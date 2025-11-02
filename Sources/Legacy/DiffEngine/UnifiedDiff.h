//
//  UnifiedDiff.h
//  VisualDiffer
//
//  Created by davide ficano on 23/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import <Foundation/Foundation.h>

@class UDiffScriptBuilder;
@class UDiffChange;

NS_ASSUME_NONNULL_BEGIN

@interface UDiffFileData : NSObject {
    /** Vector, indexed by line number, containing an equivalence code for
     each line.  It is this vector that is actually compared with that
     of another file to generate differences. */
    int*	    equivs;
    
    int* pequiv_max;
    BOOL*   pno_discards;
}

/** Number of elements (lines) in this file. */
@property (assign) NSUInteger buffered_lines;
/** Array, indexed by real origin-1 line number, containing true for a line that is an insertion or a deletion. */
@property (assign, nullable) BOOL* changed_flag;
/** Vector, like the previous one except that the elements for discarded lines have been squeezed out.  */
@property (assign) int* undiscarded;
/** Vector mapping virtual line numbers (not counting discarded lines) to real ones (counting those lines).  Both are origin-0.  */
@property (assign) int* realindexes;
/** Total number of nondiscarded lines. */
@property (assign) int nondiscarded_lines;

+ (instancetype)fileData:(NSArray*)data h:(NSMutableDictionary*)h equivMax:(int*)ppequiv_max noDiscards:(BOOL*)ppnoDiscards;
- (instancetype)initWithData:(NSArray*)data h:(NSMutableDictionary*)h equivMax:(int*)ppequiv_max noDiscards:(BOOL*)ppnoDiscards;

@end

@interface UnifiedDiff : NSObject {
@private
    /** 1 more than the maximum equivalence value used for this or its
     sibling file. */
    int equiv_max;
    
    /** When set to true, the comparison uses a heuristic to speed it up.
     With this heuristic, for files with a constant small density
     of changes, the algorithm is linear in the file size.  */
    BOOL heuristic;
    
    /** When set to true, the algorithm returns a guarranteed minimal
     set of changes.  This makes things slower, sometimes much slower. */
    BOOL no_discards;
    
    int* xvec, *yvec;	/* Vectors being compared. */
    int* fdiag;		/* Vector, indexed by diagonal, containing
                     the X coordinate of the point furthest
                     along the given diagonal in the forward
                     search of the edit matrix. */
    int* bdiag;		/* Vector, indexed by diagonal, containing
                     the X coordinate of the point furthest
                     along the given diagonal in the backward
                     search of the edit matrix. */
    int fdiagoff, bdiagoff;
    int cost;
    
    BOOL inhibit;
}

- (instancetype)initWithOriginalLines:(NSArray*)a revisedLines:(NSArray*)b;
- (nullable UDiffChange*)diff_2:(BOOL)reverse;

@end

NS_ASSUME_NONNULL_END
