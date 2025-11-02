//
//  ConsoleToolbarView.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ConsoleToolbarView: NSView {
    @objc let clearButton: NSButton
    @objc let hideButton: NSButton

    override init(frame frameRect: NSRect) {
        clearButton = NSButton(frame: .zero)
        hideButton = NSButton(frame: .zero)

        super.init(frame: frameRect)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    private func setupViews() {
        setup(button: clearButton, title: NSLocalizedString("Clear", comment: ""))
        setup(button: hideButton, title: NSLocalizedString("Hide", comment: ""))

        addSubview(clearButton)
        addSubview(hideButton)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            clearButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            clearButton.trailingAnchor.constraint(equalTo: hideButton.leadingAnchor, constant: -6),

            hideButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            hideButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }

    private func setup(button: NSButton, title: String) {
        button.bezelStyle = .roundRect
        button.setButtonType(.momentaryPushIn)
        button.isBordered = true
        button.state = .on
        button.title = title
        button.alignment = .center
        button.controlSize = .small
        button.translatesAutoresizingMaskIntoConstraints = false
    }
}
