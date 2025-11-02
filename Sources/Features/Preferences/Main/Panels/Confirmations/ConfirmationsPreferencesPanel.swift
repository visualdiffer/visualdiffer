//
//  ConfirmationsPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ConfirmationsPreferencesPanel: NSView, PreferencesPanelDataSource {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let views = [
            ConfirmationsFoldersBox(title: NSLocalizedString("Confirmation and Warning Messages for Folders", comment: "")),
            ConfirmationsFilesBox(title: NSLocalizedString("Confirmation and Warning Messages for Files", comment: "")),
            ConfirmationsDocumentsBox(title: NSLocalizedString("Confirmation for Documents", comment: "")),
        ]

        let stackView = NSStackView.preferences(with: views)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor),
        ])

        for view in views {
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }
    }

    func reloadData() {
        guard let stackView = subviews[0] as? NSStackView else {
            return
        }

        for view in stackView.views {
            if let box = view as? PreferencesBox {
                box.reloadData()
            }
        }
    }
}
