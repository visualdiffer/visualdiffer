//
//  FoldersWindowController+UISetup.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController {
    func initAllViews() {
        setupWindowLayout()
        setupFoldersLayout()

        leftPanelView.treeView.nextKeyView = rightView

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
}
