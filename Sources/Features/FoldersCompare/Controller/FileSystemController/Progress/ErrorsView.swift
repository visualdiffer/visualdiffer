//
//  ErrorsView.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ErrorsView: NSStackView {
    private(set) var errors: [NSError] = []

    private lazy var errorTextContainer: NSScrollView = createScrollView()
    private lazy var errorsText: NSTextView = createErrorTextView()

    private lazy var title: NSTextField = .hintWithTitle(NSLocalizedString("Problems", comment: ""))

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        orientation = .vertical
        alignment = .leading
        spacing = 4
        translatesAutoresizingMaskIntoConstraints = false

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        collapse()
        isHidden = true

        addArrangedSubview(title)
        addArrangedSubview(errorTextContainer)

        // gives the text a default height
        errorsText.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
    }

    @objc func updateErrors(_ errorMessage: String) {
        // Show errors if it is the first time we are called
        if errors.isEmpty {
            isHidden = false
            expand()
        }

        let attributes = [
            NSAttributedString.Key.foregroundColor: errorsText.textColor ?? NSColor.white,
        ]

        errorsText.append(text: errorMessage + "\n", attributes: attributes)
    }

    func addError(_ error: NSError, forPath path: String) {
        let errorMessage = error.format(withPath: path)
        performSelector(onMainThread: #selector(updateErrors), with: errorMessage, waitUntilDone: true)

        errors.append(error)
        title.stringValue = String(format: NSLocalizedString("Problems (%lu)", comment: ""), errors.count)
    }

    func expand() {
        errorTextContainer.isHidden = false
    }

    func collapse() {
        errorTextContainer.isHidden = true
    }

    private func createErrorTextView() -> NSTextView {
        let view = NSTextView(frame: .zero)

        view.isEditable = true
        view.isSelectable = true
        view.isRichText = true
        view.autoresizingMask = [.width, .height]

        // This causes the text to appear a bit scrolled on the right, I can't find a valid solution
        view.disableWordWrap()

        return view
    }

    private func createScrollView() -> NSScrollView {
        let view = NSScrollView(frame: .zero)

        view.borderType = .bezelBorder
        view.autohidesScrollers = true
        view.hasHorizontalScroller = true
        view.hasVerticalScroller = true
        view.horizontalLineScroll = 19
        view.horizontalPageScroll = 10
        view.verticalLineScroll = 19
        view.verticalPageScroll = 10
        view.usesPredominantAxisScrolling = false

        view.documentView = errorsText

        return view
    }
}
