//
//  ProgressBarView.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/04/12.
//  Copyright (c) 2012 visualdiffer.com
//

class ProgressBarView: NSView {
    private static let stopButtonWidth: CGFloat = 16
    private static let stopButtonSpacing: CGFloat = 4

    private lazy var progressIndicator: NSProgressIndicator = {
        let view = NSProgressIndicator(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.style = .bar
        view.isDisplayedWhenStopped = true
        view.minValue = 0
        view.maxValue = 100
        view.controlSize = .small
        view.isIndeterminate = false

        return view
    }()

    private lazy var messageText: NSTextField = {
        let view = NSTextField(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.stringValue = NSLocalizedString("Waiting...", comment: "")
        view.isBordered = false
        view.isEditable = false
        view.isBezeled = false
        view.drawsBackground = false
        view.textColor = NSColor.controlTextColor
        view.backgroundColor = NSColor.controlColor
        view.lineBreakMode = .byTruncatingMiddle
        view.controlSize = .small
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        return view
    }()

    private lazy var stopButton: NSButton = {
        let view = NSButton(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.setButtonType(.momentaryPushIn)
        view.isBordered = false
        view.state = .off
        view.alignment = .center
        view.image = VDSymbol.Button.stop.image(accessibilityDescription: NSLocalizedString("Stop", comment: ""))
        view.imagePosition = .imageOnly
        view.imageScaling = .scaleProportionallyDown
        view.keyEquivalent = KeyEquivalent.escape
        view.isHidden = true

        return view
    }()

    private lazy var stopButtonWidthConstraint = stopButton.widthAnchor.constraint(
        equalToConstant: 0
    )

    private lazy var stopButtonSpacingConstraint = progressIndicator.leadingAnchor.constraint(
        equalTo: stopButton.trailingAnchor,
        constant: 0
    )

    var waitStopMessage = ""

    // a comparison that cannot be interrupted never sets a stop action, the button would
    // be inert there so it takes no room either
    private var isStopButtonHidden: Bool {
        stopButton.target == nil
    }

    override var isHidden: Bool {
        didSet {
            if !isHidden {
                stopButton.isEnabled = !isStopButtonHidden
                messageText.stringValue = ""
                setProgress(position: 0, maxValue: 1)
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    func setupViews() {
        addSubview(stopButton)
        addSubview(progressIndicator)
        addSubview(messageText)

        setupConstraints()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            stopButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            stopButton.topAnchor.constraint(equalTo: topAnchor),
            stopButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            stopButtonWidthConstraint,

            stopButtonSpacingConstraint,
            progressIndicator.topAnchor.constraint(equalTo: topAnchor),
            progressIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 250),

            messageText.leadingAnchor.constraint(equalTo: progressIndicator.trailingAnchor, constant: 4),
            messageText.topAnchor.constraint(equalTo: topAnchor),
            messageText.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageText.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        messageText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        messageText.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    func updateMessage(_ text: String) {
        messageText.stringValue = text
        messageText.needsDisplay = true
    }

    func setProgress(position: Double, maxValue: Double) {
        // the range must be set before the value or it clamps the value
        progressIndicator.maxValue = maxValue
        progressIndicator.doubleValue = position
    }

    func advanceProgress() {
        progressIndicator.increment(by: 1)
    }

    func stop() {
        stopButton.isEnabled = false
        updateMessage(waitStopMessage)
    }

    func setStop(action: Selector, target: AnyObject) {
        stopButton.target = target
        stopButton.action = action

        stopButton.isHidden = false
        stopButtonWidthConstraint.constant = Self.stopButtonWidth
        stopButtonSpacingConstraint.constant = Self.stopButtonSpacing
    }

    // for the callers that are about to block the main thread, the next display cycle
    // happens only once that work is over
    func displayMessage(_ text: String) {
        updateMessage(text)

        // a window that is not on screen draws into a surface nobody sees
        if window?.isVisible == true {
            displayIfNeeded()
        }
    }
}
