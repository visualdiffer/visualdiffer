//
//  SaveFileAccessoryView.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class SaveFileAccessoryView: NSView {
    private let leftButton: NSButton
    private let rightButton: NSButton

    @objc var saveLeft: Bool {
        get {
            leftButton.state == .on
        }

        set {
            leftButton.state = newValue ? .on : .off
        }
    }

    @objc var saveRight: Bool {
        get {
            rightButton.state == .on
        }

        set {
            rightButton.state = newValue ? .on : .off
        }
    }

    @objc
    convenience init(withLeftChecked leftChecked: Bool, rightChecked: Bool) {
        self.init(frame: NSRect(x: 0, y: 0, width: 100, height: 60))
        saveLeft = leftChecked
        saveRight = rightChecked
    }

    override init(frame frameRect: NSRect) {
        leftButton = NSButton(
            checkboxWithTitle: NSLocalizedString("Left", comment: ""),
            target: nil,
            action: nil
        )
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton = NSButton(
            checkboxWithTitle: NSLocalizedString("Right", comment: ""),
            target: nil,
            action: nil
        )
        rightButton.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: frameRect)

        saveLeft = true
        saveRight = true

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(leftButton)
        addSubview(rightButton)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            leftButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            leftButton.topAnchor.constraint(equalTo: topAnchor),
            leftButton.heightAnchor.constraint(equalToConstant: 40),

            rightButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightButton.bottomAnchor.constraint(equalTo: leftButton.bottomAnchor, constant: 5),
        ])
    }
}
