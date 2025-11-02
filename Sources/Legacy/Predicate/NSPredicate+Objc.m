//
//  NSPredicate+Objc.m
//  VisualDiffer
//
//  Created by davide ficano on 02/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

#import "NSPredicate+Objc.h"

@implementation NSPredicate (Helper)

+ (instancetype)createSafeWithFormat:(NSString*)format error: (NSError**)outError {
    @try {
        return [NSPredicate predicateWithFormat: format];
    }
    @catch (NSException* exception) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFormattingError
                                        userInfo:@{NSLocalizedDescriptionKey: exception.description}];

        }
    }
    return nil;
}

@end
