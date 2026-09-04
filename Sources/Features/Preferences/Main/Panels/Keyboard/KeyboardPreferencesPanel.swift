//
//  KeyboardPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class KeyboardPreferencesPanel: NSView, PreferencesPanelDataSource {
    private var documentBox: KeyboardDocumentBox

    override init(frame frameRect: NSRect) {
        documentBox = KeyboardDocumentBox(title: NSLocalizedString("Document", comment: ""))

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    private func setupViews() {
        addSubview(documentBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            documentBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            documentBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            documentBox.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            panelBottomConstraint(documentBox, constant: -5),
        ])
    }

    func reloadData() {
        documentBox.reloadData()
    }
}
