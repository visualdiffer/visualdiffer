//
//  ScriptBuilder.h
//  VisualDiffer
//
//  Created by davide ficano on 23/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** The result of comparison is an "edit script": a chain of change objects.
 Each change represents one place where some lines are deleted
 and some are inserted.
 
 LINE0 and LINE1 are the first affected lines in the two files (origin 0).
 DELETED is the number of lines deleted here from file 0.
 INSERTED is the number of lines inserted here in file 1.
 
 If DELETED is 0 then LINE0 is the number of the line before
 which the insertion was done; vice versa for INSERTED and LINE1.  */

@interface UDiffChange : NSObject
/** Previous or next edit command. */
@property (strong, nullable) UDiffChange* link;
/** Line number of 1st deleted line.  */
@property (assign) int line0;
/** Line number of 1st inserted line.  */
@property (assign) int line1;
/** # lines of file 1 changed here.  */
@property (assign) int inserted;
/** # lines of file 0 changed here.  */
@property (assign) int deleted;

+ (instancetype)changeWithRange:(int)line0 line1:(int)line1 deleted:(int)deleted inserted:(int)inserted old:(nullable UDiffChange*)old;
- (instancetype)initWithRange:(int)line0 line1:(int)line1 deleted:(int)deleted inserted:(int)inserted old:(nullable UDiffChange*)old;
@end


@interface UDiffScriptBuilder : NSObject
/** Scan the tables of which lines are inserted and deleted,
 producing an edit script. 
 @param changed0 true for lines in first file which do not match 2nd
 @param len0 number of lines in first file
 @param changed1 true for lines in 2nd file which do not match 1st
 @param len1 number of lines in 2nd file
 @return a linked list of changes - or null
 */
- (nullable UDiffChange*)build_script:(BOOL*)changed0 len0:(NSUInteger)len0 changed1:(BOOL*)changed1 len1:(NSUInteger)len1;
@end

@interface UDiffReverseScript : UDiffScriptBuilder
@end;

@interface UDiffForwardScript : UDiffScriptBuilder
@end;

NS_ASSUME_NONNULL_END
