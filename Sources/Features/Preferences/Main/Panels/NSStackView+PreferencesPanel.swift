//
//  NSStackView+PreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSStackView {
    func setupPreferences() {
        orientation = .vertical
        alignment = .leading
        spacing = 8
        edgeInsets = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false
    }

    static func preferencesStackView() -> NSStackView {
        let view = NSStackView(frame: .zero)

        view.setupPreferences()

        return view
    }

    static func preferences(with views: [NSView]) -> NSStackView {
        let view = NSStackView(views: views)

        view.setupPreferences()

        return view
    }

    func addArrangedSubviews(_ views: [NSView]) {
        for view in views {
            addArrangedSubview(view)
        }
    }
}
