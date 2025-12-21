//
//  CompareItemTableCellView.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

class CompareItemTableCellView: NSView {
    lazy var text: NSTextField = createTextField()
    var icon: NSImageView?

    init(icon hasIcon: Bool) {
        if hasIcon {
            icon = Self.createImageView()
        }

        super.init(frame: .zero)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(text)

        if let icon {
            addSubview(icon)
            setupConstraints(icon: icon)
        } else {
            setupConstraints()
        }
    }

    private func setupConstraints(icon: NSImageView) {
        NSLayoutConstraint.activate([
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),

            text.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            // Align the textField to the bottom of the superview (view)
            text.bottomAnchor.constraint(equalTo: bottomAnchor),
            // is relative to icon
            text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 2),
            text.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            // Align the textField to the bottom of the superview (view)
            text.bottomAnchor.constraint(equalTo: bottomAnchor),
            // is relative to super view
            text.leadingAnchor.constraint(equalTo: leadingAnchor),
            text.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func createTextField() -> NSTextField {
        let view = NSTextField()

        view.allowsExpansionToolTips = true
        view.lineBreakMode = .byTruncatingTail
        view.alignment = .left
        view.isBordered = false
        view.backgroundColor = NSColor.clear
        view.refusesFirstResponder = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private static func createImageView() -> NSImageView {
        let view = NSImageView()

        view.alignment = .left
        view.imageScaling = .scaleProportionallyDown
        view.refusesFirstResponder = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func fileName(
        _ item: CompareItem,
        font: NSFont,
        isExpanded: Bool,
        followSymLinks _: Bool,
        hideEmptyFolders: Bool
    ) {
        if let fileName = resolvedFileName(item) {
            text.stringValue = fileName
            text.lineBreakMode = .byTruncatingMiddle
        }
        text.font = font
        icon?.image = IconUtils.shared.icon(for: item, size: 16, isExpanded: isExpanded, hideEmptyFolders: hideEmptyFolders)
    }

    func fileSize(
        _ item: CompareItem,
        font: NSFont,
        columnWidth: CGFloat
    ) {
        if item.isValidFile {
            text.frame = NSRect(x: 0, y: -2, width: 80, height: 17)
            text.font = font
            text.alignment = .right

            let size = item.isFile ? Int64(item.fileSize) : item.subfoldersSize
            var strSize = FileSizeFormatter.default.string(from: NSNumber(value: size), showInBytes: true, showUnitForBytes: false)
            // increment width by one digit to be sure it is enough large to contain the formatted number
            let sizeCellWidth: CGFloat = if let cell = text.cell as? NSTextFieldCell,
                                            let strSize {
                cell.widthString("9") + cell.widthString(strSize)
            } else {
                0
            }

            if columnWidth < sizeCellWidth {
                strSize = FileSizeFormatter.default.string(from: NSNumber(value: size), showInBytes: false, showUnitForBytes: false)
            }
            text.stringValue = strSize ?? "\(size)"
        }
    }

    func fileDate(
        _: CompareItem,
        date: Date?,
        font: NSFont,
        dateFormat: String
    ) {
        text.font = font

        // includes seconds on time using the current locale time components position
        if let date {
            let localeFormat = DateFormatter()

            localeFormat.dateFormat = DateFormatter.dateFormat(
                fromTemplate: dateFormat,
                options: 0,
                locale: Locale.current
            )
            text.formatter = localeFormat
            text.objectValue = date
        } else {
            text.formatter = nil
            text.objectValue = nil
        }
    }

    private func resolvedFileName(
        _ item: CompareItem
    ) -> String? {
        guard let fileName = item.fileName else {
            return nil
        }
        if item.isSymbolicLink,
           let path = item.path,
           let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
            return "\(fileName) -> \(destination)"
        }
        return fileName
    }
}
