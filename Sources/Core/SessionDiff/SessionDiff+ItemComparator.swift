//
//  SessionDiff+ItemComparator.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension SessionDiff {
    func comparator(
        withDelegate delegate: ItemComparatorDelegate,
        bufferSize: Int
    ) -> ItemComparator {
        guard let leftPath,
              let rightPath else {
            fatalError("Both leftPath and rightPath must be set")
        }
        let options = comparatorOptions
        let (isLeftCaseSensitive, isRightCaseSensitive) = options.fileNameCase(
            leftPath: URL(filePath: leftPath),
            rightPath: URL(filePath: rightPath)
        )
        return ItemComparator(
            options: options,
            delegate: delegate,
            bufferSize: bufferSize,
            timestampToleranceSeconds: Int(timestampToleranceSeconds),
            isLeftCaseSensitive: isLeftCaseSensitive,
            isRightCaseSensitive: isRightCaseSensitive,
            fileNameAlignments: fileNameAlignments
        )
    }
}
