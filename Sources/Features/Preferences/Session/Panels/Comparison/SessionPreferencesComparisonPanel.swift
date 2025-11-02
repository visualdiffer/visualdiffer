//
//  SessionPreferencesComparisonPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class SessionPreferencesComparisonPanel: NSView, PreferencesPanelDataSource {
    var delegate: PreferencesBoxDataSource? {
        didSet {
            for view in stackView.views {
                if let delegate,
                   let box = view as? PreferencesBox {
                    box.delegate = delegate
                }
            }
        }
    }

    let stackView: NSStackView

    override init(frame frameRect: NSRect) {
        stackView = NSStackView.preferences(with: [
            FolderComparisonBox(title: NSLocalizedString("Comparison", comment: "")),
            FoldersTraversalBox(title: "Folders Traversal"),
            FolderViewBox(title: NSLocalizedString("View", comment: "")),
        ])

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            heightAnchor.constraint(equalToConstant: 360),
        ])

        for view in stackView.views {
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }
    }

    func reloadData() {
        for view in stackView.views {
            if let box = view as? PreferencesBox {
                box.reloadData()
            }
        }
    }
}
