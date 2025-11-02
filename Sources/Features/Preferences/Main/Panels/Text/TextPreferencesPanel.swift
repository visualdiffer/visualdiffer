//
//  TextPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class TextPreferencesPanel: NSView, PreferencesPanelDataSource {
    private var visualizationBox: VisualizationBox

    override init(frame frameRect: NSRect) {
        visualizationBox = VisualizationBox(title: NSLocalizedString("Visualization", comment: ""))

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(visualizationBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            visualizationBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            visualizationBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            visualizationBox.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            visualizationBox.heightAnchor.constraint(equalToConstant: 80),
        ])
    }

    func reloadData() {
        visualizationBox.reloadData()
    }
}
