//
//  DifferenceCounters.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DifferenceCounters: NSTextField {
    private var counter: DiffCountersTextFieldCell

    override init(frame frameRect: NSRect) {
        counter = DiffCountersTextFieldCell(textCell: "")

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    @objc func update(counters: [DiffCountersItem]) {
        stringValue = ""
        counter.counterItems = counters
        counter.controlView?.needsDisplay = true
    }
}
