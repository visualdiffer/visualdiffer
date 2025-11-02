//
//  NSPredicate+Objc.h
//  VisualDiffer
//
//  Created by davide ficano on 02/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSPredicate (Helper)

/**
 * Create NSPredicate handling Objective-C NSException
 */
+ (nullable instancetype)createSafeWithFormat:(NSString*)format error:(NSError *_Nullable * _Nullable)outError;

@end

NS_ASSUME_NONNULL_END
