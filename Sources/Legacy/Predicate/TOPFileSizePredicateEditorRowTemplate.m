//
//  FileSizePredicateEditorRowTemplate.m
//  VisualDiffer
//
//  Created by davide ficano on 07/03/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import "TOPFileSizePredicateEditorRowTemplate.h"

static const NSInteger VD_SIZE_KB = (1024L);
static const NSInteger VD_SIZE_MB = (VD_SIZE_KB * 1024);
static const NSInteger VD_SIZE_GB = (VD_SIZE_MB * 1024);

@implementation TOPFileSizePredicateEditorRowTemplate

- (NSArray *)templateViews {
    if (self.sizePopupButton == nil) {
        self.sizePopupButton = [[NSPopUpButton alloc] init];
        [self.sizePopupButton addItemsWithTitles:@[@"Bytes", @"KB", @"MB", @"GB"]];
    }
    NSArray* myviews = super.templateViews;
    return @[myviews[0],
            myviews[1],
            myviews[2],
            self.sizePopupButton];
}

- (void)setPredicate:(NSPredicate *)predicate {
    NSComparisonPredicate* comparisonPredicate = (NSComparisonPredicate *)predicate;
    long long num = [comparisonPredicate.rightExpression.constantValue longLongValue];
    long long size;

    // show in the view the original value entered by user
    if ((num % VD_SIZE_GB) == 0) {
        size = num / VD_SIZE_GB;
        [self.sizePopupButton selectItemAtIndex:3];
    } else if ((num % VD_SIZE_MB) == 0) {
        size = num / VD_SIZE_MB;
        [self.sizePopupButton selectItemAtIndex:2];
    } else if ((num % VD_SIZE_KB) == 0) {
        size = num / VD_SIZE_KB;
        [self.sizePopupButton selectItemAtIndex:1];
    } else {
        size = num;
        [self.sizePopupButton selectItemAtIndex:0];
    }

    NSExpression* bytesExpression = [NSExpression expressionForConstantValue:@(size)];
    predicate = [NSComparisonPredicate predicateWithLeftExpression:comparisonPredicate.leftExpression
                                                   rightExpression:bytesExpression
                                                          modifier:comparisonPredicate.comparisonPredicateModifier
                                                              type:comparisonPredicate.predicateOperatorType
                                                           options:comparisonPredicate.options];
    [super setPredicate:predicate];
}

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates {
    long unitySize = 1;

    NSPopUpButton* button = (NSPopUpButton*)self.templateViews[3];
    switch (button.indexOfSelectedItem) {
        case 0:
            unitySize = 1;
            break;
        case 1:
            unitySize = VD_SIZE_KB;
            break;
        case 2:
            unitySize = VD_SIZE_MB;
            break;
        case 3:
            unitySize = VD_SIZE_GB;
            break;
    }

    NSComparisonPredicate *predicate = (NSComparisonPredicate *)[super predicateWithSubpredicates:subpredicates];
    long long num = [predicate.rightExpression.constantValue longLongValue];

    // create the NSPredicate multiplying the value by unity size
    NSExpression* bytesExpression = [NSExpression expressionForConstantValue:@(num * unitySize)];
    return [NSComparisonPredicate predicateWithLeftExpression:predicate.leftExpression
                                              rightExpression:bytesExpression
                                                     modifier:predicate.comparisonPredicateModifier
                                                         type:predicate.predicateOperatorType
                                                      options:predicate.options];
}

@end
