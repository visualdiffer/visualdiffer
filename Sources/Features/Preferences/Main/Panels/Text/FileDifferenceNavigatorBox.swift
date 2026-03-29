//
//  FileDifferenceNavigatorBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/03/26.
//  Copyright (c) 2026 visualdiffer.com
//

class FileDifferenceNavigatorBox: PreferencesBox {
    private let stackView = NSStackView.preferencesStackView()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        let checkboxes: [(String, CommonPrefs.Name)] = [
            (NSLocalizedString("Wrap around to the next difference", comment: ""), .FileNavigator.wrapsAroundDifferences),
            (NSLocalizedString("Auto-advance to another file comparison", comment: ""), .FileNavigator.autoAdvanceWhenNoMoreDifferences),
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
