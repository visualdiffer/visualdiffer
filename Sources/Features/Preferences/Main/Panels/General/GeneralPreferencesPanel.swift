//
//  GeneralPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class GeneralPreferencesPanel: NSView, PreferencesPanelDataSource {
    private var appearanceBox: AppearanceBox
    private var preferredEditorBox: PreferredEditorBox
    private var comparisonBox: FolderComparisonBox

    private var comparisonDelegate: ComparisonStandardUserDataSource

    override init(frame frameRect: NSRect) {
        comparisonDelegate = ComparisonStandardUserDataSource()

        appearanceBox = AppearanceBox(title: NSLocalizedString("Appearance", comment: ""))

        comparisonBox = FolderComparisonBox(
            title: NSLocalizedString("Comparison and Display Defaults for New Folder Documents", comment: "")
        )
        comparisonBox.delegate = comparisonDelegate

        preferredEditorBox = PreferredEditorBox(title: NSLocalizedString("Preferred Viewer/Editor", comment: ""))

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(appearanceBox)
        addSubview(comparisonBox)
        addSubview(preferredEditorBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            appearanceBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            appearanceBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            appearanceBox.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            appearanceBox.heightAnchor.constraint(equalToConstant: 60),

            comparisonBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            comparisonBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            comparisonBox.topAnchor.constraint(equalTo: appearanceBox.bottomAnchor, constant: 5),
            comparisonBox.heightAnchor.constraint(equalToConstant: 160),

            preferredEditorBox.topAnchor.constraint(equalTo: comparisonBox.bottomAnchor, constant: 5),
            preferredEditorBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            preferredEditorBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            preferredEditorBox.heightAnchor.constraint(equalToConstant: 80),
        ])
    }

    func reloadData() {
        appearanceBox.reloadData()
        comparisonBox.reloadData()
    }
}
