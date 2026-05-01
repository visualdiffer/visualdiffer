//
//  FoldersWindowController+UISetup.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import UserNotifications

private final class RefreshItemComparatorDelegate: ItemComparatorDelegate {
    var isRunning: Bool

    init(isRunning: Bool = true) {
        self.isRunning = isRunning
    }

    func isRunning(_: ItemComparator) -> Bool {
        isRunning
    }
}

extension FoldersWindowController {
    func initAllViews() {
        setupWindowLayout()
        setupFoldersLayout()

        leftPanelView.treeView.nextKeyView = rightView
        lastUsedView = leftPanelView.treeView

        updateTreeViewFont()

        adjustTableColumnsWidth()
        setProgressHidden(true)

        // must be called after setting up all views
        setupWindow()
    }

    func setupWindowLayout() {
        guard let window,
              let contentView = window.contentView else {
            return
        }

        contentView.addSubview(consoleSplitter)
        contentView.addSubview(scopeBar)
        contentView.addSubview(statusbar)

        setupConstraints()
    }

    func setupFoldersLayout() {
        leftPanelView.setLinkPanels(rightPanelView)
    }

    func setupConstraints() {
        guard let contentView = window?.contentView else {
            return
        }

        var leadingMargin: CGFloat = 6
        var trailingMargin: CGFloat = 6
        if #available(macOS 26, *) {
            leadingMargin = 16
            trailingMargin = 16
        }

        NSLayoutConstraint.activate([
            scopeBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scopeBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scopeBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
            scopeBar.heightAnchor.constraint(equalToConstant: 25),

            statusbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            statusbar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -trailingMargin),
            statusbar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            statusbar.heightAnchor.constraint(equalToConstant: 20),

            consoleSplitter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            consoleSplitter.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            consoleSplitter.topAnchor.constraint(equalTo: scopeBar.bottomAnchor),
            consoleSplitter.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22),
        ])
    }

    func updateTreeViewFont() {
        let font = treeViewFont()
        leftPanelView.treeView.updateFont(font, reloadData: true)
        rightPanelView.treeView.updateFont(font, reloadData: true)
    }

    func treeViewFont() -> NSFont {
        currentFont = CommonPrefs.shared.folderListingFont
        if fontZoomFactor != 0 {
            currentFont = NSFontManager.shared.convert(
                currentFont,
                toSize: currentFont.pointSize + fontZoomFactor
            )
        }

        return currentFont
    }

    func adjustTableColumnsWidth() {
        dontResizeColumns = true

        leftView.adjustColumnsWidths(currentFont, dateFormatTemplate: CommonPrefs.shared.folderViewDateFormat)
        rightView.adjustColumnsWidths(currentFont, dateFormatTemplate: CommonPrefs.shared.folderViewDateFormat)

        dontResizeColumns = false
    }

    func setupWindow() {
        guard let window else {
            return
        }

        window.delegate = self
        window.toolbar = NSToolbar(identifier: "FoldersToolbar", delegate: self)
        window.makeFirstResponder(leftPanelView.treeView)

        window.collectionBehavior = [window.collectionBehavior, .fullScreenPrimary]
    }

    /**
     * Setup elements requiring the sessionDiff is correctly defined, this method must be called after setDocument
     */
    func setupUIState() {
        setupObservers()

        comparatorMethod = sessionDiff.comparatorOptions.onlyMethodFlags

        hideEmptyFolders = CommonPrefs.shared.hideEmptyFolders

        window?.setFrameAutosaveName(String(format: "%lx%lx", sessionDiff.leftPath?.hash ?? 0, sessionDiff.rightPath?.hash ?? 0))

        scopeBar.findView.delegate = FoldersOutlineViewFindTextDelegate(view: leftView)
        updateScopeBar()
        setupSortDescriptors()
        setupConsoleSplitter()

        leftPanelView.bindControls()
        rightPanelView.bindControls()
    }

    func setupObservers() {
        // a register for those notifications on the synchronized content view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fontDidChange),
            name: .prefsChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshCompareItem),
            name: .fileSaved,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appAppearanceDidChange),
            name: .appAppearanceDidChange,
            object: nil
        )

        let comparatorOptionsObservation = sessionDiff.observeComparatorOptions { flags in
            Task { @MainActor in
                self.comparatorMethod = flags.onlyMethodFlags
            }
        }

        observations.append(contentsOf: [comparatorOptionsObservation])

        UNUserNotificationCenter.current().delegate = self
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: .prefsChanged,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .fileSaved,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .appAppearanceDidChange,
            object: nil
        )

        observations.forEach { $0.invalidate() }

        // don't show notification if this window is closing
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func updateScopeBar() {
        let displayOptions = sessionDiff.displayOptions

        scopeBar.select(displayOptions, informDelegate: false)
        scopeBar.showFilteredFiles(showFilteredFiles, informDelegate: false)
        scopeBar.hideEmptyFolders(hideEmptyFolders, informDelegate: false)
        scopeBar.noOrphansFolders(displayOptions.contains(.noOrphansFolders), informDelegate: false)
    }

    func setupSortDescriptors() {
        let view = sessionDiff.currentSortSide == .left ? leftView : rightView
        view.sortDescriptors = [sessionDiff.columnSortDescriptor()]
    }

    func setupConsoleSplitter() {
        consoleSplitter.delegate = consoleDelegate
        consoleSplitter.collapseSubview(at: 1)
    }

    @objc
    func appAppearanceDidChange(_: Notification) {
        leftView.reloadData()
        rightView.reloadData()

        updateStatusBar()
    }

    @objc
    func refreshCompareItem(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let leftItemOriginal,
              let rightItemOriginal,
              let sessionLeftPath = sessionDiff.leftPath,
              let sessionRightPath = sessionDiff.rightPath else {
            return
        }

        var item: CompareItem?
        var view: FoldersOutlineView = leftView

        if let leftPath = userInfo[FileSavedKey.leftPath] as? String {
            if leftPath.hasPrefix(sessionLeftPath) {
                item = CompareItem.find(withPath: leftPath, from: leftItemOriginal)
            }
            if item == nil, leftPath.hasPrefix(sessionRightPath) {
                item = CompareItem.find(withPath: leftPath, from: rightItemOriginal)
                view = rightView
            }
        }

        if let rightPath = userInfo[FileSavedKey.rightPath] as? String {
            if item == nil, rightPath.hasPrefix(sessionLeftPath) {
                item = CompareItem.find(withPath: rightPath, from: leftItemOriginal)
            }
            if item == nil, rightPath.hasPrefix(sessionRightPath) {
                item = CompareItem.find(withPath: rightPath, from: rightItemOriginal)
                view = rightView
            }
        }

        guard let item,
              let comparator else {
            return
        }

        let filterConfig = FilterConfig(
            from: sessionDiff,
            showFilteredFiles: showFilteredFiles,
            hideEmptyFolders: hideEmptyFolders
        )

        // capture before refresh - may be filtered out after type changes to .same
        let anchor = item.visibleItem

        let refreshDelegate = RefreshItemComparatorDelegate()
        let refreshComparator = comparator.copy(delegate: refreshDelegate)

        withExtendedLifetime(refreshDelegate) {
            item.refresh(
                filterConfig: filterConfig,
                comparator: refreshComparator
            )
        }

        leftView.reloadData()
        rightView.reloadData()

        restoreSelectionAfterRefresh(
            item: item,
            anchor: anchor,
            view: view,
            limitToCurrentFolder: false
        )
    }

    func updateBottomBar(_ view: FoldersOutlineView) {
        if view.side == .left {
            leftPanelView.updateBottomBar()
        } else {
            rightPanelView.updateBottomBar()
        }
    }

    func updateStatusBar() {
        let selInfo = lastUsedView.selectionInfo
        let item = if selInfo.foldersCount == 1,
                      let row = selInfo.foldersIndexes.first,
                      let vi = leftView.item(atRow: row) as? VisibleItem {
            vi.item
        } else {
            leftItemOriginal
        }
        guard let item else {
            return
        }

        let items = DiffCountersItem.diffCounter(
            withItem: item,
            options: sessionDiff.comparatorOptions
        )
        differenceCounters.update(counters: items)
    }

    @objc
    func fontDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let target = userInfo[PrefChangedKey.target] as? PrefChangedKey.Target else {
            return
        }

        if target == .folder {
            fontZoomFactor = 0
        }
    }

    func setProgressHidden(_ hidden: Bool) {
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

    private func restoreSelectionAfterRefresh(
        item: CompareItem,
        anchor: VisibleItem?,
        view: FoldersOutlineView,
        limitToCurrentFolder: Bool
    ) {
        // item still visible after refresh - select it directly
        if let vi = item.visibleItem, view.row(forItem: vi) >= 0 {
            view.select(visibleItems: [vi], scrollToFirst: true, center: true, selectLinked: true)
            return
        }

        // item filtered out - use anchor as starting point for findNearest
        guard let vi = anchor else {
            return
        }

        // try next first, then fall back to previous
        let parentPath = item.parent?.path
        if let found = findNearest(
            view: view,
            item: vi,
            parentPath: parentPath,
            direction: .next,
            limitToCurrentFolder: limitToCurrentFolder
        ),
            let nextVI = view.item(atRow: found.row) as? VisibleItem {
            view.select(visibleItems: [nextVI], scrollToFirst: true, center: true, selectLinked: true)
            return
        }

        if let found = findNearest(
            view: view,
            item: vi,
            parentPath: parentPath,
            direction: .previous,
            limitToCurrentFolder: limitToCurrentFolder
        ),
            let prevVI = view.item(atRow: found.row) as? VisibleItem {
            view.select(visibleItems: [prevVI], scrollToFirst: true, center: true, selectLinked: true)
        }
    }
}
