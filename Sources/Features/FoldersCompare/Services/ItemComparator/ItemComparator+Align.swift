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

public struct AlignContext {
    let leftRoot: CompareItem
    let rightRoot: CompareItem
    let config: AlignConfig
}

public struct AlignPosition {
    var leftIndex = 0
    var rightIndex = 0

    func leftChild(in context: AlignContext) -> CompareItem {
        context.leftRoot.child(at: leftIndex)
    }

    func rightChild(in context: AlignContext) -> CompareItem {
        context.rightRoot.child(at: rightIndex)
    }
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

public extension ItemComparator {
    func alignItem(
        _ context: AlignContext
    ) {
        var position = AlignPosition()
        var leftChildrenCount = context.leftRoot.children.count
        var rightChildrenCount = context.rightRoot.children.count

        while (position.leftIndex < leftChildrenCount) || (position.rightIndex < rightChildrenCount) {
            var pos: ComparisonResult

            if position.leftIndex >= leftChildrenCount {
                pos = .orderedDescending
            } else if position.rightIndex >= rightChildrenCount {
                pos = .orderedAscending
            } else {
                let lChild = position.leftChild(in: context)
                let rChild = position.rightChild(in: context)

                if (lChild.isValidFile && rChild.isValidFile) || bothInvalidWithPath(lChild, rChild) {
                    pos = align(context, position: &position)
                } else {
                    if !lChild.isValidFile {
                        position.leftIndex += 1
                    }
                    if !rChild.isValidFile {
                        position.rightIndex += 1
                    }
                    continue
                }
            }
            if pos == .orderedSame {
                // both indices are valid here: orderedSame is only set from the else branch above
                let lChild = position.leftChild(in: context)
                let rChild = position.rightChild(in: context)
                if lChild.isFile, rChild.isFile {
                    // ignore this case
                } else {
                    if context.config.recursive {
                        alignItem(AlignContext(
                            leftRoot: lChild,
                            rightRoot: rChild,
                            config: context.config
                        ))
                    }
                }

                lChild.linkedItem = rChild
                rChild.linkedItem = lChild

                position.leftIndex += 1
                position.rightIndex += 1
            } else if pos == .orderedAscending {
                // insert left orphan
                insert(
                    orphan: position.leftChild(in: context),
                    otherSide: context.rightRoot,
                    context: context,
                    position: &position
                )
            } else if pos == .orderedDescending {
                // insert right orphan
                insert(
                    orphan: position.rightChild(in: context),
                    otherSide: context.leftRoot,
                    context: context,
                    position: &position
                )
            } else {
                Logger.general.error("Invalid pos value \(pos.rawValue)")
            }
            leftChildrenCount = context.leftRoot.children.count
            rightChildrenCount = context.rightRoot.children.count
        }
    }

    func insert(
        orphan: CompareItem,
        otherSide: CompareItem,
        context: AlignContext,
        position: inout AlignPosition
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
        otherSide.insert(child: newItem, at: position.leftIndex)

        if context.config.recursive {
            alignItem(AlignContext(
                leftRoot: orphan,
                rightRoot: otherSide.child(at: position.leftIndex),
                config: context.config
            ))
        }
        position.leftIndex += 1
        position.rightIndex += 1
    }

    func align(
        _ context: AlignContext,
        position: inout AlignPosition
    ) -> ComparisonResult {
        if let fileNameAlignments, !fileNameAlignments.isEmpty {
            return alignByRegularExpression(
                context,
                position: &position
            )
        }
        return alignByFileName(
            context,
            position: &position
        )
    }

    // MARK: - Filenames alignment

    func alignByFileName(
        _ context: AlignContext,
        position: inout AlignPosition
    ) -> ComparisonResult {
        var pos: ComparisonResult = .orderedSame
        let rightChildren = context.rightRoot.children
        let followSymLinks = context.config.followSymLinks

        if isLeftCaseSensitive, isRightCaseSensitive {
            pos = position.leftChild(in: context).compare(
                forAlign: position.rightChild(in: context),
                followSymLinks: followSymLinks,
                insensitiveCompare: false
            )
        } else if !isLeftCaseSensitive, !isRightCaseSensitive {
            pos = position.leftChild(in: context).compare(
                forAlign: position.rightChild(in: context),
                followSymLinks: followSymLinks,
                insensitiveCompare: true
            )
        } else {
            let leftChild = position.leftChild(in: context)
            let index = findInsertIndex(
                left: leftChild,
                right: context.rightRoot,
                startIndex: position.rightIndex,
                followSymLinks: followSymLinks
            )
            // left name doesn't exist on right so determine the insertion point using a match case
            if index == -1 {
                pos = leftChild.compare(
                    forAlign: position.rightChild(in: context),
                    followSymLinks: followSymLinks,
                    insensitiveCompare: false
                )
            } else {
                while position.rightIndex < index {
                    insert(
                        orphan: position.rightChild(in: context),
                        otherSide: context.leftRoot,
                        context: context,
                        position: &position
                    )
                }
                let leftFileName = position.leftChild(in: context).fileName ?? ""
                let (isExactlyMatch, matchIndex) = findExactlyMatchIndex(
                    leftFileName,
                    subfolders: rightChildren,
                    followSymLinks: followSymLinks,
                    startIndex: position.rightIndex
                )

                if isExactlyMatch {
                    pos = insertOrphans(
                        atExactIndex: matchIndex,
                        context: context,
                        position: &position
                    )
                } else {
                    pos = insertOrphans(
                        atClosestIndex: matchIndex,
                        context: context,
                        position: &position
                    )
                }
            }
        }

        return pos
    }

    func insertOrphans(
        atExactIndex exactMatchRightIndex: Int,
        context: AlignContext,
        position: inout AlignPosition
    ) -> ComparisonResult {
        while position.rightIndex < exactMatchRightIndex {
            insert(
                orphan: position.rightChild(in: context),
                otherSide: context.leftRoot,
                context: context,
                position: &position
            )
        }
        return .orderedSame
    }

    func insertOrphans(
        atClosestIndex closestRightIndex: Int,
        context: AlignContext,
        position: inout AlignPosition
    ) -> ComparisonResult {
        let leftChildren = context.leftRoot.children
        let l = position.leftIndex
        let hasLeftMoreSameNames = (l + 1) < leftChildren.count
            && leftChildren[l].compare(
                forAlign: leftChildren[l + 1],
                followSymLinks: context.config.followSymLinks,
                insensitiveCompare: true
            ) == .orderedSame

        if hasLeftMoreSameNames {
            return .orderedAscending
        }
        while position.rightIndex < closestRightIndex {
            insert(
                orphan: position.rightChild(in: context),
                otherSide: context.leftRoot,
                context: context,
                position: &position
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
