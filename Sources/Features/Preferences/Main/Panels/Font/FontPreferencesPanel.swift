//
//  FontPreferencesPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FontPreferencesPanel: NSView, NSFontChanging, PreferencesPanelDataSource {
    private lazy var folderFontBox: FontBox = createFontBox(
        title: NSLocalizedString("Folder Viewer Listing", comment: ""),
        previewLabel: NSLocalizedString("filename.ext", comment: "")
    )

    private lazy var fileFontBox: FontBox = createFontBox(
        title: NSLocalizedString("File Viewer Text", comment: ""),
        previewLabel: NSLocalizedString("while (a < b) {}", comment: "")
    )

    private lazy var restoreDefaults: NSButton = createRestoreDefaults()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        NSFontManager.shared.target = self

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(folderFontBox)
        addSubview(fileFontBox)
        addSubview(restoreDefaults)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            folderFontBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            folderFontBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            folderFontBox.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            folderFontBox.heightAnchor.constraint(equalToConstant: 80),

            fileFontBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            fileFontBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            fileFontBox.topAnchor.constraint(equalTo: folderFontBox.bottomAnchor, constant: 5),
            fileFontBox.heightAnchor.constraint(equalToConstant: 80),

            restoreDefaults.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            restoreDefaults.topAnchor.constraint(equalTo: fileFontBox.bottomAnchor, constant: 5),
        ])
    }

    private func createFontBox(title: String, previewLabel: String) -> FontBox {
        let view = FontBox(title: title)

        view.previewLabel = previewLabel

        return view
    }

    private func createRestoreDefaults() -> NSButton {
        let view = NSButton(frame: .zero)

        view.title = NSLocalizedString("Defaults", comment: "")
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(restoreDefaultsAction)

        return view
    }

    @objc
    func restoreDefaultsAction(_: AnyObject) {
        CommonPrefs.shared.restoreDefaultFonts()
        reloadData()
    }

    @objc
    func changeFont(_ sender: NSFontManager?) {
        guard let sender,
              let selectedFont = sender.selectedFont else {
            return
        }
        let newFont = sender.convert(selectedFont)

        if selectedFont == fileFontBox.previewFont {
            CommonPrefs.shared.fileTextFont = newFont
            fileFontBox.previewFont = newFont
        } else if selectedFont == folderFontBox.previewFont {
            CommonPrefs.shared.folderListingFont = newFont
            folderFontBox.previewFont = newFont
        }
    }

    func reloadData() {
        folderFontBox.previewFont = CommonPrefs.shared.folderListingFont
        fileFontBox.previewFont = CommonPrefs.shared.fileTextFont
    }
}
