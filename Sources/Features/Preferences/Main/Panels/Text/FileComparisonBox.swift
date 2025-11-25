//
//  FileComparisonBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FileComparisonBox: PreferencesBox {
    private lazy var compareLineEndingsCheckButton: PreferencesCheckbox = {
        let view = PreferencesCheckbox(
            title: NSLocalizedString("Compare Line Endings (DOS/Mac)", comment: ""),
            prefName: .compareLineEndings
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var stackView: NSStackView = .preferences(with: [
        compareLineEndingsCheckButton,
    ])

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        setupCheckBox(compareLineEndingsCheckButton)

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
