//
//  FileSystemController.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

public protocol FileSystemControllerDelegate: AnyObject {
    func fileSystem(
        _ fileSystem: FileSystemController<some FileOperationExecutor>,
        restoreSelection selectedVisibleItems: [VisibleItem],
        errors: [any Error]?
    )
}

public class FileSystemController<TExecutor: FileOperationExecutor>: NSWindowController {
    private var includesFilteredFiles = false
    private var hasFilteredInSelection = false

    var mainStackView: NSStackView

    private(set) var operationSummary: OperationSummaryView
    private(set) var fileSummary: FileSummaryView

    private(set) var filtersWarningText: NSTextField

    private let checkboxSuppressDialog: NSButton

    private(set) var standardButtons: StandardButtons

    var fileCount = CompareSummary()
    var fileFilteredCount = CompareSummary()

    var totalFiles = 0
    var totalFolders = 0
    var totalSize = Int64(0)

    let executor: TExecutor

    var selectedVisibleItems: [VisibleItem]
    var callerWindow: NSWindow?
    var delegate: FileSystemControllerDelegate?

    var progressIndicatorController: ProgressIndicatorController?
    var fileOperationManager: FileOperationManager

    init(
        executor: TExecutor,
        fileOperationManager: FileOperationManager,
        view: FoldersOutlineView,
        progressIndicatorController: ProgressIndicatorController,
        filteredFileVisible: Bool
    ) {
        filtersWarningText = NSTextField.labelWithTitle(NSLocalizedString(
            "Filtered files will be skipped.\nTo include them select 'Show Filtered Files' from View menu", comment: ""
        ))

        standardButtons = StandardButtons(
            primaryTitle: NSLocalizedString("OK", comment: ""),
            secondaryTitle: NSLocalizedString("Cancel", comment: ""),
            target: nil,
            action: nil
        )

        checkboxSuppressDialog = NSButton(
            checkboxWithTitle: NSLocalizedString("Do not show this message again", comment: ""),
            target: nil,
            action: nil
        )
        operationSummary = OperationSummaryView()
        fileSummary = FileSummaryView()
        mainStackView = NSStackView(frame: .zero)

        self.executor = executor
        self.fileOperationManager = fileOperationManager
        self.progressIndicatorController = progressIndicatorController
        self.progressIndicatorController?.operationDescription = executor.progressLabel

        selectedVisibleItems = view.getSelectedVisibleItems(false)

        super.init(window: nil)

        hasFilteredInSelection = computeCountsForItems(view.selectedItems())

        var showFiltered = filteredFileVisible
        if hasFilteredInSelection {
            showFiltered = true
        }
        includesFilteredFiles = showFiltered || CommonPrefs.shared.bool(forKey: .confirmIncludeFilteredItems)
        window = createWindow()
        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func computeCountsForItems(_ items: [CompareItem]) -> Bool {
        var foundFilteredRoot = false

        for item in items {
            item.computeCounts(&fileCount, filteredSummary: &fileFilteredCount)
            if item.isFiltered {
                foundFilteredRoot = true
            }
        }

        return foundFilteredRoot
    }

    func createWindow() -> NSWindow {
        let styleMask: NSWindow.StyleMask = [.titled, .closable]

        let view = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        view.hasShadow = true
        view.isRestorable = true
        view.minSize = NSSize(width: 480, height: 300)
        view.maxSize = NSSize(width: 480, height: 300)

        return view
    }

    // MARK: - Setup Views

    func setupViews() {
        setupMainStackView()
        setupStandardButtons()
        setupOperationSummaryView()
        setupCheckboxSuppressDialog()
        setupFiltersWarningText()

        if let contentView = window?.contentView {
            contentView.addSubview(mainStackView)
            contentView.addSubview(standardButtons)
        }

        setupConstraints()

        setupTitle()
        fileSummary.setupCheckboxFilteredFiles(includesFilteredFiles, hasFilteredInSelection: hasFilteredInSelection)
        updateCount(nil)
    }

    func setupMainStackView() {
        mainStackView.addArrangedSubviews([
            operationSummary,
            filtersWarningText,
            checkboxSuppressDialog,
        ])

        mainStackView.orientation = .vertical
        mainStackView.alignment = .leading
        mainStackView.spacing = 10
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupStandardButtons() {
        standardButtons.primaryButton.target = self
        standardButtons.primaryButton.action = #selector(closeSheet)
        standardButtons.secondaryButton.target = self
        standardButtons.secondaryButton.action = #selector(closeSheet)
    }

    func setupOperationSummaryView() {
        fileSummary.checkboxFilteredFiles.target = self
        fileSummary.checkboxFilteredFiles.action = #selector(updateCount)
        fileSummary.filteredFilesInSelectionText.isHidden = !hasFilteredInSelection

        if let copyFinderMetadataOnly = fileOperationManager.copyFinderMetadataOnly {
            fileSummary.checkboxCopyMetadataOnly.target = self
            fileSummary.checkboxCopyMetadataOnly.action = #selector(updateCopyMetadata)
            fileSummary.checkboxCopyMetadataOnly.isHidden = false
            fileSummary.checkboxCopyMetadataOnly.state = copyFinderMetadataOnly ? .on : .off

            fileSummary.copyFinderMetadataHelpText.isHidden = false
        } else {
            fileSummary.checkboxCopyMetadataOnly.isHidden = true
            fileSummary.copyFinderMetadataHelpText.isHidden = true
        }

        operationSummary.addArrangedSubview(fileSummary)
    }

    func setupCheckboxSuppressDialog() {
        checkboxSuppressDialog.target = self
        checkboxSuppressDialog.action = #selector(updateSuppressWarning)
        checkboxSuppressDialog.translatesAutoresizingMaskIntoConstraints = false
        // the value is negated
        checkboxSuppressDialog.state = if let prefName = executor.prefName {
            CommonPrefs.shared.bool(forKey: prefName) ? .off : .on
        } else {
            .off
        }
    }

    func setupFiltersWarningText() {
        filtersWarningText.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        filtersWarningText.isHidden = includesFilteredFiles
    }

    func setupConstraints() {
        guard let contentView = window?.contentView else {
            return
        }
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            standardButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    // MARK: - Sheet methods

    func beginSheetModal(for callerWindow: NSWindow) {
        guard let window else {
            return
        }
        if itemsCount() == 0 {
            return
        }
        self.callerWindow = callerWindow

        if !willShowConfirmDialog() {
            execute()
            return
        }

        callerWindow.beginSheet(window) {
            self.sheetEnd($0)
        }
    }

    @objc
    func closeSheet(_ sender: AnyObject) {
        guard let sender = sender as? NSButton,
              let window,
              let sheetParent = window.sheetParent else {
            return
        }
        let tag = NSApplication.ModalResponse(sender.tag)
        sheetParent.endSheet(window, returnCode: tag)
    }

    @objc
    func updateCount(_: AnyObject?) {
        includesFilteredFiles = fileSummary.checkboxFilteredFiles.state == .on
        recalcTotals(includesFilteredFiles)

        fileSummary.fileTotalText.stringValue = String.localizedStringWithFormat(NSLocalizedString("%ld files", comment: ""), totalFiles)
        fileSummary.folderTotalText.stringValue = String.localizedStringWithFormat(NSLocalizedString("%ld folders", comment: ""), totalFolders)
        fileSummary.sizeTotalText.stringValue = FileSizeFormatter.default.string(from: NSNumber(value: totalSize)) ?? "0"
    }

    @objc
    func updateSuppressWarning(_: AnyObject) {
        guard let prefName = executor.prefName else {
            return
        }
        let isSuppressed = checkboxSuppressDialog.state == .off

        CommonPrefs.shared.set(isSuppressed, forKey: prefName)
    }

    @objc
    func updateCopyMetadata(_: AnyObject?) {
        let status = fileSummary.checkboxCopyMetadataOnly.state == .on
        fileOperationManager.copyFinderMetadataOnly = status
    }

    private func recalcTotals(_ includesFiltered: Bool) {
        totalFiles = fileCount.olderFiles + fileCount.changedFiles + fileCount.orphanFiles + fileCount.matchedFiles
        totalFolders = fileCount.folders
        totalSize = fileCount.subfoldersSize

        if includesFiltered {
            totalFiles += fileFilteredCount.olderFiles
                + fileFilteredCount.changedFiles
                + fileFilteredCount.orphanFiles
                + fileFilteredCount.matchedFiles
            totalFolders += fileFilteredCount.folders
            totalSize += fileFilteredCount.subfoldersSize
        }
    }

    func updateUIAfterExecute() {
        progressIndicatorController?.endSheetAfterCompletion()
        delegate?.fileSystem(
            self,
            restoreSelection: selectedVisibleItems,
            errors: progressIndicatorController?.errors
        )
    }

    func prepareExecute() {
        guard let callerWindow else {
            fatalError("Caller window is nil")
        }

        recalcTotals(includesFilteredFiles)

        if let copyFinderMetadataOnly = fileOperationManager.copyFinderMetadataOnly,
           copyFinderMetadataOnly {
            progressIndicatorController?.isSizeLeftHidden = copyFinderMetadataOnly
        }
        progressIndicatorController?.beginSheetModal(
            for: callerWindow,
            processingItemsCount: totalFiles,
            totalSize: totalSize,
            singleItem: executor.operationOnSingleItem
        )

        fileOperationManager.includesFiltered = includesFilteredFiles

        progressIndicatorController?.startRun()
    }

    func execute() {
        prepareExecute()

        let capturedManager = fileOperationManager
        DispatchQueue.global(qos: .userInitiated).async {
            self.executor.execute(capturedManager, payload: nil)

            DispatchQueue.main.async {
                self.updateUIAfterExecute()
            }
        }
    }

    func sheetEnd(_ returnCode: NSApplication.ModalResponse) {
        if returnCode == .cancel {
            return
        }
        execute()
    }

    // MARK: - Confirmation handling methods

    func willShowConfirmDialog() -> Bool {
        let isOptionPressed = NSApp.currentEvent?.modifierFlags.contains(.option) ?? false
        if isOptionPressed {
            return true
        }

        if let prefName = executor.prefName {
            return CommonPrefs.shared.bool(forKey: prefName)
        }
        return true
    }

    // MARK: - Helper Methods

    func setupTitle() {
        fileSummary.operationDescription.stringValue = executor.summary
        standardButtons.primaryButton.title = executor.title
        operationSummary.icon.image = executor.image
    }

    func itemsCount() -> Int {
        var count = fileCount.olderFiles + fileCount.changedFiles + fileCount.orphanFiles + fileCount.matchedFiles
        count += fileCount.folders
        count += fileFilteredCount.olderFiles
            + fileFilteredCount.changedFiles
            + fileFilteredCount.orphanFiles
            + fileFilteredCount.matchedFiles
        count += fileFilteredCount.folders

        return count
    }
}
