//
//  ItemComparator.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

public protocol ItemComparatorDelegate: AnyObject {
    func isRunning(_ comparator: ItemComparator) -> Bool
}

@objc
public class ItemComparator: NSObject {
    let options: ComparatorOptions
    weak var delegate: ItemComparatorDelegate?
    let timestampToleranceSeconds: Int
    let bufferSize: Int

    let isLeftCaseSensitive: Bool
    let isRightCaseSensitive: Bool

    let fileNameAlignments: [AlignRule]?

    init(
        options: ComparatorOptions,
        delegate: ItemComparatorDelegate,
        bufferSize: Int,
        timestampToleranceSeconds: Int = 0,
        isLeftCaseSensitive: Bool = true,
        isRightCaseSensitive: Bool = true,
        fileNameAlignments: [AlignRule]? = nil
    ) {
        self.options = options
        self.delegate = delegate
        self.bufferSize = bufferSize
        self.timestampToleranceSeconds = timestampToleranceSeconds
        self.isLeftCaseSensitive = isLeftCaseSensitive
        self.isRightCaseSensitive = isRightCaseSensitive
        self.fileNameAlignments = fileNameAlignments
    }
}
