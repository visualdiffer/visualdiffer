//
//  ConfirmationsFilesBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ConfirmationsFilesBox: PreferencesBox {
    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let stackView = NSStackView.preferences(with: [
            createCheckBox(
                title: NSLocalizedString("Confirm reloading files changed on the file system by another application", comment: ""),
                prefName: .confirmReloadFiles,
                isNegated: true
            ),
        ])

        if let contentView {
            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),

                heightAnchor.constraint(equalToConstant: 60),
            ])
        }
    }
}
