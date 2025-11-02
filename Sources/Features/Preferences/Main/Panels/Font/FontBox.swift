//
//  FontBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FontBox: PreferencesBox {
    var previewLabel: String {
        get {
            preview.stringValue
        }

        set {
            preview.stringValue = newValue
        }
    }

    var previewFont: NSFont? {
        get {
            preview.font
        }

        set {
            if let font = newValue {
                selectFont.isEnabled = true
                preview.font = font
                fontName.stringValue = String(format: "%@, %2.0fpt", font.displayName ?? "font", font.pointSize)
            } else {
                selectFont.isEnabled = false
            }
        }
    }

    private lazy var selectFont: NSButton = createSelectFont()
    private lazy var preview: NSTextField = createPreview()
    private lazy var fontName: NSTextField = createFontName()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(selectFont)
            contentView.addSubview(preview)
            contentView.addSubview(fontName)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            selectFont.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectFont.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectFont.widthAnchor.constraint(equalToConstant: 100),

            preview.leadingAnchor.constraint(equalTo: selectFont.trailingAnchor, constant: 20),
            preview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            preview.topAnchor.constraint(equalTo: contentView.topAnchor),
            preview.heightAnchor.constraint(equalToConstant: 22),

            fontName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            fontName.topAnchor.constraint(equalTo: preview.bottomAnchor),
        ])
    }

    private func createFontName() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = ""
        view.alignment = .right
        view.isBezeled = false
        view.isBordered = false
        view.textColor = NSColor.controlTextColor
        view.backgroundColor = NSColor.controlColor
        view.isEditable = false
        view.isSelectable = false
        view.font = NSFont.menuFont(ofSize: 9)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createSelectFont() -> NSButton {
        let view = NSButton(frame: .zero)

        view.title = NSLocalizedString("Select Font...", comment: "")
        view.bezelStyle = .push
        view.setButtonType(.momentaryPushIn)
        view.isBordered = true
        view.alignment = .center
        view.font = NSFont.messageFont(ofSize: 11)
        view.isEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(browseFont)

        return view
    }

    private func createPreview() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = ""
        view.isEditable = false
        view.isSelectable = false
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    @objc func browseFont(_: AnyObject) {
        if let font = preview.font {
            NSFontManager.shared.setSelectedFont(font, isMultiple: false)
        }
        NSFontManager.shared.orderFrontFontPanel(self)
    }
}
