//
//  StandardButtons.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Cocoa
import Foundation

@objc
class StandardButtons: NSStackView {
    @objc private(set) var primaryButton: NSButton
    @objc private(set) var secondaryButton: NSButton

    @objc
    init(
        primaryTitle: String,
        secondaryTitle: String,
        target: Any?,
        action: Selector?
    ) {
        secondaryButton = NSButton.cancelButton(
            title: secondaryTitle,
            target: target,
            action: action
        )

        primaryButton = NSButton.okButton(
            title: primaryTitle,
            target: target,
            action: action
        )

        super.init(frame: .zero)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        orientation = .horizontal
        alignment = .centerY
        spacing = 20
        translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(secondaryButton)
        addArrangedSubview(primaryButton)

        primaryButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        secondaryButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
}
