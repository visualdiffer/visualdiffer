//
//  FoldersWindowController+FileSystemControllerDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: @preconcurrency FileSystemControllerDelegate {
    private typealias FileOperationManagerBuilder =
        (FilterConfig, ItemComparator, FileOperationManagerDelegate) -> FileOperationManager

    @objc
    func copyFiles(_ sender: AnyObject?) {
        guard let vi = lastUsedView.dataSource?.outlineView?(lastUsedView, child: 0, ofItem: nil) as? VisibleItem,
              let root = vi.item.parent,
              let srcBaseDir = root.path,
              let destBaseDir = root.linkedItem?.path else {
            return
        }
        let executor = CopyFileOperationExecutor(
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            items: lastUsedView.selectedItems(),
            side: lastUsedView.side
        )
        run(executor) { config, comparator, delegate in
            FileOperationManager(
                filterConfig: config,
                comparator: comparator,
                delegate: delegate,
                copyFinderMetadataOnly: CopyFilesTag.isCopyFinderMetadataOnly(sender: sender)
            )
        }
    }

    @objc
    func deleteFiles(_: AnyObject?) {
        guard let vi = lastUsedView.dataSource?.outlineView?(lastUsedView, child: 0, ofItem: nil) as? VisibleItem,
              let root = vi.item.parent,
              let srcBaseDir = root.path else {
            return
        }
        let executor = DeleteFileOperationExecutor(
            srcBaseDir: srcBaseDir,
            items: lastUsedView.selectedItems()
        )
        run(executor)
    }

    @objc
    func moveFiles(_: AnyObject?) {
        guard let vi = lastUsedView.dataSource?.outlineView?(lastUsedView, child: 0, ofItem: nil) as? VisibleItem,
              let root = vi.item.parent,
              let srcBaseDir = root.path,
              let destBaseDir = root.linkedItem?.path else {
            return
        }
        let executor = MoveFileOperationExecutor(
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            items: lastUsedView.selectedItems(),
            side: lastUsedView.side
        )
        run(executor)
    }

    @objc
    func syncFiles(_: AnyObject?) {
        guard let window else {
            return
        }

        let pic = ProgressIndicatorController()
        progressIndicatorController = pic
        let delegate = FileOperationManagerDelegateImpl(progressIndicatorController: pic)
        let executor = SyncFileOperationExecutor(side: lastUsedView.side)
        let fileSystemController = SyncFileController(
            executor: executor,
            fileOperationManager: createLocalFileManager(delegate: delegate),
            view: lastUsedView,
            progressIndicatorController: pic
        )

        fileSystemController.delegate = self
        fileSystemController.beginSheetModal(for: window)
    }

    @objc
    func setModificationDate(_: AnyObject) {
        guard let window else {
            return
        }

        let pic = ProgressIndicatorController()
        progressIndicatorController = pic
        let delegate = FileOperationManagerDelegateImpl(progressIndicatorController: pic)
        let executor = TouchFileOperationExecutor(items: lastUsedView.selectedItems())
        let fileSystemController = TouchController(
            executor: executor,
            fileOperationManager: createLocalFileManager(delegate: delegate),
            view: lastUsedView,
            progressIndicatorController: pic,
            filteredFileVisible: showFilteredFiles
        )
        fileSystemController.delegate = self
        fileSystemController.beginSheetModal(for: window)
    }

    // MARK: - File Operations Delegate

    @MainActor
    public func fileSystem(
        _: FileSystemController<some FileOperationExecutor>,
        restoreSelection selectedVisibleItems: [VisibleItem],
        errors: [any Error]?
    ) {
        // reload data before working on selection to prevent errors
        // on not updated rows count (see bug 0000063)
        leftView.reloadData()
        rightView.reloadData()

        // Deselect all items otherwise after removing items from tree
        // the visible items will contain incorrect selection
        leftView.deselectAll(nil)
        rightView.deselectAll(nil)

        updateBottomBar(leftView)
        updateBottomBar(rightView)
        updateStatusBar()

        lastUsedView.restoreSelectionAndFocusPosition(selectedVisibleItems)

        let suggestedRow = selectedVisibleItems.isEmpty ? -1 : leftView.row(forItem: selectedVisibleItems[0])
        leftView.ensureRowVisibility(suggestedRow: suggestedRow)
        showErrorsAfterFileSystemOperation(errors)
    }

    // MARK: - Internal Helpers

    private func showErrorsAfterFileSystemOperation(_: [any Error]?) {
        // Bouncing Dock Icon on complete
        NSApp.requestUserAttention(.informationalRequest)
    }

    private func run(
        _ executor: some FileOperationExecutor,
        builder: FileOperationManagerBuilder? = nil
    ) {
        guard let window else {
            return
        }
        let pic = ProgressIndicatorController()
        progressIndicatorController = pic
        let delegate = FileOperationManagerDelegateImpl(progressIndicatorController: pic)
        let fileSystemController = FileSystemController(
            executor: executor,
            fileOperationManager: createLocalFileManager(delegate: delegate, builder: builder),
            view: lastUsedView,
            progressIndicatorController: pic,
            filteredFileVisible: showFilteredFiles
        )
        fileSystemController.delegate = self
        fileSystemController.beginSheetModal(for: window)
    }

    private func createLocalFileManager(
        delegate: FileOperationManagerDelegate,
        builder: FileOperationManagerBuilder? = nil
    ) -> FileOperationManager {
        guard let comparator else {
            fatalError("Comparator not found")
        }
        let config = FilterConfig(
            from: sessionDiff,
            showFilteredFiles: showFilteredFiles,
            hideEmptyFolders: hideEmptyFolders
        )
        guard let builder else {
            return FileOperationManager(
                filterConfig: config,
                comparator: comparator,
                delegate: delegate
            )
        }
        return builder(config, comparator, delegate)
    }
}
