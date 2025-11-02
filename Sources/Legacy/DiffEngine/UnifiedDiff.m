//
//  UnifiedDiff.m
//  VisualDiffer
//
//  Created by davide ficano on 23/05/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import "UnifiedDiff.h"
#import "UDiffScriptBuilder.h"

/** Snakes bigger than this are considered "big". */
static const NSInteger SNAKE_LIMIT = 20;

static UDiffScriptBuilder* forwardScript;
static UDiffScriptBuilder* reverseScript;

@interface UDiffFileData()
- (char*)discardable:(int*)counts NS_RETURNS_INNER_POINTER;
- (void)filterDiscards:(char*)discards;
- (void)discard:(char*)discards;
@end

@interface UnifiedDiff()
- (UDiffChange*)diff:(UDiffScriptBuilder*)bld;
@end

@implementation UDiffFileData

+ (instancetype)fileData:(NSArray*)data h:(NSMutableDictionary*)h equivMax:(int*)ppequiv_max noDiscards:(BOOL*)ppno_discards {
    return [[self alloc] initWithData:data h:h equivMax:ppequiv_max noDiscards:ppno_discards];
}

- (instancetype)initWithData:(NSArray*)data h:(NSMutableDictionary*)h equivMax:(int*)ppequiv_max noDiscards:(BOOL*)ppno_discards {
    self = [super init];
    
    if (self) {
        pequiv_max = ppequiv_max;
        pno_discards = ppno_discards;
        _buffered_lines = data.count;

        equivs = calloc(_buffered_lines, sizeof(int));
        _undiscarded = calloc(_buffered_lines, sizeof(int));
        _realindexes = calloc(_buffered_lines, sizeof(int));
        _changed_flag = NULL;

        int i = 0;
        for (NSString* o in data) {
            NSNumber* ir = h[o];
            if (ir == nil) {
                h[o] = @(equivs[i] = *pequiv_max);
                (*pequiv_max)++;
            } else {
                equivs[i] = [ir intValue];
            }
            ++i;
        }
    }
    
    return self;
}

- (void)dealloc {
    free(equivs);
    free(_undiscarded);
    free(_realindexes);
    free(_changed_flag);
    
}

/** Allocate changed array for the results of comparison.  */
- (void)clear {
    /* Allocate a flag for each line of each file, saying whether that line
     is an insertion or deletion.
     Allocate an extra element, always zero, at each end of each vector.
     */
    _changed_flag = calloc(_buffered_lines + 2, sizeof(BOOL));
}

/** Return equiv_count[I] as the number of lines in this file
 that fall in equivalence class I.
 @return the array of equivalence class counts.
 */
- (int*)equivCount {
    int equiv_max = *pequiv_max;
    int* equiv_count = calloc(equiv_max, sizeof(int));
    for (int i = 0; i < (NSInteger)_buffered_lines; ++i)
        ++equiv_count[equivs[i]];
    return equiv_count;
}

/** Discard lines that have no matches in another file.
 
 A line which is discarded will not be considered by the actual
 comparison algorithm; it will be as if that line were not in the file.
 The file's `realindexes' table maps virtual line numbers
 (which don't count the discarded lines) into real line numbers;
 this is how the actual comparison algorithm produces results
 that are comprehensible when the discarded lines are counted.
 <p>
 When we discard a line, we also mark it as a deletion or insertion
 so that it will be printed in the output.  
 @param f the other file   
 */
- (void)discard_confusing_lines:(UDiffFileData*)f {
    [self clear];
    /* Set up table of which lines are going to be discarded. */
    int* tempEquivCount = [f equivCount];
    char* discarded = [self discardable:tempEquivCount];
    
    /* Don't really discard the provisional lines except when they occur
     in a run of discardables, with nonprovisionals at the beginning
     and end.  */
    [self filterDiscards:discarded];
    
    /* Actually discard the lines. */
    [self discard:discarded];
    
    free(discarded);
    free(tempEquivCount);
}

/** Mark to be discarded each line that matches no line of another file.
 If a line matches many lines, mark it as provisionally discardable.  
 @see equivCount()
 @param counts The count of each equivalence number for the other file.
 @return 0=nondiscardable, 1=discardable or 2=provisionally discardable
 for each line
 */

- (char*)discardable:(int*)counts {
    NSInteger end = (NSInteger)_buffered_lines;
    char* discards = calloc(end, sizeof(char));
    int many = 5;
    NSUInteger tem = end / 64;
    
    /* Multiply MANY by approximate square root of number of lines.
     That is the threshold for provisionally discardable lines.  */
    while ((tem = tem >> 2) > 0)
        many *= 2;
    
    for (int i = 0; i < end; i++)
    {
        int nmatch;
        if (equivs[i] == 0)
            continue;
        nmatch = counts[equivs[i]];
        if (nmatch == 0)
            discards[i] = 1;
        else if (nmatch > many)
            discards[i] = 2;
    }
    return discards;
}

/** Don't really discard the provisional lines except when they occur
 in a run of discardables, with nonprovisionals at the beginning
 and end.  */

- (void)filterDiscards:(char*)discards {
    NSInteger end = (NSInteger)_buffered_lines;
    
    for (int i = 0; i < end; i++)
    {
        /* Cancel provisional discards not in middle of run of discards.  */
        if (discards[i] == 2)
            discards[i] = 0;
        else if (discards[i] != 0)
        {
            /* We have found a nonprovisional discard.  */
            int j;
            int length;
            int provisional = 0;
            
            /* Find end of this run of discardable lines.
             Count how many are provisionally discardable.  */
            for (j = i; j < end; j++)
            {
                if (discards[j] == 0)
                    break;
                if (discards[j] == 2)
                    ++provisional;
            }
            
            /* Cancel provisional discards at end, and shrink the run.  */
            while (j > i && discards[j - 1] == 2) {
                discards[--j] = 0; --provisional;
            }
            
            /* Now we have the length of a run of discardable lines
             whose first and last are not provisional.  */
            length = j - i;
            
            /* If 1/4 of the lines in the run are provisional,
             cancel discarding of all provisional lines in the run.  */
            if (provisional * 4 > length)
            {
                while (j > i)
                    if (discards[--j] == 2)
                        discards[j] = 0;
            }
            else
            {
                int consec;
                int minimum = 1;
                int tem = length / 4;
                
                /* MINIMUM is approximate square root of LENGTH/4.
                 A subrun of two or more provisionals can stand
                 when LENGTH is at least 16.
                 A subrun of 4 or more can stand when LENGTH >= 64.  */
                while ((tem = tem >> 2) > 0)
                    minimum *= 2;
                minimum++;
                
                /* Cancel any subrun of MINIMUM or more provisionals
                 within the larger run.  */
                for (j = 0, consec = 0; j < length; j++)
                    if (discards[i + j] != 2)
                        consec = 0;
                    else if (minimum == ++consec)
                    /* Back up to start of subrun, to cancel it all.  */
                        j -= consec;
                    else if (minimum < consec)
                        discards[i + j] = 0;
                
                /* Scan from beginning of run
                 until we find 3 or more nonprovisionals in a row
                 or until the first nonprovisional at least 8 lines in.
                 Until that point, cancel any provisionals.  */
                for (j = 0, consec = 0; j < length; j++)
                {
                    if (j >= 8 && discards[i + j] == 1)
                        break;
                    if (discards[i + j] == 2) {
                        consec = 0; discards[i + j] = 0;
                    }
                    else if (discards[i + j] == 0)
                        consec = 0;
                    else
                        consec++;
                    if (consec == 3)
                        break;
                }
                
                /* I advances to the last line of the run.  */
                i += length - 1;
                
                /* Same thing, from end.  */
                for (j = 0, consec = 0; j < length; j++)
                {
                    if (j >= 8 && discards[i - j] == 1)
                        break;
                    if (discards[i - j] == 2) {
                        consec = 0; discards[i - j] = 0;
                    }
                    else if (discards[i - j] == 0)
                        consec = 0;
                    else
                        consec++;
                    if (consec == 3)
                        break;
                }
            }
        }
    }
}

/** Actually discard the lines.
 @param discards flags lines to be discarded
 */
- (void)discard:(char*)discards {
    NSInteger end = (NSInteger)_buffered_lines;
    int j = 0;
    for (int i = 0; i < end; ++i)
        if (*pno_discards || discards[i] == 0)
        {
            _undiscarded[j] = equivs[i];
            _realindexes[j++] = i;
        }
        else
            _changed_flag[1+i] = true;
    _nondiscarded_lines = j;
}

/** Adjust inserts/deletes of blank lines to join changes
 as much as possible.
 
 We do something when a run of changed lines include a blank
 line at one end and have an excluded blank line at the other.
 We are free to choose which blank line is included.
 `compareseq' always chooses the one at the beginning,
 but usually it is cleaner to consider the following blank line
 to be the "change".  The only exception is if the preceding blank line
 would join this change to other changes.  
 @param f the file being compared against
 */

- (void)shift_boundaries:(UDiffFileData*)f {
    BOOL* changed = _changed_flag;
    BOOL* other_changed = f.changed_flag;
    int i = 0;
    int j = 0;
    NSInteger i_end = (NSInteger)_buffered_lines;
    int preceding = -1;
    int other_preceding = -1;
    
    for (;;)
    {
        int start, end, other_start;
        
        /* Scan forwards to find beginning of another run of changes.
         Also keep track of the corresponding point in the other file.  */
        
        while (i < i_end && !changed[1+i])
        {
            while (other_changed[1+j++])
            /* Non-corresponding lines in the other file
             will count as the preceding batch of changes.  */
                other_preceding = j;
            i++;
        }
        
        if (i == i_end)
            break;
        
        start = i;
        other_start = j;
        
        for (;;)
        {
            /* Now find the end of this run of changes.  */
            
            while (i < i_end && changed[1+i]) i++;
            end = i;
            
            /* If the first changed line matches the following unchanged one,
             and this run does not follow right after a previous run,
             and there are no lines deleted from the other file here,
             then classify the first changed line as unchanged
             and the following line as changed in its place.  */
            
            /* You might ask, how could this run follow right after another?
             Only because the previous run was shifted here.  */
            
            if (end != i_end
                && equivs[start] == equivs[end]
                && !other_changed[1+j]
                && end != i_end
                && !((preceding >= 0 && start == preceding)
                     || (other_preceding >= 0
                         && other_start == other_preceding)))
            {
                changed[1+end++] = true;
                changed[1+start++] = false;
                ++i;
                /* Since one line-that-matches is now before this run
                 instead of after, we must advance in the other file
                 to keep in synch.  */
                ++j;
            }
            else
                break;
        }
        
        preceding = i;
        other_preceding = j;
    }
}
@end

#pragma mark -
#pragma mark UnifiedDiff methods

@interface UnifiedDiff()
@property (strong) UDiffFileData* filevec0;
@property (strong) UDiffFileData* filevec1;
@end

@implementation UnifiedDiff

/** Prepare to find differences between two arrays.  Each element of
 the arrays is translated to an "equivalence number" based on
 the result of <code>equals</code>.  The original Object arrays
 are no longer needed for computing the differences.  They will
 be needed again later to print the results of the comparison as
 an edit script, if desired.
 */
- (instancetype)initWithOriginalLines:(NSArray*)a revisedLines:(NSArray*)b {
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        forwardScript = [[UDiffForwardScript alloc] init];
        reverseScript = [[UDiffReverseScript alloc] init];
    });
    self = [super init];

    if (self) {
        equiv_max = 1;
        heuristic = NO;
        no_discards = NO;
        inhibit = NO;
        NSMutableDictionary* h = [NSMutableDictionary dictionaryWithCapacity:a.count + b.count];
        _filevec0 = [UDiffFileData fileData:a h:h equivMax:&equiv_max noDiscards:&no_discards];
        _filevec1 = [UDiffFileData fileData:b h:h equivMax:&equiv_max noDiscards:&no_discards];
    }

    return self;
}

/** Find the midpoint of the shortest edit script for a specified
 portion of the two files.
 
 We scan from the beginnings of the files, and simultaneously from the ends,
 doing a breadth-first search through the space of edit-sequence.
 When the two searches meet, we have found the midpoint of the shortest
 edit sequence.
 
 The value returned is the number of the diagonal on which the midpoint lies.
 The diagonal number equals the number of inserted lines minus the number
 of deleted lines (counting only lines before the midpoint).
 The edit cost is stored into COST; this is the total number of
 lines inserted or deleted (counting only lines before the midpoint).
 
 This function assumes that the first lines of the specified portions
 of the two files do not match, and likewise that the last lines do not
 match.  The caller must trim matching lines from the beginning and end
 of the portions it is going to specify.
 
 Note that if we return the "wrong" diagonal value, or if
 the value of bdiag at that diagonal is "wrong",
 the worst this can do is cause suboptimal diff output.
 It cannot cause incorrect diff output.  */

- (int)diag:(int)xoff xlim:(int)xlim yoff:(int)yoff ylim:(int)ylim {
        int* fd = fdiag;	// Give the compiler a chance.
        int* bd = bdiag;	// Additional help for the compiler.
        int* xv = xvec;		// Still more help for the compiler.
        int* yv = yvec;		// And more and more . . .
        int dmin = xoff - ylim;	// Minimum valid diagonal.
        int dmax = xlim - yoff;	// Maximum valid diagonal.
        int fmid = xoff - yoff;	// Center diagonal of top-down search.
        int bmid = xlim - ylim;	// Center diagonal of bottom-up search.
    int fmin = fmid, fmax = fmid;	// Limits of top-down search.
    int bmin = bmid, bmax = bmid;	// Limits of bottom-up search.
    /* True if southeast corner is on an odd
     diagonal with respect to the northwest. */
        BOOL odd = (fmid - bmid & 1) != 0;	
    
    fd[fdiagoff + fmid] = xoff;
    bd[bdiagoff + bmid] = xlim;
    
    for (int c = 1;; ++c)
    {
        int d;			/* Active diagonal. */
        BOOL big_snake = NO;
        
        /* Extend the top-down search by an edit step in each diagonal. */
        if (fmin > dmin)
            fd[fdiagoff + --fmin - 1] = -1;
        else
            ++fmin;
        if (fmax < dmax)
            fd[fdiagoff + ++fmax + 1] = -1;
        else
            --fmax;
        for (d = fmax; d >= fmin; d -= 2)
        {
            int x, y, oldx, tlo = fd[fdiagoff + d - 1], thi = fd[fdiagoff + d + 1];
            
            if (tlo >= thi)
                x = tlo + 1;
            else
                x = thi;
            oldx = x;
            y = x - d;
            while (x < xlim && y < ylim && xv[x] == yv[y]) {
                ++x; ++y;
            }
            if (x - oldx > SNAKE_LIMIT)
                big_snake = true;
            fd[fdiagoff + d] = x;
            if (odd && bmin <= d && d <= bmax && bd[bdiagoff + d] <= fd[fdiagoff + d])
            {
                cost = 2 * c - 1;
                return d;
            }
        }
        
        /* Similar extend the bottom-up search. */
        if (bmin > dmin)
            bd[bdiagoff + --bmin - 1] = INT_MAX;
        else
            ++bmin;
        if (bmax < dmax)
            bd[bdiagoff + ++bmax + 1] = INT_MAX;
        else
            --bmax;
        for (d = bmax; d >= bmin; d -= 2)
        {
            int x, y, oldx, tlo = bd[bdiagoff + d - 1], thi = bd[bdiagoff + d + 1];
            
            if (tlo < thi)
                x = tlo;
            else
                x = thi - 1;
            oldx = x;
            y = x - d;
            while (x > xoff && y > yoff && xv[x - 1] == yv[y - 1]) {
                --x; --y;
            }
            if (oldx - x > SNAKE_LIMIT)
                big_snake = true;
            bd[bdiagoff + d] = x;
            if (!odd && fmin <= d && d <= fmax && bd[bdiagoff + d] <= fd[fdiagoff + d])
            {
                cost = 2 * c;
                return d;
            }
        }
        
        /* Heuristic: check occasionally for a diagonal that has made
         lots of progress compared with the edit distance.
         If we have any such, find the one that has made the most
         progress and return it as if it had succeeded.
         
         With this heuristic, for files with a constant small density
         of changes, the algorithm is linear in the file size.  */
        
        if (c > 200 && big_snake && heuristic)
        {
            int best = 0;
            int bestpos = -1;
            
            for (d = fmax; d >= fmin; d -= 2)
            {
                int dd = d - fmid;
                int x = fd[fdiagoff + d];
                int y = x - d;
                int v = (x - xoff) * 2 - dd;
                if (v > 12 * (c + (dd < 0 ? -dd : dd)))
                {
                    if (v > best
                        && xoff + SNAKE_LIMIT <= x && x < xlim
                        && yoff + SNAKE_LIMIT <= y && y < ylim)
                    {
                        /* We have a good enough best diagonal;
                         now insist that it end with a significant snake.  */
                        int k;
                        
                        for (k = 1; xvec[x - k] == yvec[y - k]; k++)
                            if (k == SNAKE_LIMIT)
                            {
                                best = v;
                                bestpos = d;
                                break;
                            }
                    }
                }
            }
            if (best > 0)
            {
                cost = 2 * c - 1;
                return bestpos;
            }
            
            best = 0;
            for (d = bmax; d >= bmin; d -= 2)
            {
                int dd = d - bmid;
                int x = bd[bdiagoff + d];
                int y = x - d;
                int v = (xlim - x) * 2 + dd;
                if (v > 12 * (c + (dd < 0 ? -dd : dd)))
                {
                    if (v > best
                        && xoff < x && x <= xlim - SNAKE_LIMIT
                        && yoff < y && y <= ylim - SNAKE_LIMIT)
                    {
                        /* We have a good enough best diagonal;
                         now insist that it end with a significant snake.  */
                        int k;
                        
                        for (k = 0; xvec[x + k] == yvec[y + k]; k++)
                            if (k == SNAKE_LIMIT)
                            {
                                best = v;
                                bestpos = d;
                                break;
                            }
                    }
                }
            }
            if (best > 0)
            {
                cost = 2 * c - 1;
                return bestpos;
            }
        }
    }
}

/** Compare in detail contiguous subsequences of the two files
 which are known, as a whole, to match each other.
 
 The results are recorded in the vectors filevec[N].changed_flag, by
 storing a 1 in the element for each line that is an insertion or deletion.
 
 The subsequence of file 0 is [XOFF, XLIM) and likewise for file 1.
 
 Note that XLIM, YLIM are exclusive bounds.
 All line numbers are origin-0 and discarded lines are not counted.  */

- (void)compareseq:(int)xoff xlim:(int)xlim yoff:(int)yoff ylim:(int)ylim {
    /* Slide down the bottom initial diagonal. */
    while (xoff < xlim && yoff < ylim && xvec[xoff] == yvec[yoff]) {
        ++xoff; ++yoff;
    }
    /* Slide up the top initial diagonal. */
    while (xlim > xoff && ylim > yoff && xvec[xlim - 1] == yvec[ylim - 1]) {
        --xlim; --ylim;
    }
    
    /* Handle simple cases. */
    if (xoff == xlim)
        while (yoff < ylim)
            self.filevec1.changed_flag[1 + self.filevec1.realindexes[yoff++]] = YES;
    else if (yoff == ylim)
        while (xoff < xlim)
            self.filevec0.changed_flag[1 + self.filevec0.realindexes[xoff++]] = YES;
    else
    {
        /* Find a point of correspondence in the middle of the files.  */
        
        int d = [self diag:xoff xlim:xlim yoff:yoff ylim:ylim];
        int c = cost;
//        int f = fdiag[fdiagoff + d];
        int b = bdiag[bdiagoff + d];
        
        if (c == 1)
        {
            /* This should be impossible, because it implies that
             one of the two subsequences is empty,
             and that case was handled above without calling `diag'.
             Let's verify that this is true.  */
//            /throw new IllegalArgumentException("Empty subsequence");
        }
        else
        {
            /* Use that point to split this problem into two subproblems.  */
            [self compareseq:xoff xlim:b yoff:yoff ylim:b - d];
            /* This used to use f instead of b,
             but that is incorrect!
             It is not necessarily the case that diagonal d
             has a snake from b to f.  */
            [self compareseq:b xlim:xlim yoff:b - d ylim:ylim];
        }
    }
}

/** Discard lines from one file that have no matches in the other file.
 */

- (void)discard_confusing_lines {
    [self.filevec0 discard_confusing_lines:self.filevec1];
    [self.filevec1 discard_confusing_lines:self.filevec0];
}

/** Adjust inserts/deletes of blank lines to join changes
 as much as possible.
 */

- (void)shift_boundaries {
    if (inhibit)
        return;
    [self.filevec0 shift_boundaries:self.filevec1];
    [self.filevec1 shift_boundaries:self.filevec0];
}

/* Report the differences of two files. */
- (UDiffChange*)diff_2:(BOOL)reverse {
    return [self diff:reverse ? reverseScript : forwardScript];
}

/** Get the results of comparison as an edit script.  The script 
 is described by a list of changes.  The standard ScriptBuilder
 implementations provide for forward and reverse edit scripts.
 Alternate implementations could, for instance, list common elements 
 instead of differences.
 @param bld	an object to build the script from change flags
 @return the head of a list of changes
 */
- (UDiffChange*)diff:(UDiffScriptBuilder*)bld {
    
    /* Some lines are obviously insertions or deletions
     because they don't match anything.  Detect them now,
     and avoid even thinking about them in the main comparison algorithm.  */
    
    [self discard_confusing_lines];
    
    /* Now do the main comparison algorithm, considering just the
     undiscarded lines.  */
    
    xvec = self.filevec0.undiscarded;
    yvec = self.filevec1.undiscarded;
    
    int diags = self.filevec0.nondiscarded_lines + self.filevec1.nondiscarded_lines + 3;
    fdiag = calloc(diags, sizeof(int));
    fdiagoff = self.filevec1.nondiscarded_lines + 1;
    bdiag = calloc(diags, sizeof(int));
    bdiagoff = self.filevec1.nondiscarded_lines + 1;

    [self compareseq:0
                xlim:self.filevec0.nondiscarded_lines
                yoff:0
                ylim:self.filevec1.nondiscarded_lines];
    fdiag = nil;
    bdiag = nil;
    
    /* Modify the results slightly to make them prettier
     in cases where that can validly be done.  */
    
    [self shift_boundaries];
    
    /* Get the results of comparison in the form of a chain
     of struct change's -- an edit script.  */
    return [bld build_script:self.filevec0.changed_flag
                        len0:self.filevec0.buffered_lines
                    changed1:self.filevec1.changed_flag
                        len1:self.filevec1.buffered_lines];
}

/** Data on one input file being compared.
 */


@end
