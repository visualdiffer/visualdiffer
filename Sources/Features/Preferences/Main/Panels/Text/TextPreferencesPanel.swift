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
    private var fileDifferenceNavigatorBox = FileDifferenceNavigatorBox(
        title: NSLocalizedString("Difference Navigator", comment: "")
    )

    private let stackView = NSStackView.preferencesStackView()

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
        addSubview(stackView)

        stackView.addArrangedSubview(visualizationBox)
        stackView.addArrangedSubview(fileComparisonBox)
        stackView.addArrangedSubview(fileDifferenceNavigatorBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
        ])

        for view in stackView.views {
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }
    }

    func reloadData() {
        visualizationBox.reloadData()
        fileComparisonBox.reloadData()
        fileDifferenceNavigatorBox.reloadData()
    }
}
