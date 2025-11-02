//
//  FilePathTableCellView.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FilePathTableCellView: NSTableCellView {
    @objc convenience init(identifier: NSUserInterfaceItemIdentifier) {
        self.init(frame: .zero)
        self.identifier = identifier
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    private func setupViews() {
        let image = createImageView()
        addSubview(image)
        imageView = image

        let text = createFilePathTextField()
        addSubview(text)
        textField = text

        setupConstraints()
    }

    private func createImageView() -> NSImageView {
        let view = NSImageView(frame: .zero)

        view.imageScaling = .scaleProportionallyUpOrDown
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createFilePathTextField() -> FilePathTextField {
        let view = FilePathTextField(frame: .zero)

        view.isBezeled = false
        view.drawsBackground = false
        view.isEditable = false
        view.isSelectable = false
        view.lineBreakMode = .byTruncatingMiddle
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func setupConstraints() {
        guard let imageView, let textField else {
            return
        }
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 17),
            imageView.heightAnchor.constraint(equalToConstant: 17),

            textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func update(path: String) {
        guard let pathTextField = textField as? FilePathTextField else {
            return
        }
        pathTextField.path = path

        guard let imageView else {
            return
        }

        if pathTextField.fileExists {
            imageView.image = IconUtils.shared.icon(forFile: URL(filePath: path, directoryHint: .notDirectory), size: 16.0)
        } else {
            imageView.image = NSImage(named: NSImage.cautionName)
            imageView.image?.size = NSSize(width: 16.0, height: 16.0)
        }
    }

    func update(pattern: String) {
        guard let pathTextField = textField as? FilePathTextField else {
            return
        }

        pathTextField.pattern = pattern
    }

    /**
     * This is called by the parent as discussed on
     * https://developer.apple.com/documentation/appkit/nstablecellview/1483206-backgroundstyle?language=objc
     * "The default implementation automatically forwards calls to all subviews that implement setBackgroundStyle"
     */
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            guard let pathTextField = textField as? FilePathTextField else {
                return
            }
            pathTextField.highlightsPattern(backgroundStyle)
        }
    }
}
