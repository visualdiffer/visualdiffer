//
//  FolderPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FolderPreferencesPanel: NSView, PreferencesPanelDataSource {
    private var comparisonDelegate: ComparisonStandardUserDataSource

    override init(frame frameRect: NSRect) {
        comparisonDelegate = ComparisonStandardUserDataSource()

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    private func setupViews() {
        let views = [
            FolderComparisonBox(title: NSLocalizedString("Comparison and Display Defaults for New Folder Documents", comment: "")),
            FoldersTraversalBox(title: NSLocalizedString("Folder Traversal", comment: "")),
            FolderViewBox(title: NSLocalizedString("View", comment: "")),
            DifferenceNavigatorBox(title: NSLocalizedString("Difference Navigator", comment: "")),
        ]

        let stackView = NSStackView.preferences(with: views)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            panelBottomConstraint(stackView),
        ])

        for view in views {
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
            view.delegate = comparisonDelegate
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
