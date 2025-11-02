//
//  KeyboardDocumentBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class KeyboardDocumentBox: PreferencesBox {
    private let stackView: NSStackView

    override init(title: String) {
        stackView = NSStackView.preferencesStackView()

        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        stackView.addArrangedSubview(
            createCheckBox(
                title: NSLocalizedString("ESC key closes documents/application", comment: ""),
                prefName: .escCloseWindow
            )
        )
        contentView?.addSubview(stackView)

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),

            heightAnchor.constraint(equalToConstant: 80),
        ])
    }
}
