//
//  FoldersWindowController+UISetup.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import UserNotifications

extension FoldersWindowController {
    @objc func initAllViews() {
        setupWindowLayout()
        setupFoldersLayout()

        leftPanelView.treeView.nextKeyView = rightView
        lastUsedView = leftPanelView.treeView

        updateTreeViewFont()

        adjustTableColumnsWidth()

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

    @objc func updateTreeViewFont() {
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
    @objc func setupUIState() {
        setupObservers()

        comparatorMethod = sessionDiff.comparatorOptions.onlyMethodFlags
        displayOptionsMethod = sessionDiff.displayOptions.onlyMethodFlags

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

        let displayOptionsObservation = sessionDiff.observeDisplayOptions { flags in
            Task { @MainActor in
                self.displayOptionsMethod = flags.onlyMethodFlags
            }
        }

        observations.append(contentsOf: [comparatorOptionsObservation, displayOptionsObservation])

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

    @objc func updateScopeBar() {
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

    @objc func appAppearanceDidChange(_: Notification) {
        leftView.reloadData()
        rightView.reloadData()

        updateStatusBar()
    }

    @objc func refreshCompareItem(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let leftItemOriginal,
              let rightItemOriginal,
              let sessionLeftPath = sessionDiff.leftPath,
              let sessionRightPath = sessionDiff.rightPath else {
            return
        }

        var item: CompareItem?

        if let leftPath = userInfo[FileSavedKey.leftPath] as? String {
            if leftPath.hasPrefix(sessionLeftPath) {
                item = CompareItem.find(withPath: leftPath, from: leftItemOriginal)
            }
            if item == nil, leftPath.hasPrefix(sessionRightPath) {
                item = CompareItem.find(withPath: leftPath, from: rightItemOriginal)
            }
        }

        if let rightPath = userInfo[FileSavedKey.rightPath] as? String {
            if item == nil, rightPath.hasPrefix(sessionLeftPath) {
                item = CompareItem.find(withPath: rightPath, from: leftItemOriginal)
            }
            if item == nil, rightPath.hasPrefix(sessionRightPath) {
                item = CompareItem.find(withPath: rightPath, from: rightItemOriginal)
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
        item.refresh(
            filterConfig: filterConfig,
            comparator: comparator
        )

        leftView.reloadData()
        rightView.reloadData()
    }

    @objc func updateBottomBar(_ view: FoldersOutlineView) {
        if view.side == .left {
            leftPanelView.updateBottomBar()
        } else {
            rightPanelView.updateBottomBar()
        }
    }

    @objc func updateStatusBar() {
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

    @objc func fontDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let target = userInfo[PrefChangedKey.target] as? PrefChangedKey.Target else {
            return
        }

        if target == .folder {
            fontZoomFactor = 0
        }
    }
}
