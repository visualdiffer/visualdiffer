//
//  FolderViewBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FolderViewBox: PreferencesBox {
    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let stackView = NSStackView.preferences(with: [
            createCheckBox(
                title: NSLocalizedString("Expand All Folders After Session Load", comment: ""),
                prefName: .expandAllFolders
            ),
        ])

        if let contentView {
            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
                // setting bottomAnchor isn't necessary to explicitly setting heightAnchor
                stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
    }
}
