//
//  TitlePredicateEditorRowTemplate.m
//  VisualDiffer
//
//  Created by davide ficano on 25/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

#import "TitlePredicateEditorRowTemplate.h"

@interface TitlePredicateEditorRowTemplate()
@property (nonatomic, copy) NSDictionary<NSString *, NSString *>* keyPathDisplayNames;
@property (nonatomic, copy) NSDictionary<NSNumber *, NSString *>* operatorDisplayNames;
@end

@implementation TitlePredicateEditorRowTemplate

- (instancetype)initWithKeyPathDisplayNames:(NSDictionary<NSString *, NSString *>*)displayNames
                                leftKeyPath:(NSString *)leftKeyPath
               rightExpressionAttributeType:(NSAttributeType)attributeType
                            caseInsensitive:(BOOL)caseInsensitive
                                  operators:(NSArray<NSDictionary<NSNumber *, NSString *>*>*)operators {
    NSExpression *leftExpr = [NSExpression expressionForKeyPath:leftKeyPath];
    NSMutableArray* ops = [NSMutableArray array];

    // used to maintain the order inside popup menu
    for (NSDictionary<NSNumber *, NSString *>* dict in operators) {
        [ops addObjectsFromArray:dict.allKeys];
    }

    self = [super initWithLeftExpressions:@[leftExpr]
             rightExpressionAttributeType:attributeType
                                 modifier:NSDirectPredicateModifier
                                operators:ops
                                  options:caseInsensitive ? NSCaseInsensitivePredicateOption : 0];

    if (self) {
        NSMutableDictionary* map = [NSMutableDictionary dictionary];

        for (NSDictionary<NSNumber *, NSString *>* dict in operators) {
            [dict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                map[key] = obj;
            }];
        }
        self.operatorDisplayNames = map;
        self.keyPathDisplayNames = displayNames;
    }
    return self;
};

- (NSArray<NSView *> *)templateViews {
    NSArray<NSView*> *views = [super templateViews];

    for (NSView *view in views) {
        if ([view isKindOfClass:[NSPopUpButton class]]) {
            NSPopUpButton *popup = (NSPopUpButton *)view;

            for (NSMenuItem *item in popup.itemArray) {
                id represented = item.representedObject;

                // Customize key path titles
                if ([represented isKindOfClass:[NSExpression class]]) {
                    NSExpression *expr = (NSExpression *)represented;

                    if (expr.expressionType == NSKeyPathExpressionType) {
                        NSString *keyPath = expr.keyPath;
                        NSString *display = self.keyPathDisplayNames[keyPath];
                        if (display) {
                            item.title = display;
                        }
                    }
                }

                // Customize operator titles
                if ([represented isKindOfClass:[NSNumber class]]) {
                    NSNumber *opType = (NSNumber *)represented;
                    NSString *customOp = self.operatorDisplayNames[opType];
                    if (customOp) {
                        item.title = customOp;
                    }
                }
            }
        }
    }

    return views;
}
@end
