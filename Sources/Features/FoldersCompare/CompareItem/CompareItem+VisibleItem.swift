//
//  CompareItem+VisibleItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension DisplayOptions {
    func showsOnlyMismatchesOrOrphans() -> Bool {
        // .showAll contains also the flag .onlyMismatches
        // so we can't simply check .onlyMismatches but we must be sure
        // .showAll is turned off at all
        !contains(.showAll) && (contains(.onlyMismatches) || contains(.onlyOrphans))
    }
}

extension CompareItem {
    func removeVisibleItems(
        showFilteredFiles: Bool,
        displayOptions: DisplayOptions,
        hideEmptyFolders: Bool,
        followSymLinks: Bool,
        recursive: Bool
    ) -> Bool {
        var isRemovable = false
        var removed = false
        let leftItem = self
        guard let rightItem = leftItem.linkedItem else {
            return false
        }

        if leftItem.isFolder {
            if recursive {
                for item in leftItem.children {
                    _ = item.removeVisibleItems(
                        showFilteredFiles: showFilteredFiles,
                        displayOptions: displayOptions,
                        hideEmptyFolders: hideEmptyFolders,
                        followSymLinks: followSymLinks,
                        recursive: true
                    )
                }
            }
            if !followSymLinks, leftItem.isSymbolicLink || rightItem.isSymbolicLink {
                let dontFollowSymbolicLinks = displayOptions.union(.dontFollowSymlinks)
                let isDisplayable = dontFollowSymbolicLinks.isDisplayable(
                    leftItem,
                    rightItem: rightItem
                )
                leftItem.isDisplayed = isDisplayable
                rightItem.isDisplayed = isDisplayable
                isRemovable = !isDisplayable
            } else {
                // folders have the flag always set to true
                leftItem.isDisplayed = true
                rightItem.isDisplayed = true

                var hideOrphanFolders = false

                if !hideEmptyFolders,
                   displayOptions.showsOnlyMismatchesOrOrphans(),
                   leftItem.orphanFolders == 0, rightItem.orphanFolders == 0,
                   leftItem.isFolder, leftItem.summary.containsOnlyMatches(),
                   rightItem.isFolder, rightItem.summary.containsOnlyMatches() {
                    hideOrphanFolders = true
                } else if displayOptions.contains(.noOrphansFolders) {
                    hideOrphanFolders = !leftItem.isValidFile || !rightItem.isValidFile
                }
                if hideOrphanFolders {
                    isRemovable = true
                } else {
                    if let viLeft = leftItem.visibleItem,
                       let viRight = rightItem.visibleItem {
                        let isEmpty = viLeft.childrenAllFiltered && viRight.childrenAllFiltered
                        isRemovable = hideEmptyFolders && isEmpty
                    }
                }
            }
        } else {
            let isDisplayable = displayOptions.isDisplayable(leftItem, rightItem: rightItem)
            leftItem.isDisplayed = isDisplayable
            rightItem.isDisplayed = isDisplayable
            isRemovable = !leftItem.isDisplayed
        }
        if isRemovable {
            if showFilteredFiles {
                leftItem.isFiltered = true
                rightItem.isFiltered = true
            } else {
                if let vi = leftItem.visibleItem {
                    leftItem.parent?.visibleItem?.remove(vi)
                }
                if let vi = rightItem.visibleItem {
                    rightItem.parent?.visibleItem?.remove(vi)
                }
                removed = true
            }
        }
        return removed
    }

    func refresh(
        filterConfig: FilterConfig,
        comparator: ItemComparator
    ) {
        guard let destRoot = linkedItem,
              isFile,
              destRoot.isFile else {
            return
        }

        var srcCount = CompareSummary()
        var destCount = CompareSummary()

        var srcDiffSize = fileSize
        var destDiffSize = destRoot.fileSize
        let fm = FileManager.default

        if let path {
            setAttributes(try? fm.attributesOfItem(atPath: path), fileExtraOptions: filterConfig.fileExtraOptions)
        }
        if let path = destRoot.path {
            destRoot.setAttributes(try? fm.attributesOfItem(atPath: path), fileExtraOptions: filterConfig.fileExtraOptions)
        }

        srcDiffSize = fileSize - srcDiffSize
        destDiffSize = destRoot.fileSize - destDiffSize

        srcCount += summary
        destCount += destRoot.summary

        comparator.compare(self, destRoot)
        removeVisibleItems(filterConfig: filterConfig)

        srcCount -= summary
        destCount -= destRoot.summary

        // if nothing has been changed don't try to update parents
        if srcCount.olderFiles == 0, srcCount.changedFiles == 0,
           srcCount.orphanFiles == 0, srcCount.matchedFiles == 0,
           destCount.olderFiles == 0, destCount.changedFiles == 0,
           destCount.orphanFiles == 0, destCount.matchedFiles == 0,
           destCount.subfoldersSize == 0,
           srcDiffSize == 0, destDiffSize == 0 {
            return
        }

        var parent = parent
        while let item = parent {
            item.addOlderFiles(-srcCount.olderFiles)
            item.addChangedFiles(-srcCount.changedFiles)
            item.addOrphanFiles(-srcCount.orphanFiles)
            item.addMatchedFiles(srcCount.matchedFiles)
            item.addSubfoldersSize(srcDiffSize)

            if let destItem = item.linkedItem {
                destItem.addOlderFiles(-destCount.olderFiles)
                destItem.addChangedFiles(-destCount.changedFiles)
                destItem.addOrphanFiles(-destCount.orphanFiles)
                destItem.addMatchedFiles(destCount.matchedFiles)
                destItem.addSubfoldersSize(destDiffSize)
            }

            item.removeVisibleItems(filterConfig: filterConfig)

            parent = item.parent
        }
    }

    @discardableResult
    func filterVisibleItems(
        showFilteredFiles: Bool,
        hideEmptyFolders: Bool,
        recursive: Bool
    ) -> VisibleItem {
        var leftVisible: VisibleItem
        var rightVisible: VisibleItem?

        if let vi = visibleItem {
            leftVisible = vi
            rightVisible = vi.linkedItem
        } else {
            leftVisible = VisibleItem.createLinked(self)
            rightVisible = leftVisible.linkedItem
        }

        guard let rightVisible else {
            return leftVisible
        }

        leftVisible.removeAll()
        rightVisible.removeAll()

        for left in children {
            if showFilteredFiles || !left.isFiltered {
                var newDestLeft = left.visibleItem
                var addItem = true

                if left.isFolder {
                    if recursive {
                        newDestLeft = left.filterVisibleItems(
                            showFilteredFiles: showFilteredFiles,
                            hideEmptyFolders: hideEmptyFolders,
                            recursive: true
                        )
                    }

                    if hideEmptyFolders, let newDestLeft {
                        addItem = !newDestLeft.children.isEmpty
                    }
                }

                if addItem {
                    if newDestLeft == nil {
                        newDestLeft = VisibleItem.createLinked(left)
                    }
                    if let newDestLeft {
                        leftVisible.add(newDestLeft)
                        if let linkedItem = newDestLeft.linkedItem {
                            rightVisible.add(linkedItem)
                        }
                    }
                }
            }
        }

        return leftVisible
    }
}
