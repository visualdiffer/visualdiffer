//
//  FileComparisonBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FileComparisonBox: PreferencesBox {
    private let stackView: NSStackView

    override init(title: String) {
        stackView = NSStackView.preferencesStackView()

        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let checkboxes: [(String, CommonPrefs.Name)] = [
            (NSLocalizedString("Ignore Line Endings (DOS/Mac)", comment: ""), .ignoreLineEndings),
            (NSLocalizedString("Ignore Leading Whitespace", comment: ""), .ignoreLeadingWhitespaces),
            (NSLocalizedString("Ignore Trailing Whitespace", comment: ""), .ignoreTrailingWhitespaces),
            (NSLocalizedString("Ignore Internal Whitespace", comment: ""), .ignoreInternalWhitespaces),
            (NSLocalizedString("Ignore Character Case", comment: ""), .ignoreCharacterCase),
        ]

        for (title, prefName) in checkboxes {
            let view = PreferencesCheckbox(title: title, prefName: prefName)
            view.translatesAutoresizingMaskIntoConstraints = false

            setupCheckBox(view)

            stackView.addArrangedSubview(view)
        }

        contentView?.addSubview(stackView)

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // setting bottomAnchor isn't necessary to explicitly setting heightAnchor
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        for view in stackView.views {
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }
    }
}
