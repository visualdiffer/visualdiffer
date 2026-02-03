//
//  ExtensionBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/01/26.
//  Copyright (c) 2025 visualdiffer.com
//

class ExtensionBox: PreferencesBox {
    private lazy var finderTitleLabel = createFinderTitleLabel()
    private lazy var settingsButton = createSettingsButton()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        contentView?.addSubview(finderTitleLabel)
        contentView?.addSubview(settingsButton)

        setupConstraints()
    }

    private func createFinderTitleLabel() -> NSTextField {
        let view = NSTextField(labelWithString: NSLocalizedString("Finder Extension", comment: ""))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .left
        view.lineBreakMode = .byTruncatingTail
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return view
    }

    private func createSettingsButton() -> NSButton {
        let view = NSButton(
            title: NSLocalizedString("Open System Settings", comment: ""),
            target: self,
            action: #selector(openLoginItemsSettings)
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .right
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)

        return view
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }

        let labelTrailingConstraint = finderTitleLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: settingsButton.leadingAnchor,
            constant: -8
        )
        labelTrailingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            finderTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            labelTrailingConstraint,
            finderTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            finderTitleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 5),
            finderTitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -5),

            settingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            settingsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            settingsButton.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 5),
            settingsButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -5),
        ])
    }

    @objc func openLoginItemsSettings(_: AnyObject) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
