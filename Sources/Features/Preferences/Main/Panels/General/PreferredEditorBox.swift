//
//  PreferredEditorBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class PreferredEditorBox: PreferencesBox {
    private lazy var editorPopup: NSPopUpButton = createEditorPopup()
    private lazy var removeButton: NSButton = createRemoveButton()
    private lazy var scriptLinkButton: NSButton = createScriptLinkButton()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        contentView?.addSubview(editorPopup)
        contentView?.addSubview(removeButton)
        contentView?.addSubview(scriptLinkButton)

        setupConstraints()
    }

    private func createEditorPopup() -> NSPopUpButton {
        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.cell = PreferredEditorPopupCell(textCell: "")
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createRemoveButton() -> NSButton {
        let view = NSButton(frame: .zero)

        view.title = NSLocalizedString("Remove", comment: "")
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = editorPopup.cell
        view.action = #selector(PreferredEditorPopupCell.removePreferredEditor)

        return view
    }

    private func createScriptLinkButton() -> NSButton {
        let view = LinkButton(
            title: NSLocalizedString("Open Script Folder", comment: ""),
            target: self,
            action: #selector(openScriptFolder)
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }

        NSLayoutConstraint.activate([
            editorPopup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            editorPopup.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -5),
            editorPopup.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),

            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            removeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),

            scriptLinkButton.leadingAnchor.constraint(equalTo: editorPopup.leadingAnchor),
            scriptLinkButton.topAnchor.constraint(equalTo: editorPopup.bottomAnchor, constant: 5),
        ])

        // fill the space when the container grows
        editorPopup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        editorPopup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // do not resize
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        removeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @objc
    func openScriptFolder(_: AnyObject) {
        guard let folder = try? FileManager.default.url(
            for: .applicationScriptsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return
        }

        NSWorkspace.shared.show(inFinder: [folder.osPath])
    }
}
