//
//  VDTimestampPredicateEditorRowTemplate.m
//  VisualDiffer
//
//  Created by davide ficano on 07/03/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import "TOPTimestampPredicateEditorRowTemplate.h"

const NSInteger VDTimestampElementFlag = NSDatePickerElementFlagYearMonthDay | NSDatePickerElementFlagHourMinuteSecond;

static NSDateFormatter* TOPTimestampPredicateEditorDateFormatter;

@interface TOPTimestampPredicateEditorRowTemplate() {
    BOOL isDefaultValuesSet;
}
@end;

@implementation TOPTimestampPredicateEditorRowTemplate

- (instancetype)init
{
    self = [super init];
    if (self) {
        static dispatch_once_t pred;

        dispatch_once(&pred, ^{
            TOPTimestampPredicateEditorDateFormatter = [[NSDateFormatter alloc] init];
            TOPTimestampPredicateEditorDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss z";
            TOPTimestampPredicateEditorDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            TOPTimestampPredicateEditorDateFormatter.timeZone = [NSTimeZone defaultTimeZone];
            TOPTimestampPredicateEditorDateFormatter.formatterBehavior = NSDateFormatterBehaviorDefault;
        });
    }
    return self;
}

- (NSArray *)templateViews {
    if (!isDefaultValuesSet) {
        NSDatePicker* picker = (NSDatePicker*)super.templateViews[2];
        picker.datePickerElements = VDTimestampElementFlag;
        picker.dateValue = [NSDate date];
        isDefaultValuesSet = YES;
    }

    return super.templateViews;
}

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates {
    NSComparisonPredicate *predicate = (NSComparisonPredicate *)[super predicateWithSubpredicates:subpredicates];
    // set to zero from the decimal part present in the NSTimeInterval
    // so exact compares (eg a == b) can be done correctly
    NSDatePicker* picker = (NSDatePicker*)super.templateViews[2];
    NSDate* d1 = picker.dateValue;
    NSDate* d2 = [TOPTimestampPredicateEditorDateFormatter dateFromString:d1.description];

    NSExpression* dateExpression = [NSExpression expressionForConstantValue:d2];
    return [NSComparisonPredicate predicateWithLeftExpression:predicate.leftExpression
                                              rightExpression:dateExpression
                                                     modifier:predicate.comparisonPredicateModifier
                                                         type:predicate.predicateOperatorType
                                                      options:predicate.options];
}

@end
