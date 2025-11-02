//
//  ConfirmationsDocumentsBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ConfirmationsDocumentsBox: PreferencesBox {
    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let stackView = NSStackView.preferences(with: [
            createCheckBox(
                title: NSLocalizedString("Don't ask to save document with changes when close", comment: ""),
                prefName: .confirmDontAskToSaveSession
            ),
            NSTextField.hintWithTitle(NSLocalizedString("Be careful, any changes will be lost (filters, aligment rules, ...)", comment: "")),
        ])

        if let contentView {
            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),

                heightAnchor.constraint(equalToConstant: 80),
            ])
        }
    }
}
