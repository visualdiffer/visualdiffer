//
//  ProgressBarView.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/04/12.
//  Copyright (c) 2012 visualdiffer.com
//

class ProgressBarView: NSView {
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
        view.image = NSImage(named: VDImageNameStop)
        view.imagePosition = .imageOnly
        view.imageScaling = .scaleProportionallyDown
        view.keyEquivalent = KeyEquivalent.escape

        return view
    }()

    var waitStopMessage = ""

    override var isHidden: Bool {
        didSet {
            if !isHidden {
                stopButton.isEnabled = true
                messageText.stringValue = ""
                setProgress(position: 0, maxValue: 1)
            }
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
            stopButton.widthAnchor.constraint(equalToConstant: 16),

            progressIndicator.leadingAnchor.constraint(equalTo: stopButton.trailingAnchor, constant: 4),
            progressIndicator.topAnchor.constraint(equalTo: topAnchor),
            progressIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 250),

            messageText.leadingAnchor.constraint(equalTo: progressIndicator.trailingAnchor, constant: 4),
            messageText.topAnchor.constraint(equalTo: topAnchor),
            messageText.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageText.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func updateMessage(_ text: String) {
        messageText.stringValue = text
        messageText.needsDisplay = true
    }

    func setProgress(position: Double, maxValue: Double) {
        progressIndicator.doubleValue = position
        progressIndicator.maxValue = maxValue
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
    }
}
