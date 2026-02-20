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
    private let stackView: NSStackView

    override init(frame frameRect: NSRect) {
        appearanceBox = AppearanceBox(title: NSLocalizedString("Appearance", comment: ""))
        preferredEditorBox = PreferredEditorBox(title: NSLocalizedString("Preferred Viewer/Editor", comment: ""))

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
        stackView.addArrangedSubview(preferredEditorBox)

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

            preferredEditorBox.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            preferredEditorBox.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            preferredEditorBox.heightAnchor.constraint(equalToConstant: 80),
        ])
    }

    func reloadData() {
        appearanceBox.reloadData()
    }
}
