//
//  ConsoleView.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/04/12.
//  Copyright (c) 2012 visualdiffer.com
//

protocol ConsoleViewDelegate: AnyObject {
    func hide(console: ConsoleView)
}

class ConsoleView: NSView, NSTextViewDelegate {
    var delegate: ConsoleViewDelegate?

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "ddMMyyHHmmss",
            options: 0,
            locale: Locale.current
        )

        return dateFormatter
    }()

    private lazy var toolbar: ConsoleToolbarView = {
        let view = ConsoleToolbarView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.clearButton.target = self
        view.clearButton.action = #selector(clear)

        view.hideButton.target = self
        view.hideButton.action = #selector(hide)

        return view
    }()

    private lazy var consoleText: NSTextView = {
        let view = NSTextView(frame: .zero)

        view.isEditable = true
        view.isSelectable = true
        view.isRichText = true
        view.font = CommonPrefs.shared.consoleLogFont
        view.autoresizingMask = [.width, .height]
        view.delegate = self

        return view
    }()

    private lazy var scrollView: NSScrollView = {
        let view = NSScrollView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.borderType = .bezelBorder
        view.autohidesScrollers = true
        view.hasHorizontalScroller = true
        view.hasVerticalScroller = true
        view.horizontalLineScroll = 19
        view.horizontalPageScroll = 10
        view.verticalLineScroll = 19
        view.verticalPageScroll = 10
        view.usesPredominantAxisScrolling = false

        view.documentView = consoleText

        return view
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(toolbar)
        addSubview(scrollView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 25),

            scrollView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.textBackgroundColor.setFill()
        bounds.fill()
    }

    func log(info message: String) {
        let colors = CommonPrefs.shared.consoleLogColors(.info)
        log(message: message, at: Date(), colors: colors)
    }

    func log(warning message: String) {
        let colors = CommonPrefs.shared.consoleLogColors(.warning)
        log(message: message, at: Date(), colors: colors)
    }

    func log(error message: String) {
        let colors = CommonPrefs.shared.consoleLogColors(.error)
        log(message: message, at: Date(), colors: colors)
    }

    private func log(
        message: String,
        at atTime: Date,
        colors: ColorSet
    ) {
        let dateText = dateFormatter.string(from: atTime)
        let dict: [NSAttributedString.Key: Any] = [
            .font: consoleText.font ?? CommonPrefs.shared.consoleLogFont,
            .foregroundColor: colors.text,
            .backgroundColor: colors.background,
        ]
        consoleText.append(
            text: String(format: "%@ %@\n", dateText, message),
            attributes: dict
        )
    }

    @objc
    func clear(_: AnyObject) {
        consoleText.string = ""
    }

    @objc
    func hide(_: AnyObject) {
        delegate?.hide(console: self)
    }

    func focus() {
        window?.makeFirstResponder(consoleText)
    }

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(cancelOperation(_:)) {
            hide(self)
            return true
        }
        return false
    }
}
