//
//  FileInfoBar.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

private let separatorWidth: CGFloat = 1.0
private let itemSpacing: CGFloat = 6.0
private let separatorColor = NSColor(calibratedWhite: 0.52, alpha: 1.0)

protocol FileInfoBarDelegate: AnyObject {
    func fileInfoBar(_ fileInfoBar: FileInfoBar, changedEncoding encoding: String.Encoding)
}

class FileInfoBar: NSView {
    private lazy var labelText: NSTextField = createLabelText()
    private lazy var encodingPopup: NSPopUpButton = createEncodingPopup()
    private lazy var eolText: NSTextField = createEolText()

    var delegate: FileInfoBarDelegate?

    var encoding: String.Encoding? {
        get {
            if let enc = (encodingPopup.selectedItem?.representedObject as? NSNumber)?.uintValue {
                String.Encoding(rawValue: enc)
            } else {
                nil
            }
        }

        set {
            if let newValue,
               let index = encodingPopup.menu?.indexOfItem(withRepresentedObject: newValue.rawValue) {
                if index != -1 {
                    encodingPopup.selectItem(at: index)
                }
            }
        }
    }

    var eol: EndOfLine = .missing {
        didSet {
            eolText.stringValue = eol.description
        }
    }

    var fileAttrs: [FileAttributeKey: Any]? {
        didSet {
            setLabel(fileAttrs)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let stackView = NSStackView(views: [
            labelText,
            createSeparator(),
            encodingPopup,
            createSeparator(),
            eolText,
        ])

        stackView.orientation = .horizontal
        stackView.spacing = itemSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .centerY

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func createLabelText() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.isEditable = false
        view.isBordered = false
        view.drawsBackground = false
        view.alignment = .right
        view.translatesAutoresizingMaskIntoConstraints = false

        let cell = TextFieldVerticalCentered()
        cell.lineBreakMode = .byClipping

        view.cell = cell

        // set the font after the cell otherwise it is lost
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        return view
    }

    private func createEncodingPopup() -> NSPopUpButton {
        let view = NSPopUpButton(frame: .zero)

        view.cell = EncodingPopUpButtonCell(textCell: "")
        view.isBordered = false
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(encodingAction)

        return view
    }

    private func createEolText() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.isEditable = false
        view.isBordered = false
        view.drawsBackground = false
        view.translatesAutoresizingMaskIntoConstraints = false

        let cell = TextFieldVerticalCentered()
        cell.lineBreakMode = .byClipping

        view.cell = cell

        // set the font after the cell otherwise it is lost
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        return view
    }

    private func createSeparator() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = separatorColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false

        view.widthAnchor.constraint(equalToConstant: separatorWidth).isActive = true

        return view
    }

    // MARK: - Actions methods

    @objc
    func encodingAction(_: AnyObject) {
        if let delegate,
           let encoding {
            delegate.fileInfoBar(self, changedEncoding: encoding)
        }
    }

    // MARK: UI methods

    func setLabel(_ text: String) {
        labelText.stringValue = text
    }

    func setLabel(_ fileAttrs: [FileAttributeKey: Any]?) {
        guard let fileAttrs,
              let modificationDate = fileAttrs[.modificationDate] as? Date else {
            setLabel("")
            return
        }
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "ddMMyyyyHHmmss",
            options: 0,
            locale: Locale.current
        )
        let dateText = dateFormatter.string(from: modificationDate)
        let fileSize = fileAttrs[.size] as? NSNumber ?? NSNumber(value: -1)

        setLabel(String.localizedStringWithFormat(NSLocalizedString("%@ - %@ bytes", comment: ""), dateText, fileSize))
    }

    /**
     * update attributes reloading from the path
     * return true if the modification date has been changed
     */
    func updateFileAttrsFromPath(_ path: String) -> Bool {
        var changed = false

        // don't do anything if file no longer exists (for example when launched as external diff)
        guard FileManager.default.fileExists(atPath: path) else {
            return changed
        }
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        if let attrs,
           let updatedDate = attrs[.modificationDate] as? Date,
           let currentDate = fileAttrs?[.modificationDate] as? Date,
           currentDate != updatedDate {
            changed = true
        }

        fileAttrs = attrs

        return changed
    }
}
