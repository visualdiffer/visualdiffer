//
//  DifferenceCounters.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DifferenceCounters: NSTextField {
    private var counter: DiffCountersTextFieldCell

    override var intrinsicContentSize: NSSize {
        counter.cellSize(forBounds: .infinite)
    }

    override init(frame frameRect: NSRect) {
        counter = DiffCountersTextFieldCell(textCell: "")

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    func setupViews() {
        counter.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        isHidden = true
        drawsBackground = false
        isBezeled = false
        isBordered = false
        textColor = NSColor.controlTextColor
        backgroundColor = NSColor.controlColor
        controlSize = .small
        cell = counter
    }

    func update(counters: [DiffCountersItem]) {
        stringValue = ""
        counter.counterItems = counters
        counter.controlView?.needsDisplay = true
        invalidateIntrinsicContentSize()
    }
}
