//
//  FoldersWindowController+Comparison.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

import UserNotifications

extension CompareItem: @unchecked Sendable {}

public extension FoldersWindowController {
    // MARK: - Reload folders

    func reloadAll(_ refreshInfo: RefreshInfo) {
        if running {
            return
        }

        guard let leftPath = sessionDiff.resolvePath(
            for: .left,
            chooseFileType: .folder,
            alwaysResolveSymlinks: CommonPrefs.shared.alwaysResolveSymlinks
        ),
            let rightPath = sessionDiff.resolvePath(
                for: .right,
                chooseFileType: .folder,
                alwaysResolveSymlinks: CommonPrefs.shared.alwaysResolveSymlinks
            ) else {
            return
        }

        // release previously started bookmarks
        SecureBookmark.shared.stopAccessing(url: leftSecureURL)
        SecureBookmark.shared.stopAccessing(url: rightSecureURL)

        leftSecureURL = SecureBookmark.shared.secure(fromBookmark: leftPath, startSecured: true)
        rightSecureURL = SecureBookmark.shared.secure(fromBookmark: rightPath, startSecured: true)

        if refreshInfo.refreshFolders {
            leftItemOriginal = nil
            rightItemOriginal = nil
        }

        syncFolders(refreshInfo)
    }

    /**
     * refreshComparison is forced to YES if refreshLeftFolders or refreshRightFolders are YES
     * refreshDisplay is forced to YES if refreshComparison is YES
     */
    func syncFolders(_ refreshInfo: RefreshInfo) {
        guard let leftPath = sessionDiff.leftPath,
              let rightPath = sessionDiff.rightPath else {
            return
        }
        let comparatorDelegateBridge = MainThreadComparatorDelegateBridge(self)

        let folderReaderComparator = sessionDiff.comparator(
            withDelegate: comparatorDelegateBridge,
            bufferSize: CommonPrefs.shared.comparatorBinaryBufferSize
        )
        comparator = folderReaderComparator
        let folderDelegateBridge = MainThreadFolderReaderDelegateBridge(self)
        let filterConfig = FilterConfig(
            from: sessionDiff,
            showFilteredFiles: showFilteredFiles,
            hideEmptyFolders: hideEmptyFolders
        )

        let folderReader = FolderReader(
            with: folderDelegateBridge,
            comparator: folderReaderComparator,
            filterConfig: filterConfig,
            refreshInfo: refreshInfo
        )

        folderReader.startDetached(
            leftRoot: leftItemOriginal,
            rightRoot: rightItemOriginal,
            leftPath: URL(filePath: leftPath, directoryHint: .isDirectory),
            rightPath: URL(filePath: rightPath, directoryHint: .isDirectory)
        )
    }

    // MARK: - Comparison actions

    @objc func startComparison() {
        reloadAll(RefreshInfo(
            initState: true,
            expandAllFolders: sessionDiff.expandAllFolders
        ))
    }

    @objc func showEmptyFolders(_: AnyObject?) {
        hideEmptyFolders.toggle()

        scopeBar.hideEmptyFolders(hideEmptyFolders, informDelegate: false)

        CommonPrefs.shared.hideEmptyFolders = hideEmptyFolders

        reloadAll(RefreshInfo(initState: false))
    }

    @objc func noOrphansFolders(_: AnyObject?) {
        let displayOptions = sessionDiff.displayOptions.toggled(.noOrphansFolders)

        sessionDiff.displayOptions = displayOptions

        scopeBar.noOrphansFolders(
            displayOptions.contains(.noOrphansFolders),
            informDelegate: false
        )

        reloadAll(RefreshInfo(initState: false))
    }

    @objc func selectComparison(_ sender: AnyObject?) {
        guard let tag = sender?.selectedItem?.tag as? Int else {
            return
        }
        var compareFlags = sessionDiff.comparatorOptions.withoutMethodFlags
        compareFlags.insert(ComparatorOptions(rawValue: tag))
        sessionDiff.comparatorOptions = compareFlags

        let refreshInfo = RefreshInfo(
            initState: false,
            refreshComparison: true,
            expandAllFolders: sessionDiff.expandAllFolders
        )

        reloadAll(refreshInfo)
    }

    @objc func refresh(_: AnyObject) {
        reloadAll(RefreshInfo(
            initState: true,
            expandAllFolders: sessionDiff.expandAllFolders
        ))
    }

    @objc func toggleFilteredFiles(_: AnyObject?) {
        showFilteredFiles.toggle()

        scopeBar.showFilteredFiles(showFilteredFiles, informDelegate: false)

        reloadAll(RefreshInfo(initState: false))
    }

    // MARK: - FolderReaderDelegate Bridge

    func isRunning() -> Bool {
        running
    }

    func will(startAt _: Date) {
        PowerAssertion.shared.setDisableSystemSleep(true, with: NSLocalizedString("Folders reading and comparison", comment: ""))
        running = true

        setProgressHidden(false)
        progressView.updateMessage(sessionDiff.leftPath ?? "")
        leftPanelView.pathView.isEnabled = false
        rightPanelView.pathView.isEnabled = false

        scopeBar.setEnabledAllGroups(false)
    }

    func did(endAt: Date, startedAt: Date) {
        PowerAssertion.shared.setDisableSystemSleep(false, with: NSLocalizedString("Folders reading and comparison", comment: ""))
        running = false

        let elapsedTime = endAt.timeIntervalSinceReferenceDate - startedAt.timeIntervalSinceReferenceDate

        didComparisonCompleted(elapsedTime.format())
    }

    func rootFoldersDidRead(folderReader: FolderReader, foldersOnRoot: Int) {
        leftItemOriginal = folderReader.leftRoot
        rightItemOriginal = folderReader.rightRoot
        leftVisibleItems = leftItemOriginal?.visibleItem

        // reloadItem requires the parent to be already loaded so we refresh the root here
        // queue the operation to avoid deadlock and serialize execution
        sortBySessionColumn()

        progressView.setProgress(position: 0, maxValue: Double(foldersOnRoot))

        leftView.reloadData()
        leftView.linkedView?.reloadData()

        if folderReader.refreshInfo.expandAllFolders {
            leftView.expandItem(nil, expandChildren: true)
        }
    }

    func handleError(error: any Error, forPath path: URL) -> Bool {
        log(error: (error as NSError).format(withPath: path.osPath))

        return true
    }

    func willTraverse(_ item: CompareItem) {
        progressView.updateMessage(item.path ?? item.linkedItem?.path ?? "")
    }

    func didTraverse(folderReader: FolderReader, _ item: CompareItem) {
        sortBySessionColumn()

        progressView.advanceProgress()

        leftView.reloadItem(item.visibleItem, reloadChildren: true)
        leftView.linkedView?.reloadItem(item.visibleItem?.linkedItem, reloadChildren: true)
        if folderReader.refreshInfo.expandAllFolders {
            leftView.expandItem(item.visibleItem, expandChildren: true)
        }
    }

    func didComparisonCompleted(_ elapsedTimeText: String) {
        let leftSelection = leftView.getSelectedVisibleItems(true)
        let rightSelection = rightView.getSelectedVisibleItems(true)

        leftView.reloadData()
        rightView.reloadData()

        leftView.select(visibleItems: leftSelection)
        rightView.select(visibleItems: rightSelection)

//        selectFirstRow(leftSelection: leftSelection,
//                       rightSelection: rightSelection)

        updateBottomBar(leftView)
        updateBottomBar(rightView)
        updateStatusBar()

        scopeBar.setEnabledAllGroups(true)

        setProgressHidden(true)

        leftPanelView.pathView.isEnabled = true
        rightPanelView.pathView.isEnabled = true

        // force toolbar to enable items
        window?.toolbar?.validateVisibleItems()

        consoleView.log(info: String(format: NSLocalizedString("Comparison completed in %@", comment: ""), elapsedTimeText))
        showCompareCompleteNotification(elapsedTimeText)
    }

    func showCompareCompleteNotification(_ text: String) {
        guard let document = document as? VDDocument else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Folders comparison completed", comment: "")
        content.body = String(format: NSLocalizedString("'%@' completed in %@", comment: ""), document.displayName, text)
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        // ensure the identifier is unique per document
        let request = UNNotificationRequest(
            identifier: document.uuid,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
        NSApp.requestUserAttention(.informationalRequest)
    }

    // periphery:ignore
    private func selectFirstRow(
        leftSelection: [VisibleItem],
        rightSelection: [VisibleItem]
    ) {
        let suggestedRow = leftSelection.isEmpty ? -1 : leftView.row(forItem: leftSelection[0])
        let firstVisibleRow = leftView.ensureRowVisibility(suggestedRow: suggestedRow)

        if leftSelection.isEmpty {
            leftView.selectRowIndexes(IndexSet(integer: firstVisibleRow), byExtendingSelection: false)
        }
        if rightSelection.isEmpty {
            rightView.selectRowIndexes(IndexSet(integer: firstVisibleRow), byExtendingSelection: false)
        }
    }

    private func setProgressHidden(_ hidden: Bool) {
        if hidden {
            differenceCounters.isHidden = false
            statusbarText.isHidden = false
            progressView.isHidden = true
        } else {
            differenceCounters.isHidden = true
            statusbarText.isHidden = true
            progressView.isHidden = false
        }
    }
}
