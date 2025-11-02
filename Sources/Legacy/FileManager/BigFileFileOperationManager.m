//
//  BigFileFileOperationManager.m
//  VisualDiffer
//
//  Created by davide ficano on 10/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

#import "BigFileFileOperationManager.h"
#import "VisualDiffer-Swift.h"

typedef OSStatus (*FSOperationObjectAsync)(FSFileOperationRef fileOp, const FSRef *source, const FSRef *destDir, CFStringRef _Nullable destName, OptionBits flags, FSFileOperationStatusProcPtr callback, CFTimeInterval statusChangeInterval, FSFileOperationClientContext *clientContext);

// disabled warning on deprecated api usage (FSMoveObjectAsync)
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

void copyStatusCallback(FSFileOperationRef fileOp,
                        const FSRef *currentItem,
                        FSFileOperationStage stage,
                        OSStatus error,
                        CFDictionaryRef statusDictionary,
                        void *info);

@implementation BigFileFileOperationManager

- (instancetype)init:(FileOperationManager*)operationManager
            delegate:(id<FileOperationManagerDelegate>) delegate {
    self = [super init];

    if (self) {
        self.operationManager = operationManager;
        self.delegate = delegate;
    }

    return self;
}


- (BOOL)copy:(CompareItem*)srcRoot
destFullPath:(NSString*)destFullPath
       error:(NSError**)outError {
    [self.delegate fileManager:self.operationManager startBigFileOperationForItem:srcRoot];

    NSError* error;

    [self.class copyObject:srcRoot.path
                  destPath:destFullPath
               fileManager:self.operationManager
            asyncOperation:FSCopyObjectAsync
                     error:&error];
    if ([self.delegate isBigFileOperationCancelled:self.operationManager]) {
        // error isn't stored if operation is cancelled
        [self.delegate fileManager:self.operationManager updateForItem:srcRoot];
        return NO;
    }

    if (outError) {
        *outError = error;
    }
    return error == nil;
}

- (BOOL)move:(CompareItem*)srcRoot
destFullPath:(NSString*)destFullPath
       error:(NSError**)outError {
    [self.delegate fileManager:self.operationManager startBigFileOperationForItem:srcRoot];

    NSError* error;

    [self.class copyObject:srcRoot.path
                  destPath:destFullPath
               fileManager:self.operationManager
            asyncOperation:FSMoveObjectAsync
                     error:&error];

    if ([self.delegate isBigFileOperationCancelled:self.operationManager]) {
        // error isn't stored if operation is cancelled
        [self.delegate fileManager:self.operationManager updateForItem:srcRoot];
        return NO;
    }

    if (outError) {
        *outError = error;
    }
    return error == nil;
}

+ (BOOL)copyObject:(NSString*)srcPath
          destPath:(NSString*)destPath
     fileManager:(FileOperationManager*)fileManager
    asyncOperation:(FSOperationObjectAsync)operation
             error:(NSError**)error {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    FSFileOperationRef fileOp = FSFileOperationCreate(kCFAllocatorDefault);
    OSStatus status = FSFileOperationScheduleWithRunLoop(fileOp, runLoop, kCFRunLoopDefaultMode);

    if (status == noErr) {
        FSRef source;
        FSRef destination;

        FSPathMakeRef( (const UInt8 *)[srcPath fileSystemRepresentation], &source, NULL);

        Boolean isDir = true;
        FSPathMakeRef( (const UInt8 *)[[destPath stringByDeletingLastPathComponent] fileSystemRepresentation], &destination, &isDir);

        FSFileOperationClientContext clientContext = {};
        clientContext.info = (__bridge void *)(fileManager);

        status = operation(fileOp,
                           &source,
                           &destination, // Full path to destination dir
                           NULL, // Use the same filename as source
                           kFSFileOperationDefaultOptions,
                           copyStatusCallback,
                           1.0,
                           &clientContext);
        if (status == noErr) {
            while (![fileManager.delegate isBigFileOperationCompleted:fileManager] && CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.0, true)) {
                ; //nop
            }

            FSFileOperationCopyStatus(fileOp, NULL, NULL, &status, NULL, NULL);
        }
    }

    CFRelease(fileOp);
    BOOL retVal = NO;
    if (status) {
        retVal = [self setError:error withStatus:status];
    }
    return retVal;
}

+ (BOOL)setError:(NSError **)error withStatus:(OSStatus)err {
    if (error) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
    }
    return error != nil;
}

@end

#pragma mark -
#pragma mark Static callbacks

void copyStatusCallback(FSFileOperationRef fileOp,
                        const FSRef *currentItem,
                        FSFileOperationStage stage,
                        OSStatus error,
                        CFDictionaryRef statusDictionary,
                        void *info) {
    FileOperationManager* fileManager = (__bridge FileOperationManager*)info;
    id<FileOperationManagerDelegate> delegate = fileManager.delegate;

    [delegate waitPauseFor:fileManager];

    if (stage == kFSOperationStageComplete) {
        [delegate fileManager:fileManager setCompleted:YES];
    } else {
        if ([delegate isBigFileOperationCancelled:fileManager]) {
            FSFileOperationCancel(fileOp);
            return;
        }
    }

    if (statusDictionary && stage == kFSOperationStageRunning) {
        CFNumberRef bytesCompleted = (CFNumberRef)CFDictionaryGetValue(statusDictionary, kFSOperationBytesCompleteKey);
        CGFloat floatBytesCompleted = 0.0;
        if (bytesCompleted) {
            CFNumberGetValue(bytesCompleted, kCFNumberMaxType, &floatBytesCompleted);
        }

        CFNumberRef throughput = (CFNumberRef)CFDictionaryGetValue(statusDictionary, kFSOperationThroughputKey);
        CGFloat floatThroughput = 0.0;
        if (throughput) {
            CFNumberGetValue(throughput, kCFNumberMaxType, &floatThroughput);
        }

        CFNumberRef totalBytes = (CFNumberRef)CFDictionaryGetValue(statusDictionary, kFSOperationTotalBytesKey);
        CGFloat floatTotalBytes = 0.0;
        if (totalBytes) {
            CFNumberGetValue(totalBytes, kCFNumberMaxType, &floatTotalBytes);
        }

        [delegate fileManager:fileManager
           updateBytesCompleted:floatBytesCompleted
                     totalBytes:floatTotalBytes
                     throughput:floatThroughput];
    }
}
