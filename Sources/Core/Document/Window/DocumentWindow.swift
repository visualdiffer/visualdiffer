//
//  DocumentWindow.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DocumentWindow: NSWindow, FileDropImageViewDelegate, HistoryControllerDelegate {
    private var isFoldersDiff = false
    // if true the user changed values from sessionPreferencesSheet
    // so we open the document ignoring the HistoryManager session (if any),
    // otherwise the history session 'overwrite' the chosen user settings
    private var userChosenPreferences = false

    private lazy var sessionPreferencesSheet: SessionPreferencesWindow = {
        let sheet = SessionPreferencesWindow()
        sheet.fillWithUserDefaults()

        return sheet
    }()

    private lazy var historyController: HistoryController = {
        let view = HistoryController()
        view.delegate = self

        return view
    }()

    private lazy var searchHistory: HistorySearchField = {
        let view = HistorySearchField(frame: .zero)
        view.historyController = historyController

        return view
    }()

    private let separator: NSBox = .separator()

    private lazy var compareButton: NSButton = {
        let view = NSButton(
            title: NSLocalizedString("Compare", comment: ""),
            target: self,
            action: #selector(showDiffs)
        )

        view.toolTip = NSLocalizedString("Start Compare ⌘↩︎", comment: "")
        view.keyEquivalent = KeyEquivalent.enter
        view.keyEquivalentModifierMask = .command
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var recentPopup = RecentDocumentPopupMenu(
        title: NSLocalizedString("Open Recent", comment: ""),
        target: self,
        action: #selector(openRecent)
    )

    private lazy var sessionPreferencesButton: NSButton = {
        let view = NSButton(
            title: NSLocalizedString("Session Settings", comment: ""),
            target: self,
            action: #selector(selectSessionPreferences)
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var leftPathChooser = PathChooser(
        userDefault: "leftPaths",
        dropTitle: NSLocalizedString("Left", comment: ""),
        dropDelegate: self,
        chooseTitle: NSLocalizedString("Left...", comment: "")
    )

    private lazy var rightPathChooser = PathChooser(
        userDefault: "rightPaths",
        dropTitle: NSLocalizedString("Right", comment: ""),
        dropDelegate: self,
        chooseTitle: NSLocalizedString("Right...", comment: "")
    )

    init() {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable]

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 330),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        title = NSLocalizedString("Compare Folders or Files", comment: "")
        isReleasedWhenClosed = false
        hasShadow = true
        isRestorable = true
        titlebarSeparatorStyle = .automatic
        setFrameAutosaveName("compareDialog")
        minSize = NSSize(width: 600, height: 330)

        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(leftPathChooser.dropView)
            contentView.addSubview(rightPathChooser.dropView)
            contentView.addSubview(leftPathChooser.chooserView)
            contentView.addSubview(rightPathChooser.chooserView)

            contentView.addSubview(sessionPreferencesButton)
            contentView.addSubview(recentPopup)
            contentView.addSubview(compareButton)
            contentView.addSubview(separator)
            contentView.addSubview(searchHistory)
            contentView.addSubview(historyController.scrollView)
        }

        setupViewsConstraints()
    }

    private func setupViewsConstraints() {
        guard let contentView else {
            return
        }
        let table = historyController.scrollView
        let leftDropView = leftPathChooser.dropView
        let rightDropView = rightPathChooser.dropView

        NSLayoutConstraint.activate([
            leftDropView.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            leftDropView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            leftDropView.widthAnchor.constraint(equalToConstant: 50),
            leftDropView.heightAnchor.constraint(equalToConstant: 50),

            rightDropView.leadingAnchor.constraint(equalTo: leftDropView.trailingAnchor, constant: 8),
            rightDropView.topAnchor.constraint(equalTo: leftDropView.topAnchor),
            rightDropView.widthAnchor.constraint(equalToConstant: 50),
            rightDropView.heightAnchor.constraint(equalToConstant: 50),

            leftPathChooser.chooserView.leadingAnchor.constraint(equalTo: rightDropView.trailingAnchor, constant: 8),
            leftPathChooser.chooserView.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            leftPathChooser.chooserView.topAnchor.constraint(equalTo: leftDropView.topAnchor),

            rightPathChooser.chooserView.leadingAnchor.constraint(equalTo: leftPathChooser.chooserView.leadingAnchor),
            rightPathChooser.chooserView.trailingAnchor.constraint(equalTo: leftPathChooser.chooserView.trailingAnchor),
            rightPathChooser.chooserView.topAnchor.constraint(equalTo: leftPathChooser.chooserView.bottomAnchor, constant: 6),

            sessionPreferencesButton.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            sessionPreferencesButton.topAnchor.constraint(equalTo: leftDropView.bottomAnchor, constant: 12),

            recentPopup.trailingAnchor.constraint(equalTo: compareButton.leadingAnchor, constant: -5),
            recentPopup.topAnchor.constraint(equalTo: sessionPreferencesButton.topAnchor),
            recentPopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 130),

            compareButton.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            compareButton.topAnchor.constraint(equalTo: sessionPreferencesButton.topAnchor),
            compareButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 130),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separator.topAnchor.constraint(equalTo: compareButton.bottomAnchor, constant: 8),

            searchHistory.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            searchHistory.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            searchHistory.topAnchor.constraint(equalTo: separator.topAnchor, constant: 10),

            table.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            table.topAnchor.constraint(equalTo: searchHistory.bottomAnchor, constant: 5),
            table.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    @objc func showDiffs(_: AnyObject?) {
        let leftUrl = URL(filePath: leftPathChooser.currentPath)
        let rightUrl = URL(filePath: rightPathChooser.currentPath)
        var leftExists = false
        var rightExists = false
        let isOk = leftUrl.matchesFileType(
            of: rightUrl,
            isDir: &isFoldersDiff,
            leftExists: &leftExists,
            rightExists: &rightExists
        )

        if isOk {
            let leftPath = leftPathChooser.currentPath
            let rightPath = rightPathChooser.currentPath
            leftPathChooser.addPath(leftPath)
            rightPathChooser.addPath(rightPath)

            if !userChosenPreferences, HistorySessionManager.shared.containsHistory(leftPath: leftPath, rightPath: rightPath) {
                try? HistorySessionManager.shared.openDocument(leftPath: leftPath, rightPath: rightPath)
            } else {
                // Create a new document
                // the history session is updated inside openUntitledDocumentAndDisplay:error
                // Pass `self` to newDocument otherwise the comparison doesn't start
                NSDocumentController.shared.newDocument(self)
            }
        } else {
            var errDesc = NSLocalizedString("Left and Right paths must be both folders or files", comment: "")
            if !leftExists {
                errDesc = NSLocalizedString("Left file no longer exists", comment: "")
            } else if !rightExists {
                errDesc = NSLocalizedString("Right file no longer exists", comment: "")
            }
            let alert = NSAlert()
            alert.messageText = errDesc
            alert.beginSheetModal(for: self)
        }
    }

    @objc func openRecent(_ sender: AnyObject) {
        guard let sender = sender as? NSPopUpButton else {
            return
        }
        let index = sender.indexOfSelectedItem - 1
        if index < 0 {
            return
        }
        guard let url = sender.selectedItem?.representedObject as? URL else {
            let alert = NSAlert()

            alert.messageText = NSLocalizedString("The document could not be opened.", comment: "")
            alert.alertStyle = .critical
            alert.runModal()
            return
        }

        let docController = NSDocumentController.shared
        docController.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error {
                self.presentError(error)
            } else {
                self.orderOut(self)
            }
        }
    }

    // MARK: - FileDropImageViewDelegate delegate methods

    func fileDropImageViewUpdatePath(_ view: FileDropView, paths: [URL]) -> Bool {
        if paths.count < 2 {
            if view === leftPathChooser.dropView {
                leftPathChooser.currentPath = paths[0].path
                SecureBookmark.shared.add(paths[0])
            } else if view === rightPathChooser.dropView {
                rightPathChooser.currentPath = paths[0].path
                SecureBookmark.shared.add(paths[0])
            }
        } else {
            leftPathChooser.currentPath = paths[0].path
            rightPathChooser.currentPath = paths[1].path

            SecureBookmark.shared.add(paths[0])
            SecureBookmark.shared.add(paths[1])
        }
        return true
    }

    // MARK: - History Controller

    func history(controller _: HistoryController, doubleClickedEntity _: HistoryEntity?) {
        showDiffs(nil)
    }

    func history(controller _: HistoryController, selectedEntities entities: [HistoryEntity]) {
        if entities.count == 1,
           let leftPath = entities[0].leftPath,
           let rightPath = entities[0].rightPath {
            leftPathChooser.currentPath = leftPath
            rightPathChooser.currentPath = rightPath
        }
    }

    func history(controller _: HistoryController, droppedPaths paths: [URL]) -> Bool {
        if paths.count == 1 {
            let rightPath = rightPathChooser.currentPath
            let trimmedPath = rightPath.trimmingCharacters(in: CharacterSet.whitespaces)
            if trimmedPath.isEmpty {
                rightPathChooser.currentPath = paths[0].path
            } else {
                leftPathChooser.currentPath = paths[0].path
                rightPathChooser.currentPath = ""
            }
            SecureBookmark.shared.add(paths[0])
        } else if paths.count > 1 {
            leftPathChooser.currentPath = paths[0].path
            rightPathChooser.currentPath = paths[1].path

            SecureBookmark.shared.add(paths[0])
            SecureBookmark.shared.add(paths[1])
        }
        return true
    }

    @objc func find(_: AnyObject) {
        makeFirstResponder(searchHistory)
    }

    @objc func selectSessionPreferences(_: AnyObject) {
        sessionPreferencesSheet.beginSheet(
            self,
            sessionDiff: nil,
            selectedTab: .comparison
        ) {
            self.userChosenPreferences = $0 == .OK
        }
    }

    @objc func fillSessionDiff(_ sessionDiff: SessionDiff) -> Bool {
        // Update all properties handled by preference sheet
        sessionPreferencesSheet.updateSessionDiff(sessionDiff)

        // Update all properties handled by Document Controller
        sessionDiff.leftPath = leftPathChooser.currentPath
        sessionDiff.leftReadOnly = leftPathChooser.isReadOnly

        sessionDiff.rightPath = rightPathChooser.currentPath
        sessionDiff.rightReadOnly = rightPathChooser.isReadOnly

        sessionDiff.itemType = isFoldersDiff ? .folder : .file

        return sessionDiff.leftPath != nil
    }

    func newDocument(_: Any?) {
        userChosenPreferences = false

        leftPathChooser.selectLastUsedPath()
        rightPathChooser.selectLastUsedPath()
        leftPathChooser.isReadOnly = false
        rightPathChooser.isReadOnly = false

        recentPopup.refresh()

        center()
        makeKeyAndOrderFront(self)
    }
}
