//
//  FileSummaryView.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FileSummaryView: NSStackView {
    lazy var folderTotalText = createFolderTotalText()
    lazy var fileTotalText = createFileTotalText()
    lazy var sizeTotalText = createSizeTotalText()
    lazy var operationDescription = createOperationDescription()
    lazy var filteredFilesInSelectionText = createFilteredFilesInSelectionText()
    lazy var checkboxFilteredFiles = createCheckboxFilteredFiles()
    lazy var checkboxCopyMetadataOnly = createCheckboxCopyMetadataOnly()
    lazy var copyFinderMetadataHelpText = createCopyFinderMetadataHelpText()

    init() {
        super.init(frame: .zero)

        orientation = .vertical
        alignment = .leading
        spacing = 10
        translatesAutoresizingMaskIntoConstraints = false

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addArrangedSubview(operationDescription)
        addArrangedSubview(folderTotalText)
        addArrangedSubview(fileTotalText)
        addArrangedSubview(sizeTotalText)
        addArrangedSubview(checkboxFilteredFiles)
        addArrangedSubview(checkboxCopyMetadataOnly)
        addArrangedSubview(copyFinderMetadataHelpText)
        addArrangedSubview(filteredFilesInSelectionText)

        setCustomSpacing(4, after: checkboxFilteredFiles)
        setCustomSpacing(4, after: checkboxCopyMetadataOnly)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            filteredFilesInSelectionText.leadingAnchor.constraint(equalTo: checkboxFilteredFiles.leadingAnchor, constant: 20),
            copyFinderMetadataHelpText.leadingAnchor.constraint(equalTo: checkboxCopyMetadataOnly.leadingAnchor, constant: 20),
        ])
    }

    func setupCheckboxFilteredFiles(
        _ includesFilteredFiles: Bool,
        hasFilteredInSelection: Bool
    ) {
        if includesFilteredFiles {
            checkboxFilteredFiles.isHidden = false
            checkboxFilteredFiles.state = .on
            checkboxFilteredFiles.isEnabled = !hasFilteredInSelection
        } else {
            checkboxFilteredFiles.isHidden = true
            checkboxFilteredFiles.state = .off
            checkboxFilteredFiles.isEnabled = false
        }
    }

    private func createFolderTotalText() -> NSTextField {
        NSTextField.hintWithTitle("")
    }

    private func createFileTotalText() -> NSTextField {
        NSTextField.hintWithTitle("")
    }

    private func createSizeTotalText() -> NSTextField {
        NSTextField.hintWithTitle("")
    }

    private func createOperationDescription() -> NSTextField {
        let view = NSTextField.labelWithTitle("")
        view.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        return view
    }

    private func createFilteredFilesInSelectionText() -> NSTextField {
        let view = NSTextField.hintWithTitle(
            NSLocalizedString("Selection already contains Filtered Files", comment: "")
        )
        view.controlSize = .mini
        view.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .mini))

        return view
    }

    private func createCheckboxFilteredFiles() -> NSButton {
        let view = NSButton(
            checkboxWithTitle: NSLocalizedString("Include Filtered Files", comment: ""),
            target: nil,
            action: nil
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createCheckboxCopyMetadataOnly() -> NSButton {
        let view = NSButton(
            checkboxWithTitle: NSLocalizedString("Copy Finder metadata", comment: ""),
            target: nil,
            action: nil
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }

    private func createCopyFinderMetadataHelpText() -> NSTextField {
        let view = NSTextField.hintWithTitle(
            NSLocalizedString("Copies Finder metadata (tags, labels), not file contents", comment: "")
        )
        view.controlSize = .mini
        view.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .mini))
        view.isHidden = true

        return view
    }
}
