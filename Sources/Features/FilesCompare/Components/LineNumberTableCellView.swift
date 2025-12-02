//
//  LineNumberTableCellView.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

struct LineNumberCellData {
    let separatorWidth: CGFloat = 1.0
    let leftWidth: CGFloat = 10.0
    let rightWidth: CGFloat = 10.0
    let sectionSeparatorHeight: CGFloat = 2.0
    let leadingTextPadding: CGFloat = 2.0
}

class LineNumberTableCellView: NSTableCellView {
    var lineNumberWidth: CGFloat = 0.0 {
        didSet {
            lineNumberWidthConstraint?.constant = lineNumberWidth
        }
    }

    var cellData = LineNumberCellData()

    private let lineNumberTextField: NSTextField = {
        let view = NSTextField()
        view.isBezeled = false
        view.drawsBackground = false
        view.isEditable = false
        view.isSelectable = false
        view.alignment = .right
        view.lineBreakMode = .byClipping
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private let contentTextField: NSTextField = {
        let view = NSTextField(wrappingLabelWithString: "")
        view.isBezeled = false
        view.drawsBackground = false
        view.isEditable = false
        view.isSelectable = false
        view.alignment = .left
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private let separatorView: NSView = {
        let view = NSView()

        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let missingLineImageView: TiledImageView = {
        let view = TiledImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    private let sectionSeparatorView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    private var lineNumberWidthConstraint: NSLayoutConstraint?
    private var lineNumberCenterYConstraint: NSLayoutConstraint?
    private var lineNumberTopConstraint: NSLayoutConstraint?

    var diffLine: DiffLine? {
        didSet {
            updateContent()
        }
    }

    var formattedText: String? {
        didSet {
            updateContent()
        }
    }

    var font: NSFont? {
        didSet {
            lineNumberTextField.font = font
            contentTextField.font = font
            updateContent()
        }
    }

    var isWordWrapEnabled: Bool = false {
        didSet {
            updateWordWrapSettings()
            updateContent()
        }
    }

    var isHighlighted = false {
        didSet {
            updateColors()
        }
    }

    dynamic var isSelected: Bool = false {
        didSet {
            if oldValue != isSelected {
                updateColors()
            }
        }
    }

    init() {
        super.init(frame: .zero)

        setupViews()
        setupConstraints()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(lineNumberTextField)
        addSubview(separatorView)
        addSubview(contentTextField)
        addSubview(missingLineImageView)
        addSubview(sectionSeparatorView)
    }

    private func setupConstraints() {
        // align tyoe: center (no wrap) or top (wrap)
        lineNumberCenterYConstraint = lineNumberTextField.centerYAnchor.constraint(equalTo: centerYAnchor)
        lineNumberTopConstraint = lineNumberTextField.topAnchor.constraint(equalTo: topAnchor)
        lineNumberCenterYConstraint?.isActive = true

        lineNumberWidthConstraint = lineNumberTextField.widthAnchor.constraint(equalToConstant: lineNumberWidth)
        lineNumberWidthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            lineNumberTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: cellData.leftWidth),
            lineNumberTextField.heightAnchor.constraint(equalTo: heightAnchor),

            separatorView.leadingAnchor.constraint(equalTo: lineNumberTextField.trailingAnchor, constant: cellData.rightWidth),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: cellData.separatorWidth),

            contentTextField.leadingAnchor.constraint(equalTo: separatorView.trailingAnchor, constant: cellData.leadingTextPadding),
            contentTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentTextField.topAnchor.constraint(equalTo: topAnchor),
            contentTextField.bottomAnchor.constraint(equalTo: bottomAnchor),

            missingLineImageView.leadingAnchor.constraint(equalTo: separatorView.trailingAnchor),
            missingLineImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            missingLineImageView.topAnchor.constraint(equalTo: topAnchor),
            missingLineImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            sectionSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sectionSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sectionSeparatorView.heightAnchor.constraint(equalToConstant: cellData.sectionSeparatorHeight),
        ])
    }

    private func updateWordWrapSettings() {
        if isWordWrapEnabled {
            contentTextField.cell?.wraps = true
            contentTextField.cell?.isScrollable = false
            contentTextField.maximumNumberOfLines = 0
            contentTextField.lineBreakMode = .byWordWrapping

            lineNumberCenterYConstraint?.isActive = false
            lineNumberTopConstraint?.isActive = true
        } else {
            contentTextField.cell?.wraps = false
            contentTextField.cell?.isScrollable = true
            contentTextField.maximumNumberOfLines = 1
            contentTextField.lineBreakMode = .byClipping

            lineNumberTopConstraint?.isActive = false
            lineNumberCenterYConstraint?.isActive = true
        }
    }

    // MARK: - Update Content

    private func updateContent() {
        guard let diffLine else {
            hideAllContent()
            return
        }

        if diffLine.number > 0 {
            showLineNumberAndText()
            lineNumberTextField.stringValue = String(format: "%ld", diffLine.number)
            contentTextField.stringValue = formattedText ?? diffLine.text
            updateColors()
            updateSectionSeparator()
        } else {
            showMissingLineImage()
        }
    }

    private func showLineNumberAndText() {
        lineNumberTextField.isHidden = false
        contentTextField.isHidden = false
        missingLineImageView.isHidden = true
    }

    private func showMissingLineImage() {
        lineNumberTextField.isHidden = true
        contentTextField.isHidden = true
        missingLineImageView.isHidden = false

        if let emptyImage = NSImage(named: VDImageNameEmpty) {
            let color = CommonPrefs.shared.fileColor(.missing)?.background ?? NSColor.labelColor
            missingLineImageView.image = emptyImage.tinted(with: color)
        }
    }

    private func hideAllContent() {
        lineNumberTextField.isHidden = true
        contentTextField.isHidden = true
        missingLineImageView.isHidden = true
        sectionSeparatorView.isHidden = true
    }

    private func updateColors() {
        guard let diffLine else {
            return
        }

        if isSelected {
            lineNumberTextField.textColor = diffLine.color(for: .text, isSelected: isHighlighted)
        } else {
            lineNumberTextField.textColor = CommonPrefs.shared.fileColor(.lineNumber)?.text
        }

        let textColor = diffLine.color(for: .text, isSelected: isSelected)
        let backgroundColor = diffLine.color(for: .background, isSelected: isSelected)

        contentTextField.wantsLayer = true
        contentTextField.textColor = textColor
        contentTextField.layer?.backgroundColor = backgroundColor.cgColor

        if let separatorColor = CommonPrefs.shared.fileColor(.lineNumberSeparator)?.text {
            separatorView.wantsLayer = true
            separatorView.layer?.backgroundColor = separatorColor.cgColor
        }
    }

    private func updateSectionSeparator() {
        guard let diffLine else {
            sectionSeparatorView.isHidden = true
            return
        }

        if diffLine.isSectionSeparator,
           let sectionColor = CommonPrefs.shared.fileColor(.sectionSeparatorLine)?.text {
            sectionSeparatorView.isHidden = false
            sectionSeparatorView.wantsLayer = true
            sectionSeparatorView.layer?.backgroundColor = sectionColor.cgColor
        } else {
            sectionSeparatorView.isHidden = true
        }
    }

    /**
     * This is called by the parent as discussed on
     * https://developer.apple.com/documentation/appkit/nstablecellview/1483206-backgroundstyle?language=objc
     * "The default implementation automatically forwards calls to all subviews that implement setBackgroundStyle"
     */
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            isHighlighted = backgroundStyle == .emphasized
            needsDisplay = true
        }
    }

    // Ensure we're opaque for better performance
    override var isOpaque: Bool {
        true
    }
}
