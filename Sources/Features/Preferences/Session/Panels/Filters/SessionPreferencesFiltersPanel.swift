//
//  SessionPreferencesFiltersPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class SessionPreferencesFiltersPanel: NSView, PreferencesPanelDataSource {
    var delegate: PreferencesBoxDataSource? {
        didSet {
            filterBox.delegate = delegate
        }
    }

    private let filterBox: SessionPreferencesFiltersBox

    override init(frame frameRect: NSRect) {
        filterBox = SessionPreferencesFiltersBox(
            title: NSLocalizedString("Do not show files matching the criteria below", comment: "")
        )

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        super.addSubview(filterBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            filterBox.leadingAnchor.constraint(equalTo: leadingAnchor),
            filterBox.trailingAnchor.constraint(equalTo: trailingAnchor),
            filterBox.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            filterBox.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }

    func reloadData() {
        filterBox.reloadData()
    }

    @objc func updatePendingData() {
        filterBox.updatePendingData()
    }
}
