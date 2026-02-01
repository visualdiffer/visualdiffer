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
    private var finderExtensionBox: FinderExtensionBox
    private let stackView: NSStackView

    private var comparisonDelegate: ComparisonStandardUserDataSource

    override init(frame frameRect: NSRect) {
        comparisonDelegate = ComparisonStandardUserDataSource()

        appearanceBox = AppearanceBox(title: NSLocalizedString("Appearance", comment: ""))

        comparisonBox = FolderComparisonBox(
            title: NSLocalizedString("Comparison and Display Defaults for New Folder Documents", comment: "")
        )
        comparisonBox.delegate = comparisonDelegate

        preferredEditorBox = PreferredEditorBox(title: NSLocalizedString("Preferred Viewer/Editor", comment: ""))

        finderExtensionBox = FinderExtensionBox(title: NSLocalizedString("Finder Integration", comment: ""))
        stackView = NSStackView()

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(appearanceBox)
        stackView.addArrangedSubview(comparisonBox)
        stackView.addArrangedSubview(preferredEditorBox)
        stackView.addArrangedSubview(finderExtensionBox)

        addSubview(stackView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),

            appearanceBox.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            appearanceBox.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            appearanceBox.heightAnchor.constraint(equalToConstant: 60),
            comparisonBox.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            comparisonBox.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            comparisonBox.heightAnchor.constraint(equalToConstant: 160),
            preferredEditorBox.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            preferredEditorBox.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            preferredEditorBox.heightAnchor.constraint(equalToConstant: 80),
            finderExtensionBox.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            finderExtensionBox.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
    }

    func reloadData() {
        appearanceBox.reloadData()
        comparisonBox.reloadData()
    }
}
