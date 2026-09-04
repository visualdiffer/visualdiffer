//
//  PreferencesPanelDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

protocol PreferencesPanelDataSource {
    @MainActor
    func reloadData()
}

extension PreferencesPanelDataSource where Self: NSView {
    // defaultHigh because NSTabView lays the panel out at 20 points while it is still detached,
    // there the content cannot fit and a required constraint would break the box heights
    @MainActor
    func panelBottomConstraint(_ view: NSView, constant: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = view.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: constant)
        constraint.priority = .defaultHigh

        return constraint
    }
}
