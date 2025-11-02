//
//  FolderReader+Detached.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FolderReader {
    /**
     * Identical to .start() but runs in separated detached thread
     */
    func startDetached(
        leftRoot: CompareItem?,
        rightRoot: CompareItem?,
        leftPath: URL,
        rightPath: URL
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.start(
                withLeftRoot: leftRoot,
                rightRoot: rightRoot,
                leftPath: leftPath,
                rightPath: rightPath
            )
        }
    }
}
