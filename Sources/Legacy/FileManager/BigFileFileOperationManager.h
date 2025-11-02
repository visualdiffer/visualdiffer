//
//  BigFileFileOperationManager.h
//  VisualDiffer
//
//  Created by davide ficano on 10/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

#import <Cocoa/Cocoa.h>

NS_SWIFT_NAME(defaultBigFileSizeThreshold)
static const uint64 BIG_FILE_SIZE_THRESHOLD = (uint64)(10 * 1024 * 1024);

NS_ASSUME_NONNULL_BEGIN

@protocol FileOperationManagerDelegate;
@class FileOperationManager;
@class CompareItem;

@interface BigFileFileOperationManager: NSObject

@property (strong) FileOperationManager* operationManager;
@property (nullable, strong) id<FileOperationManagerDelegate> delegate;

- (instancetype)init:(FileOperationManager*)operationManager
            delegate:(nullable id<FileOperationManagerDelegate>) delegate;

- (BOOL)copy:(CompareItem*)srcRoot
destFullPath:(NSString*)destFullPath
       error:(out NSError ** _Nullable)outError;

- (BOOL)move:(CompareItem*)srcRoot
destFullPath:(NSString*)destFullPath
       error:(out NSError ** _Nullable)outError;

@end

NS_ASSUME_NONNULL_END
