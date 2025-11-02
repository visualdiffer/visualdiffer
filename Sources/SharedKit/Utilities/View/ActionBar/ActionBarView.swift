//
//  ActionBarView.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

class ActionBarView: NSStackView {
    lazy var firstButton: NSButton = createButton(image: NSImage(named: NSImage.addTemplateName))
    lazy var secondButton: NSButton = createButton(image: NSImage(named: NSImage.removeTemplateName))
    lazy var popup: NSPopUpButton = createMenu()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        translatesAutoresizingMaskIntoConstraints = false
        orientation = .horizontal
        spacing = 1
        alignment = .centerY

        // ensure the height is correctly set
        setHuggingPriority(.required, for: .vertical)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    func setupViews() {
        addArrangedSubview(firstButton)
        addArrangedSubview(secondButton)
        addArrangedSubview(popup)

        setupConstraints()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            firstButton.widthAnchor.constraint(equalToConstant: 24),
            firstButton.heightAnchor.constraint(equalToConstant: 24),

            secondButton.widthAnchor.constraint(equalToConstant: 24),
            secondButton.heightAnchor.constraint(equalToConstant: 24),

            popup.widthAnchor.constraint(equalToConstant: 32),
            popup.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func createButton(image: NSImage?) -> NSButton {
        let view = NSButton(frame: .zero)

        view.bezelStyle = .shadowlessSquare
        view.setButtonType(.momentaryPushIn)
        view.isBordered = true
        view.alignment = .center

        view.image = image
        view.imagePosition = .imageOnly
        view.imageScaling = .scaleProportionallyDown

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createMenu() -> NSPopUpButton {
        let popupMenu = NSMenu()

        // the button title image
        popupMenu
            .addItem(
                withTitle: "",
                action: nil,
                keyEquivalent: ""
            )
            .image = NSImage(named: NSImage.actionTemplateName)

        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.bezelStyle = .shadowlessSquare
        view.setButtonType(.momentaryPushIn)
        view.isBordered = true
        view.alignment = .left
        view.menu = popupMenu

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }
}
