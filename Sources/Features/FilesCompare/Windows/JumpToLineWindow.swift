//
//  JumpToLineWindow.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/10/11.
//  Copyright (c) 2011 visualdiffer.com
//

class JumpToLineWindow: NSWindow, NSWindowDelegate, NSSearchFieldDelegate {
    var side: DisplaySide = .left
    var lineNumber = -1
    var leftMaxLineNumber = -1
    var rightMaxLineNumber = -1

    private lazy var searchField: NSSearchField = {
        let view = NSSearchField(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.delegate = self

        return view
    }()

    private lazy var maxLineNumber: NSTextField = {
        let view = NSTextField(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isBezeled = false
        view.isBordered = false
        view.drawsBackground = false
        view.controlSize = .small
        view.alignment = .right
        view.focusRingType = .none
        view.isEditable = false
        view.isSelectable = false
        view.textColor = .controlTextColor

        return view
    }()

    private lazy var jumpSide: NSSegmentedControl = {
        let labels = [
            NSLocalizedString("Left", comment: ""),
            NSLocalizedString("Right", comment: ""),
        ]
        let view = NSSegmentedControl(
            labels: labels,
            trackingMode: .selectOne,
            target: self,
            action: #selector(sideChanged)
        )

        view.translatesAutoresizingMaskIntoConstraints = false
        view.segmentStyle = .rounded
        view.segmentDistribution = .fit
        view.alignment = .center

        return view
    }()

    private lazy var standardButtons = StandardButtons(
        primaryTitle: NSLocalizedString("Jump", comment: ""),
        secondaryTitle: NSLocalizedString("Cancel", comment: ""),
        target: self,
        action: #selector(closeSheet)
    )

    static func createSheet() -> JumpToLineWindow {
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
        ]

        return JumpToLineWindow(
            contentRect: NSRect(x: 0, y: 0, width: 410, height: 100),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )

        minSize = NSSize(width: 400, height: 100)
        delegate = self

        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(searchField)
            contentView.addSubview(maxLineNumber)
            contentView.addSubview(jumpSide)
            contentView.addSubview(standardButtons)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: maxLineNumber.leadingAnchor, constant: -5),

            maxLineNumber.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            maxLineNumber.trailingAnchor.constraint(equalTo: jumpSide.leadingAnchor, constant: -20),

            jumpSide.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            jumpSide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            standardButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    override func beginSheet(_ sheetWindow: NSWindow, completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        searchField.integerValue = lineNumber
        jumpSide.selectedSegment = side.rawValue

        enableJumpButton()

        sheetWindow.beginSheet(self, completionHandler: handler)
    }

    private func enableJumpButton() {
        guard let side = DisplaySide(rawValue: jumpSide.selectedSegment) else {
            fatalError("invalid jump side \(jumpSide.selectedSegment)")
        }
        let value = searchField.intValue
        var isEnabled = false

        switch side {
        case .left:
            maxLineNumber.stringValue = String(format: "/%ld", leftMaxLineNumber)
            isEnabled = value >= 1 && value <= leftMaxLineNumber
        case .right:
            maxLineNumber.stringValue = String(format: "/%ld", rightMaxLineNumber)
            isEnabled = value >= 1 && value <= rightMaxLineNumber
        }
        standardButtons.primaryButton.isEnabled = isEnabled
    }

    @objc
    func closeSheet(_ sender: AnyObject) {
        guard let side = DisplaySide(rawValue: jumpSide.selectedSegment) else {
            fatalError("invalid jump side \(jumpSide.selectedSegment)")
        }
        self.side = side
        lineNumber = searchField.integerValue
        sheetParent?.endSheet(self, returnCode: NSApplication.ModalResponse(rawValue: sender.tag))
    }

    @objc
    func sideChanged(_: AnyObject) {
        enableJumpButton()
    }

    func controlTextDidChange(_: Notification) {
        enableJumpButton()
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Only allow horizontal sizing
        NSSize(width: frameSize.width, height: sender.contentView?.frame.size.height ?? frameSize.height)
    }
}
