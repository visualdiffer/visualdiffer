//
//  FileThumbnailView.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

class FileThumbnailView: NSView {
    var diffResult: DiffResult?
    var view: FilesTableView?
    var linesCount = 0

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    override var isFlipped: Bool {
        true
    }

    private func getPositionFromLine(_ lineNumber: Int, linesCount: Int, bounds: NSRect) -> CGFloat {
        CGFloat(lineNumber) * bounds.size.height / CGFloat(linesCount)
    }

    private func getLineFromPosition(_ point: NSPoint, linesCount: Int, bounds: NSRect) -> Int {
        Int(point.y * CGFloat(linesCount) / bounds.size.height)
    }

    private func createRect(_ section: DiffSection, bounds: NSRect) -> NSRect {
        guard let diffResult else {
            return .zero
        }
        let resultLinesCount = diffResult.leftSide.lines.count
        let top = getPositionFromLine(section.start, linesCount: resultLinesCount, bounds: bounds)
        let height = getPositionFromLine(section.end - section.start + 1, linesCount: resultLinesCount, bounds: bounds)

        return NSRect(x: 0, y: top, width: 0, height: height)
    }

    private func drawPositionBox(_ bounds: NSRect) {
        guard let view else {
            return
        }
        let firstRow = view.firstVisibleRow
        let lastRow = view.lastVisibleRow

        let posRect = NSRect(
            x: 0,
            y: getPositionFromLine(firstRow, linesCount: linesCount, bounds: bounds),
            width: bounds.size.width,
            height: getPositionFromLine(lastRow - firstRow, linesCount: linesCount, bounds: bounds)
        )

        if let backgroundColor = CommonPrefs.shared.fileColor(.positionBox)?.background {
            backgroundColor.setFill()
            posRect.frame(withWidth: 2.0)
        }
    }

    override func draw(_: NSRect) {
        guard let diffResult,
              let backgroundColor = CommonPrefs.shared.fileColor(.thumbnail)?.background else {
            drawPositionBox(bounds)
            return
        }
        // draw background
        backgroundColor.setFill()
        bounds.fill()

        for section in diffResult.sections {
            var rect = createRect(section, bounds: bounds)
            let index = section.start

            let leftLine = diffResult.leftSide.lines[index]
            rect.size.width = bounds.size.width / 2
            if let oldColor = leftLine.colors?.text {
                oldColor.setFill()
                rect.fill()
            }

            let newLine = diffResult.rightSide.lines[index]
            rect.origin.x = rect.size.width
            if let newColor = newLine.colors?.text {
                newColor.setFill()
                rect.fill()
            }
        }
        drawPositionBox(bounds)
    }

    // http://borkware.com/quickies/one?topic=NSView
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }

    // MARK: - Mouse events

    override func mouseDown(with event: NSEvent) {
        guard let diffResult,
              let view else {
            return
        }
        let localPoint = convert(event.locationInWindow, from: nil)
        let leftLinesCount = diffResult.leftSide.lines.count
        var line = getLineFromPosition(localPoint, linesCount: leftLinesCount, bounds: bounds)

        if leftLinesCount != linesCount {
            line = diffResult.leftSide.lines[line].filteredIndex
        }
        view.scrollTo(row: line, center: true)

        let indexes = IndexSet(integer: line)
        view.selectRowIndexes(indexes, byExtendingSelection: false)
        view.linkedView?.selectRowIndexes(indexes, byExtendingSelection: false)
    }

    override func scrollWheel(with event: NSEvent) {
        // redirect scroll to view
        view?.scrollWheel(with: event)
    }
}
