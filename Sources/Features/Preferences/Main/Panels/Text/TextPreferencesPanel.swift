//
//  TextPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class TextPreferencesPanel: NSView, PreferencesPanelDataSource {
    private var visualizationBox = VisualizationBox(
        title: NSLocalizedString("Visualization", comment: "")
    )
    private var fileComparisonBox = FileComparisonBox(
        title: NSLocalizedString("Comparison for New File Documents", comment: "")
    )

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        fileComparisonBox.delegate = self
        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(visualizationBox)
        addSubview(fileComparisonBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            visualizationBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            visualizationBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            visualizationBox.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            visualizationBox.heightAnchor.constraint(equalToConstant: 80),

            fileComparisonBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            fileComparisonBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            fileComparisonBox.topAnchor.constraint(equalTo: visualizationBox.bottomAnchor, constant: 5),
            fileComparisonBox.heightAnchor.constraint(equalToConstant: 80),
        ])
    }

    func reloadData() {
        visualizationBox.reloadData()
        fileComparisonBox.reloadData()
    }
}
