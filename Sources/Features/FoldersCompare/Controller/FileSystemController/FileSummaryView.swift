//
//  FileSummaryView.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

@objc class FileSummaryView: NSStackView {
    @objc let folderTotalText: NSTextField
    @objc let fileTotalText: NSTextField
    @objc let sizeTotalText: NSTextField
    @objc let operationDescription: NSTextField
    @objc let filteredFilesInSelectionText: NSTextField
    @objc let checkboxFilteredFiles: NSButton

    init() {
        operationDescription = NSTextField.labelWithTitle("")
        operationDescription.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        folderTotalText = NSTextField.hintWithTitle("")
        fileTotalText = NSTextField.hintWithTitle("")
        sizeTotalText = NSTextField.hintWithTitle("")

        checkboxFilteredFiles = NSButton(
            checkboxWithTitle: NSLocalizedString("Include Filtered Files", comment: ""),
            target: nil,
            action: nil
        )
        checkboxFilteredFiles.translatesAutoresizingMaskIntoConstraints = false

        filteredFilesInSelectionText = NSTextField.hintWithTitle(
            NSLocalizedString("Selection already contains Filtered Files", comment: "")
        )
        filteredFilesInSelectionText.controlSize = .mini
        filteredFilesInSelectionText.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .mini))

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
        addArrangedSubview(filteredFilesInSelectionText)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            filteredFilesInSelectionText.leadingAnchor.constraint(equalTo: checkboxFilteredFiles.leadingAnchor, constant: 20),
            filteredFilesInSelectionText.topAnchor.constraint(equalTo: checkboxFilteredFiles.bottomAnchor, constant: 4),
        ])
    }

    @objc func setupCheckboxFilteredFiles(
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
}
