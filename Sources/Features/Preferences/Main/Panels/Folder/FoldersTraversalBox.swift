//
//  FoldersTraversalBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FoldersTraversalBox: PreferencesBox {
    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let stackView = NSStackView.preferences(with: [
            createCheckBox(title: NSLocalizedString("Follow Symbolic Links", comment: ""), prefName: .followSymLinks),
            createCheckBox(title: NSLocalizedString("Skip Packages (Applications, Frameworks, ...)", comment: ""), prefName: .skipPackages),
            createCheckBox(title: NSLocalizedString("Check Resource Forks", comment: ""), prefName: .virtualResourceFork),
            createCheckBox(title: NSLocalizedString("Traverse the folders that match the 'File Filters'", comment: ""), prefName: .traverseFilteredFolders),
        ])

        if let contentView {
            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),

                heightAnchor.constraint(equalToConstant: 120),
            ])
        }
    }
}
