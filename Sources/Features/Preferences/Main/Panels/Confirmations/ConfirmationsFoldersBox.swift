//
//  ConfirmationsFoldersBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ConfirmationsFoldersBox: PreferencesBox {
    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let separator = NSBox(frame: .zero)
        separator.boxType = .separator

        let stackView = NSStackView.preferences(with: [
            createCheckBox(
                title: NSLocalizedString("Confirm open a large number of windows in Finder", comment: ""),
                prefName: .confirmShowInFinder
            ),
            createCheckBox(
                title: NSLocalizedString("Confirm stop operation in progress", comment: ""),
                prefName: .confirmStopLongOperation
            ),
            createCheckBox(
                title: NSLocalizedString("Warn about files opened may not be visible in Finder", comment: ""),
                prefName: .confirmShowInFinderNotVisibleFiles
            ),
            separator,
            createCheckBox(
                title: NSLocalizedString("Confirm Copy", comment: ""),
                prefName: .confirmCopy
            ),
            createCheckBox(
                title: NSLocalizedString("Confirm Delete", comment: ""),
                prefName: .confirmDelete
            ),
            createCheckBox(
                title: NSLocalizedString("Confirm Move", comment: ""),
                prefName: .confirmMove
            ),
            createCheckBox(
                title: NSLocalizedString("Include Filtered Items By Default", comment: ""),
                prefName: .confirmIncludeFilteredItems
            ),
            NSTextField.hintWithTitle(NSLocalizedString("Hold down ⌥ key (ALT) to override confirm flag and show dialog", comment: "")),
        ])

        if let contentView {
            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),

                heightAnchor.constraint(equalToConstant: 230),
            ])
        }
    }
}
