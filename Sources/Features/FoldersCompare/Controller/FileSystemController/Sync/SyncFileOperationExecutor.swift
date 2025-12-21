//
//  SyncFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class SyncFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    typealias TPayload = Payload

    struct Payload: Sendable {
        let srcBaseDir: String
        let destBaseDir: String
        let copyDestFiles: Bool
        let copyEmptyFolders: Bool
    }

    var title = NSLocalizedString("Sync", comment: "")
    var summary = NSLocalizedString("Copy newer and orphan files to other side", comment: "")
    var image: NSImage?
    var progressLabel = ""
    var prefName: CommonPrefs.Name?

    // delete operation doesn't use it
    var operationOnSingleItem = false

    private(set) var side: DisplaySide

    private var selectedItems: SyncItemsInfo
    private var allItems: SyncItemsInfo

    var syncSelection = false
    var syncBothSides = false

    var hasSelectedItems: Bool {
        let nodesCount = selectedItems.nodes?.items?.count ?? 0
        let emptyNodeCount = selectedItems.emptyFoldersNodes?.items?.count ?? 0

        return nodesCount != 0 || emptyNodeCount != 0
    }

    var itemsInfo: SyncItemsInfo {
        syncSelection ? selectedItems : allItems
    }

    init(side: DisplaySide) {
        self.side = side

        selectedItems = SyncItemsInfo()
        selectedItems.linkedInfo = SyncItemsInfo()
        selectedItems.linkedInfo?.linkedInfo = selectedItems

        allItems = SyncItemsInfo()
        allItems.linkedInfo = SyncItemsInfo()
        allItems.linkedInfo?.linkedInfo = allItems
    }

    func execute(_ manager: FileOperationManagerAction, payload: Payload?) {
        guard let payload else {
            fatalError("Missing payload")
        }
        let srcBaseDir = payload.srcBaseDir
        let destBaseDir = payload.destBaseDir
        let items = payload.copyDestFiles ? itemsInfo.linkedInfo : itemsInfo
        let nodes = payload.copyEmptyFolders ? items?.emptyFoldersNodes : items?.nodes

        guard let nodes = nodes?.items else {
            return
        }

        for item in nodes {
            manager.copy(
                item,
                srcBaseDir: srcBaseDir,
                destBaseDir: destBaseDir
            )
        }
    }
}

extension SyncFileOperationExecutor {
    /**
     * Build the tree putting items in the correct order
     * 1. Folders to create on left (if any)
     * 2. Folders to create on right (if any)
     * 3. Files to copy on left (if any)
     * 4. Files to copy on right (if any)
     */
    func buildTree(
        srcItemsInfo: SyncItemsInfo,
        destItemsInfo: SyncItemsInfo,
        syncBothSides: Bool,
        createEmptyFolders: Bool
    ) {
        if side == .left {
            if createEmptyFolders {
                if syncBothSides,
                   let emptyFoldersNodes = srcItemsInfo.linkedInfo?.emptyFoldersNodes {
                    destItemsInfo.add(emptyFoldersNodes)
                }
                if let emptyFoldersNodes = srcItemsInfo.emptyFoldersNodes {
                    destItemsInfo.add(emptyFoldersNodes)
                }
            }
            if syncBothSides,
               let nodes = srcItemsInfo.linkedInfo?.nodes {
                destItemsInfo.add(nodes)
            }
            if let nodes = srcItemsInfo.nodes {
                destItemsInfo.add(nodes)
            }
        } else {
            if createEmptyFolders {
                if let emptyFoldersNodes = srcItemsInfo.emptyFoldersNodes {
                    destItemsInfo.add(emptyFoldersNodes)
                }
                if syncBothSides {
                    if let emptyFoldersNodes = srcItemsInfo.linkedInfo?.emptyFoldersNodes {
                        destItemsInfo.add(emptyFoldersNodes)
                    }
                }
            }
            if let nodes = srcItemsInfo.nodes {
                destItemsInfo.add(nodes)
            }
            if syncBothSides {
                if let nodes = srcItemsInfo.linkedInfo?.nodes {
                    destItemsInfo.add(nodes)
                }
            }
        }
    }

    @MainActor func prepareSyncItemsInfo(
        items itemsToSync: SyncItemsInfo,
        withSelection useSelection: Bool,
        syncBothSides: Bool,
        createEmptyFolders: Bool,
        view: FoldersOutlineView
    ) {
        itemsToSync.removeAll()

        if useSelection {
            if selectedItems.nodes?.items == nil {
                fillSyncItemsInfo(
                    selectedItems,
                    srcArray: view.selectedItems(),
                    foldersView: view
                )
            }
            if syncBothSides {
                if selectedItems.linkedInfo?.nodes?.items == nil {
                    var arr = [CompareItem]()
                    for item in view.selectedItems() {
                        if let linkedItem = item.linkedItem {
                            arr.append(linkedItem)
                        }
                    }
                    if let linkedInfo = selectedItems.linkedInfo,
                       let linkedView = view.linkedView {
                        fillSyncItemsInfo(
                            linkedInfo,
                            srcArray: arr,
                            foldersView: linkedView
                        )
                    }
                }
            }
            itemsToSync.totalSize = selectedItems.totalSize
            itemsToSync.nodes?.items = selectedItems.nodes?.items

            buildTree(
                srcItemsInfo: selectedItems,
                destItemsInfo: itemsToSync,
                syncBothSides: syncBothSides,
                createEmptyFolders: createEmptyFolders
            )
        } else {
            if allItems.nodes?.items == nil {
                if let vi = view.dataSource?.outlineView?(view, child: 0, ofItem: nil) as? VisibleItem,
                   let root = vi.item.parent {
                    fillSyncItemsInfo(
                        allItems,
                        srcArray: [root],
                        foldersView: view
                    )
                }
            }
            if syncBothSides {
                if allItems.linkedInfo?.nodes?.items == nil {
                    if let linkedView = view.linkedView,
                       let vi = linkedView.dataSource?.outlineView?(linkedView, child: 0, ofItem: nil) as? VisibleItem,
                       let root = vi.item.parent,
                       let linkedInfo = allItems.linkedInfo {
                        fillSyncItemsInfo(
                            linkedInfo,
                            srcArray: [root],
                            foldersView: linkedView
                        )
                    }
                }
            }
            itemsToSync.totalSize = allItems.totalSize
            itemsToSync.nodes?.items = allItems.nodes?.items

            buildTree(
                srcItemsInfo: allItems,
                destItemsInfo: itemsToSync,
                syncBothSides: syncBothSides,
                createEmptyFolders: createEmptyFolders
            )
        }
    }

    @MainActor func fillSyncItemsInfo(
        _ syncItems: SyncItemsInfo,
        srcArray: [CompareItem],
        foldersView: FoldersOutlineView
    ) {
        var files = [CompareItem]()
        var emptyFolders = [CompareItem]()
        syncItems.totalSize = 0

        for item in srcArray {
            syncItems.totalSize += getSyncableList(
                item,
                files: &files,
                emptyFoldersList: &emptyFolders
            )
        }
        let vi = foldersView.dataSource?.outlineView?(foldersView, child: 0, ofItem: nil) as? VisibleItem
        let rootPath = vi?.item.parent?.path ?? ""

        // copy direction is the inverse of displayPosition
        let direction: DisplaySide = foldersView.side == .left ? .right : .left
        var text = String.localizedStringWithFormat(
            NSLocalizedString("Copy %ld files (%@) to %lu", comment: "Copy 3 files (10.4MB) to left/right"),
            files.count,
            FileSizeFormatter.default.string(from: NSNumber(value: syncItems.totalSize)) ?? "0",
            direction.rawValue
        )
        syncItems.nodes = DescriptionOutlineNode(
            relativePath: text,
            items: files,
            rootPath: rootPath
        )

        text = String.localizedStringWithFormat(
            NSLocalizedString("Create %ld empty folders on %lu", comment: "Create 1 empty folder on left/right"),
            emptyFolders.count,
            direction.rawValue
        )
        syncItems.emptyFoldersNodes = DescriptionOutlineNode(
            relativePath: text,
            items: emptyFolders,
            rootPath: rootPath
        )
    }

    /**
     * emptyFoldersList contains also filtered folders
     */
    func getSyncableList(
        _ root: CompareItem,
        files: inout [CompareItem],
        emptyFoldersList: inout [CompareItem]
    ) -> Int64 {
        if !root.isValidFile {
            return 0
        }
        // if called directly on a file or an empty folder create a temp array
        // otherwise this element is skipped
        let subfolders = root.children.isEmpty ? [root] : root.children

        var size: Int64 = 0
        var filteredCount = 0

        for item in subfolders where item.isValidFile {
            if item.isFiltered || !item.isDisplayed {
                filteredCount += 1
                continue
            }
            if item.isFile {
                if item.type == .orphan || item.linkedItem?.type == .old {
                    size += item.fileSize
                    files.append(item)
                }
            } else {
                if item.children.isEmpty {
                    if let linkedItem = item.linkedItem, !linkedItem.isValidFile {
                        emptyFoldersList.append(item)
                    }
                } else {
                    let listCount = files.count
                    let emptyFoldersCount = emptyFoldersList.count

                    size += getSyncableList(item, files: &files, emptyFoldersList: &emptyFoldersList)
                    if listCount == files.count,
                       emptyFoldersCount == emptyFoldersList.count,
                       let linkedItem = item.linkedItem,
                       !linkedItem.isValidFile {
                        emptyFoldersList.append(item)
                    }
                }
            }
        }

        // root contains only filtered objects so it is an "empty" folder
        if root.isFolder,
           let linkedItem = root.linkedItem,
           !linkedItem.isValidFile {
            if filteredCount == root.children.count {
                emptyFoldersList.append(root)
            }
        }
        return size
    }
}
