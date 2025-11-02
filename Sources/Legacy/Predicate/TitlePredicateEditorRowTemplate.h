//
//  TitlePredicateEditorRowTemplate.h
//  VisualDiffer
//
//  Created by davide ficano on 25/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TitlePredicateEditorRowTemplate : NSPredicateEditorRowTemplate

- (instancetype)initWithKeyPathDisplayNames:(NSDictionary<NSString *, NSString *>*)displayNames
                                leftKeyPath:(NSString *)leftKeyPath
               rightExpressionAttributeType:(NSAttributeType)attributeType
                            caseInsensitive:(BOOL)caseInsensitive
                                  operators:(NSArray<NSDictionary<NSNumber *, NSString *>*>*)operators;

@end

NS_ASSUME_NONNULL_END
