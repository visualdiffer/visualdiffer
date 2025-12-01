//
//  FilesWindowController+UISetup.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc func initAllViews() {
        setupWindowLayout()

        // must be called after setting up all views
        setupWindow()
        leftPanelView.treeView.nextKeyView = rightView
    }

    func setupWindowLayout() {
        let detailsStackView = createLineDetailsStackWithViews([
            createTopView(fileThumbnail, rightView: filePanels),
            linesDetailView,
        ])

        if let contentView = window?.contentView {
            contentView.addSubview(differenceCounters)
            contentView.addSubview(statusbarText)
            contentView.addSubview(scopeBar)
            contentView.addSubview(detailsStackView)
        }

        setupDetailsStackConstraints(detailsStackView)
        setupConstraints()

        updateUI()

        linesDetailView.isHidden = CommonPrefs.shared.hideFileDiffDetails
    }

    func setupConstraints() {
        guard let contentView = window?.contentView else {
            return
        }
        var leadingMargin: CGFloat = 7
        var trailingMargin: CGFloat = 5
        if #available(macOS 26, *) {
            leadingMargin = 16
            trailingMargin = 16
        }

        NSLayoutConstraint.activate([
            scopeBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scopeBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scopeBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
            scopeBar.heightAnchor.constraint(equalToConstant: 25),

            differenceCounters.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            differenceCounters.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            // fills at least 3/4 of width space
            differenceCounters.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.75),

            statusbarText.leadingAnchor.constraint(equalTo: differenceCounters.trailingAnchor, constant: 5),
            statusbarText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -trailingMargin),
            statusbarText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            statusbarText.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])
    }

    func setupDetailsStackConstraints(_ stackView: NSStackView) {
        guard let contentView = window?.contentView else {
            return
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scopeBar.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: differenceCounters.topAnchor, constant: -2),

            fileThumbnail.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            fileThumbnail.widthAnchor.constraint(equalToConstant: 15),

            // linesDetailView has a fixed height
            linesDetailView.heightAnchor.constraint(equalToConstant: 46),
        ])
    }

    func setupWindow() {
        guard let window else {
            return
        }
        window.delegate = self
        window.toolbar = NSToolbar(identifier: "FilesToolbar", delegate: self)
        window.makeFirstResponder(leftPanelView.treeView)

        window.collectionBehavior = [window.collectionBehavior, .fullScreenPrimary]
    }

    @objc func updateUI() {
        updateTreeViewFont()

        // invalidate the line text cache
        cachedLineTextMap.removeAllObjects()

        reloadRowHeights()

        updateTabWidth()

        updateDetailLines(leftView.selectedRow)

        updateStatusbarText()
    }

    func updateStatusbarText() {
        var arr = [String]()

        arr.append(String(format: NSLocalizedString("Tab Width: %ld", comment: ""), CommonPrefs.shared.tabWidth))

        if fontZoomFactor > 0 {
            arr.append("\(100 + Int(fontZoomFactor) * 10)%")
        }
        statusbarText.stringValue = arr.joined(separator: ", ")
    }

    func updateTabWidth() {
        let tabWidth = CommonPrefs.shared.tabWidth
        leftDetailsTextView.setTabStop(tabWidth)
        rightDetailsTextView.setTabStop(tabWidth)

        visibleWhitespaces.tabWidth = tabWidth
    }

    func updateTreeViewFont() {
        let font = treeViewFont()

        leftView.updateFont(font, reloadData: false)
        rightView.updateFont(font, reloadData: false)
        leftDetailsTextView.font = font
        rightDetailsTextView.font = font
    }

    func treeViewFont() -> NSFont {
        currentFont = CommonPrefs.shared.fileTextFont

        if fontZoomFactor > 0 {
            currentFont = NSFontManager.shared.convert(
                currentFont,
                toSize: currentFont.pointSize + fontZoomFactor
            )
        }

        return currentFont
    }

    /**
     * Setup elements requiring the sessionDiff is correctly defined, this method must be called after setDocument
     */
    func setupUIState() {
        setupObservers()

        window?.setFrameAutosaveName(String(format: "%lx%lx", sessionDiff.leftPath?.hash ?? 0, sessionDiff.rightPath?.hash ?? 0))

        scopeBar.findView.delegate = FilesTableViewFindTextDelegate(view: leftView)
        updateScopeBar()

        leftPanelView.bindControls()
        rightPanelView.bindControls()
    }

    func updateScopeBar() {
        scopeBar.showWhitespaces(scopeBar.showWhitespaces, informDelegate: false)
        scopeBar.showLineFilter(scopeBar.showLinesFilter, informDelegate: false)
    }

    func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fontDidChange),
            name: .prefsChanged,
            object: nil
        )

        // a register for those notifications on the synchronized content view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(synchronizedViewContentBoundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: leftPanelView.scrollView.contentView
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appAppearanceDidChange),
            name: .appAppearanceDidChange,
            object: nil
        )
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: .prefsChanged,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSView.boundsDidChangeNotification,
            object: leftPanelView.scrollView.contentView()
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .appAppearanceDidChange,
            object: nil
        )
    }

    @objc private func fontDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let target = userInfo[PrefChangedKey.target] as? PrefChangedKey.Target else {
            return
        }

        if target == .file {
            fontZoomFactor = 0
        }
    }

    @objc func appAppearanceDidChange(_: Notification) {
        leftView.reloadData()
        rightView.reloadData()

        if let diffResult {
            differenceCounters.update(counters: DiffCountersItem.diffCounter(withResult: diffResult))
        } else {
            fatalError("diffResult is nil, why???")
        }
    }

    // MARK: - File and view scroll

    @objc func synchronizedViewContentBoundsDidChange(_: Notification) {
        fileThumbnail.needsDisplay = true
    }
}
