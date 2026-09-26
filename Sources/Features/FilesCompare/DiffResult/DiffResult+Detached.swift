//
//  DiffResult+Detached.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

// the detached task owns the result until the stream finishes, the caller reads it
// back only once the iteration is over
extension DiffResult: @unchecked Sendable {}

extension DiffResult {
    // identical to .diff() but runs detached, the returned stream yields the percentage
    // of processed lines and finishes when the comparison is complete
    func diffDetached(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent]
    ) -> AsyncStream<Int> {
        // a progress notification is worth nothing once a newer one exists, keeping just
        // the last one prevents a busy consumer from throttling the comparison
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            // the comparison is long and never suspends, on the cooperative pool it would
            // hold one of its threads and that pool is only as wide as the core count
            DispatchQueue.global(qos: .userInitiated).async {
                self.diff(
                    leftLines: leftLines,
                    rightLines: rightLines,
                    progress: DiffProgress { continuation.yield($0) }
                )
                continuation.finish()
            }
        }
    }
}
