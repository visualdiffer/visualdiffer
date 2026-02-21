//
//  ItemComparator+Align.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

import os.log

public struct AlignConfig {
    let recursive: Bool
    let followSymLinks: Bool
}

// Both files are invalid but their path string contains a valid value
@inline(__always)
func bothInvalidWithPath(_ lfs: CompareItem, _ rfs: CompareItem) -> Bool {
    !lfs.isValidFile && !rfs.isValidFile && (lfs.path != nil && rfs.path != nil)
}

public extension ComparatorOptions {
    /**
     * Return leftCaseSensitive and rightCaseSensitive determinated using the comparatorFlags value.
     * If it's necessary to access to file system then use the passed paths
     */
    func fileNameCase(leftPath: URL, rightPath: URL) -> (Bool, Bool) {
        if contains(.alignFileSystemCase) {
            (
                (try? leftPath.volumeSupportsCaseSensitive()) ?? false,
                (try? rightPath.volumeSupportsCaseSensitive()) ?? false
            )
        } else if contains(.alignMatchCase) {
            (true, true)
        } else if contains(.alignIgnoreCase) {
            (false, false)
        } else {
            (true, true)
        }
    }
}

// swiftlint:disable function_parameter_count
public extension ItemComparator {
    func alignItem(
        _ leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig
    ) {
        var lIndex = 0
        var rIndex = 0
        var leftChildrenCount = leftRoot.children.count
        var rightChildrenCount = rightRoot.children.count

        while (lIndex < leftChildrenCount) || (rIndex < rightChildrenCount) {
            var pos: ComparisonResult

            if lIndex >= leftChildrenCount {
                pos = .orderedDescending
            } else if rIndex >= rightChildrenCount {
                pos = .orderedAscending
            } else if (leftRoot.child(at: lIndex).isValidFile && rightRoot.child(at: rIndex).isValidFile)
                || bothInvalidWithPath(leftRoot.child(at: lIndex), rightRoot.child(at: rIndex)) {
                pos = align(
                    leftRoot,
                    rightRoot: rightRoot,
                    alignConfig: alignConfig,
                    leftIndex: &lIndex,
                    rightIndex: &rIndex
                )
            } else {
                if !leftRoot.child(at: lIndex).isValidFile {
                    lIndex += 1
                }
                if !rightRoot.child(at: rIndex).isValidFile {
                    rIndex += 1
                }
                continue
            }
            if pos == .orderedSame {
                if leftRoot.child(at: lIndex).isFile, rightRoot.child(at: rIndex).isFile {
                    // ignore this case
                } else {
                    if alignConfig.recursive {
                        alignItem(
                            leftRoot.child(at: lIndex),
                            rightRoot: rightRoot.child(at: rIndex),
                            alignConfig: alignConfig
                        )
                    }
                }

                leftRoot.child(at: lIndex).linkedItem = rightRoot.child(at: rIndex)
                rightRoot.child(at: rIndex).linkedItem = leftRoot.child(at: lIndex)

                lIndex += 1
                rIndex += 1
            } else if pos == .orderedAscending {
                // insert left orphan
                insert(
                    orphan: leftRoot.child(at: lIndex),
                    otherSide: rightRoot,
                    alignConfig: alignConfig,
                    leftIndex: &lIndex,
                    rightIndex: &rIndex
                )
            } else if pos == .orderedDescending {
                // insert right orphan
                insert(
                    orphan: rightRoot.child(at: rIndex),
                    otherSide: leftRoot,
                    alignConfig: alignConfig,
                    leftIndex: &lIndex,
                    rightIndex: &rIndex
                )
            } else {
                Logger.general.error("Invalid pos value \(pos.rawValue)")
            }
            leftChildrenCount = leftRoot.children.count
            rightChildrenCount = rightRoot.children.count
        }
    }

    func insert(
        orphan: CompareItem,
        otherSide: CompareItem,
        alignConfig: AlignConfig,
        leftIndex: inout Int,
        rightIndex: inout Int
    ) {
        let newItem = CompareItem(
            path: nil,
            attrs: nil,
            fileExtraOptions: [],
            parent: otherSide
        )

        orphan.linkedItem = newItem
        newItem.linkedItem = orphan
        newItem.linkedItemIsFolder(orphan.isFolder)
        otherSide.insert(child: newItem, at: leftIndex)

        if alignConfig.recursive {
            alignItem(
                orphan,
                rightRoot: otherSide.child(at: leftIndex),
                alignConfig: alignConfig
            )
        }
        leftIndex += 1
        rightIndex += 1
    }

    func align(
        _ leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig,
        leftIndex: inout Int,
        rightIndex: inout Int
    ) -> ComparisonResult {
        if let fileNameAlignments, !fileNameAlignments.isEmpty {
            return alignByRegularExpression(
                leftRoot,
                rightRoot: rightRoot,
                alignConfig: alignConfig,
                leftIndex: &leftIndex,
                rightIndex: &rightIndex
            )
        }
        return alignByFileName(
            leftRoot,
            rightRoot: rightRoot,
            alignConfig: alignConfig,
            leftIndex: &leftIndex,
            rightIndex: &rightIndex
        )
    }

    // MARK: - Filenames alignment

    func alignByFileName(
        _ leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig,
        leftIndex: inout Int,
        rightIndex: inout Int
    ) -> ComparisonResult {
        var pos: ComparisonResult = .orderedSame
        var l = leftIndex
        var r = rightIndex
        let rightChildren = rightRoot.children
        let followSymLinks = alignConfig.followSymLinks

        if isLeftCaseSensitive, isRightCaseSensitive {
            pos = leftRoot.child(at: l).compare(
                forAlign: rightRoot.child(at: r),
                followSymLinks: followSymLinks,
                insensitiveCompare: false
            )
        } else if !isLeftCaseSensitive, !isRightCaseSensitive {
            pos = leftRoot.child(at: l).compare(
                forAlign: rightRoot.child(at: r),
                followSymLinks: followSymLinks,
                insensitiveCompare: true
            )
        } else {
            let leftChild = leftRoot.child(at: l)
            let index = findInsertIndex(
                left: leftChild,
                right: rightRoot,
                startIndex: r,
                followSymLinks: followSymLinks
            )
            // left name doesn't exist on right so determine the insertion point using a match case
            if index == -1 {
                pos = leftChild.compare(
                    forAlign: rightRoot.child(at: r),
                    followSymLinks: followSymLinks,
                    insensitiveCompare: false
                )
            } else {
                while r < index {
                    insert(
                        orphan: rightRoot.child(at: r),
                        otherSide: leftRoot,
                        alignConfig: alignConfig,
                        leftIndex: &l,
                        rightIndex: &r
                    )
                }
                let leftFileName = leftRoot.child(at: l).fileName ?? ""
                let (isExactlyMatch, rightIndex) = findExactlyMatchIndex(
                    leftFileName,
                    subfolders: rightChildren,
                    followSymLinks: followSymLinks,
                    startIndex: r
                )

                if isExactlyMatch {
                    pos = insertOrphans(
                        atExactIndex: rightIndex,
                        leftRoot: leftRoot,
                        rightRoot: rightRoot,
                        alignConfig: alignConfig,
                        leftIndex: &l,
                        rightIndex: &r
                    )
                } else {
                    pos = insertOrphans(
                        atClosestIndex: rightIndex,
                        leftRoot: leftRoot,
                        rightRoot: rightRoot,
                        alignConfig: alignConfig,
                        leftIndex: &l,
                        rightIndex: &r
                    )
                }
            }
        }
        leftIndex = l
        rightIndex = r

        return pos
    }

    func insertOrphans(
        atExactIndex exactMatchRightIndex: Int,
        leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig,
        leftIndex l: inout Int,
        rightIndex r: inout Int
    ) -> ComparisonResult {
        while r < exactMatchRightIndex {
            insert(
                orphan: rightRoot.child(at: r),
                otherSide: leftRoot,
                alignConfig: alignConfig,
                leftIndex: &l,
                rightIndex: &r
            )
        }
        return .orderedSame
    }

    func insertOrphans(
        atClosestIndex closestRightIndex: Int,
        leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig,
        leftIndex l: inout Int,
        rightIndex r: inout Int
    ) -> ComparisonResult {
        let leftChildren = leftRoot.children
        let hasLeftMoreSameNames = (l + 1) < leftChildren.count
            && leftChildren[l].compare(
                forAlign: leftChildren[l + 1],
                followSymLinks: alignConfig.followSymLinks,
                insensitiveCompare: true
            ) == .orderedSame

        if hasLeftMoreSameNames {
            return .orderedAscending
        }
        while r < closestRightIndex {
            insert(
                orphan: rightRoot.child(at: r),
                otherSide: leftRoot,
                alignConfig: alignConfig,
                leftIndex: &l,
                rightIndex: &r
            )
        }
        return .orderedSame
    }

    func findInsertIndex(
        left: CompareItem,
        right: CompareItem,
        startIndex: Int,
        followSymLinks: Bool
    ) -> Int {
        for i in startIndex ..< right.children.count {
            let result = left.compare(
                forAlign: right.child(at: i),
                followSymLinks: followSymLinks,
                insensitiveCompare: true
            )
            if result == .orderedSame {
                return i
            }
            if result == .orderedDescending {
                return -1
            }
        }
        return -1
    }
}

func findExactlyMatchIndex(
    _ leftFileName: String,
    subfolders: [CompareItem],
    followSymLinks: Bool,
    startIndex: Int
) -> (isExactlyMatch: Bool, index: Int) {
    var isExactlyMatch = false
    var index = startIndex

    enumerateWithSameFileName(
        subfolders,
        startIndex: startIndex,
        followSymLinks: followSymLinks
    ) { item, i, stop in
        let fileName = item.fileName ?? ""
        let comparisonResult = leftFileName.localizedCompare(fileName)
        // update only if it isn't already found
        if index == startIndex, comparisonResult == .orderedAscending {
            index = i
        }
        if comparisonResult == .orderedSame {
            index = i
            isExactlyMatch = true
            stop = true
        }
    }
    return (isExactlyMatch, index)
}

func enumerateWithSameFileName(
    _ children: [CompareItem],
    startIndex: Int,
    followSymLinks: Bool,
    block: (CompareItem, Int, inout Bool) -> Void
) {
    var index = startIndex
    var item: CompareItem

    repeat {
        item = children[index]
        var stop = false
        block(item, index, &stop)
        if stop {
            break
        }
        index += 1
    } while index < children.count
        && item.compare(
            forAlign: children[index],
            followSymLinks: followSymLinks,
            insensitiveCompare: true
        ) == .orderedSame
}

// swiftlint:enable function_parameter_count
