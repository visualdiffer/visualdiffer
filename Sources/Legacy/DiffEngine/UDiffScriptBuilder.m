//
//  ScriptBuilder.m
//  VisualDiffer
//
//  Created by davide ficano on 23/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import "UDiffScriptBuilder.h"

@implementation UDiffChange

+ (instancetype)changeWithRange:(int)pline0 line1:(int)pline1 deleted:(int)pdeleted inserted:(int)pinserted old:(UDiffChange*)pold {
    return [[self alloc] initWithRange:pline0 line1:pline1 deleted:pdeleted inserted:pinserted old:pold];
}

/** Cons an additional entry onto the front of an edit script OLD.
 LINE0 and LINE1 are the first affected lines in the two files (origin 0).
 DELETED is the number of lines deleted here from file 0.
 INSERTED is the number of lines inserted here in file 1.
 
 If DELETED is 0 then LINE0 is the number of the line before
 which the insertion was done; vice versa for INSERTED and LINE1.  */
- (instancetype)initWithRange:(int)pline0 line1:(int)pline1 deleted:(int)pdeleted inserted:(int)pinserted old:(UDiffChange*)pold {
    self = [super init];
    
    if (self) {
        _line0 = pline0;
        _line1 = pline1;
        _inserted = pinserted;
        _deleted = pdeleted;
        _link = pold;
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%d, %d inserted %d, deleted %d", self.line0 + 1, self.line1 + 1, self.inserted, self.deleted];
}

@end

@implementation UDiffScriptBuilder

- (UDiffChange*)build_script:(BOOL*)changed0 len0:(NSUInteger)len0 changed1:(BOOL*)changed1 len1:(NSUInteger)len1 {
    return nil;
}

@end

/** Scan the tables of which lines are inserted and deleted,
 producing an edit script in reverse order.  */

@implementation UDiffReverseScript
- (UDiffChange*)build_script:(BOOL*)changed0 len0:(NSUInteger)len0 changed1:(BOOL*)changed1 len1:(NSUInteger)len1 {
    UDiffChange* script = nil;
    int i0 = 0, i1 = 0;
    while (i0 < (NSInteger)len0 || i1 < (NSInteger)len1) {
        if (changed0[1+i0] || changed1[1+i1]) {
            int line0 = i0, line1 = i1;
            
            /* Find # lines changed here in each file.  */
            while (changed0[1+i0]) ++i0;
            while (changed1[1+i1]) ++i1;
            
            /* Record this change.  */
            script = [UDiffChange changeWithRange:line0 line1:line1 deleted:i0 - line0 inserted:i1 - line1 old:script];
        }
        
        /* We have reached lines in the two files that match each other.  */
        i0++; i1++;
    }
    
    return script;
}
@end;

@implementation UDiffForwardScript
- (UDiffChange*)build_script:(BOOL*)changed0 len0:(NSUInteger)len0 changed1:(BOOL*)changed1 len1:(NSUInteger)len1 {
    UDiffChange* script = nil;
    int i0 = (int)len0, i1 = (int)len1;
    
    while (i0 >= 0 || i1 >= 0)
    {
        if (changed0[i0] || changed1[i1])
        {
            int line0 = i0, line1 = i1;
            
            /* Find # lines changed here in each file.  */
            while (changed0[i0]) --i0;
            while (changed1[i1]) --i1;
            
            /* Record this change.  */
            script = [UDiffChange changeWithRange:i0 line1:i1 deleted:line0 - i0 inserted:line1 - i1 old:script];
        }
        
        /* We have reached lines in the two files that match each other.  */
        i0--; i1--;
    }
    
    return script;
}
@end;
