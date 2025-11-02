//
//  TouchController.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/03/12.
//  Copyright (c) 2012 visualdiffer.com
//

class TouchController: FileSystemController<TouchFileOperationExecutor> {
    enum TouchDateFromSource: Int {
        case otherSide
        case userSelection
    }

    private let dateFromOtherSideButton: NSButton
    private let dateFromUserSelection: NSButton

    private let applyToAllFolderContentsButton: NSButton

    private let pickers: TouchPickersStackView

    /**
     * return nil when TouchDateFromSourceOtherSide is selected otherwise the Date
     */
    var buildTouchDate: Date? {
        if dateFromOtherSideButton.state == .on {
            return nil
        }
        return pickers.touchDate
    }

    override init(
        executor: TouchFileOperationExecutor,
        fileOperationManager: FileOperationManager,
        view: FoldersOutlineView,
        progressIndicatorController: ProgressIndicatorController,
        filteredFileVisible: Bool
    ) {
        dateFromOtherSideButton = NSButton(
            radioButtonWithTitle: NSLocalizedString("Copy Date from the other side", comment: ""),
            target: nil,
            action: nil
        )

        dateFromUserSelection = NSButton(
            radioButtonWithTitle: NSLocalizedString("Set Date to", comment: ""),
            target: nil,
            action: nil
        )

        applyToAllFolderContentsButton = NSButton(
            checkboxWithTitle: NSLocalizedString("Apply to all folder contents", comment: ""),
            target: nil,
            action: nil
        )

        pickers = TouchPickersStackView()

        super.init(
            executor: executor,
            fileOperationManager: fileOperationManager,
            view: view,
            progressIndicatorController: progressIndicatorController,
            filteredFileVisible: filteredFileVisible
        )

        setupViews()
    }

    override func createWindow() -> NSWindow {
        let window = super.createWindow()

        window.setContentSize(NSSize(width: 450, height: 480))
        window.minSize = NSSize(width: 450, height: 480)
        window.maxSize = NSSize(width: 450, height: 480)

        return window
    }

    override func setupViews() {
        super.setupViews()

        dateFromOtherSideButton.target = self
        dateFromOtherSideButton.action = #selector(radioButton)
        dateFromOtherSideButton.translatesAutoresizingMaskIntoConstraints = false
        dateFromOtherSideButton.tag = TouchDateFromSource.otherSide.rawValue

        dateFromUserSelection.target = self
        dateFromUserSelection.action = #selector(radioButton)
        dateFromUserSelection.translatesAutoresizingMaskIntoConstraints = false
        dateFromUserSelection.tag = TouchDateFromSource.userSelection.rawValue
        dateFromUserSelection.state = .on

        fileSummary.sizeTotalText.isHidden = true
        applyToAllFolderContentsButton.isHidden = fileCount.folders == 0 && fileFilteredCount.folders == 0

        pickers.touchDate = Date()
    }

    override func setupMainStackView() {
        mainStackView.addArrangedSubviews([
            operationSummary,
            createSeparator(),
            dateFromOtherSideButton,
            dateFromUserSelection,
            pickers,
            applyToAllFolderContentsButton,
            filtersWarningText,
        ])

        mainStackView.orientation = .vertical
        mainStackView.alignment = .leading
        mainStackView.spacing = 10
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pickers.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            pickers.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
        ])
    }

    func createSeparator() -> NSBox {
        let view = NSBox(frame: .zero)

        view.title = ""
        view.boxType = .separator
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    override func prepareExecute() {
        guard let callerWindow else {
            fatalError("Caller window is nil")
        }

        progressIndicatorController?.beginSheetModal(
            for: callerWindow,
            processingItemsCount: totalFiles + totalFolders,
            totalSize: 0,
            singleItem: false
        )

        fileOperationManager.includesFiltered = fileSummary.checkboxFilteredFiles.state == .on
        executor.touchDate = buildTouchDate
        executor.includeSubfolders = applyToAllFolderContentsButton.state == .on

        progressIndicatorController?.startRun()
    }

    // MARK: - Action Methods

    @objc func radioButton(_ sender: AnyObject) {
        guard let sender = sender as? NSButton,
              let source = TouchDateFromSource(rawValue: sender.tag) else {
            return
        }
        pickers.isEnabled = switch source {
        case .otherSide:
            false
        case .userSelection:
            true
        }
    }
}
