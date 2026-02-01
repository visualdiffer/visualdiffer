//
//  FinderExtensionBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FinderExtensionBox: PreferencesBox {
    private lazy var settingsLinkButton: NSButton = createSettingsLinkButton()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        contentView?.addSubview(settingsLinkButton)

        setupConstraints()
    }

    private func createSettingsLinkButton() -> NSButton {
        let view = LinkButton(
            title: NSLocalizedString("Open System Settings to enable the VisualDiffer extension", comment: ""),
            target: self,
            action: #selector(openLoginItemsSettings)
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .left
        view.setContentHuggingPriority(.required, for: .horizontal)

        return view
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }

        NSLayoutConstraint.activate([
            settingsLinkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            settingsLinkButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            settingsLinkButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
        ])
    }

    @objc func openLoginItemsSettings(_: AnyObject) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
