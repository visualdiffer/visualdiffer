//
//  LineNumberTableCellView.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

private let separatorWidth: CGFloat = 1.0
private let leftWidth: CGFloat = 10.0
private let rightWidth: CGFloat = 10.0
private let sectionSeparatorHeight: CGFloat = 2.0
private let leadingTextPadding: CGFloat = 2.0

class LineNumberTableCellView: NSTableCellView {
    private var minLineNumberBoxWidth: CGFloat = 0.0

    var diffLine: DiffLine?

    /**
     * If present is used to print the line text instead of line.text
     */
    @objc var formattedText: String?
    @objc var font: NSFont?

    // Determine if the view has focus
    var isHighlighted = false

    @objc dynamic var isSelected: Bool = false {
        didSet {
            if oldValue != isSelected {
                needsDisplay = true
            }
        }
    }

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Draw status, line number

    override func draw(_ dirtyRect: NSRect) {
        guard let lineSeparatorColor = CommonPrefs.shared.fileColor(.lineNumberSeparator)?.text else {
            super.draw(dirtyRect)
            return
        }
        // use bounds instead of the possible smaller dirtyRect
        var cellFrame = bounds
        cellFrame = drawLineNumberSeparator(withFrame: cellFrame, lineColor: lineSeparatorColor)
        cellFrame = drawContent(withFrame: cellFrame)

        cellFrame.origin.x += minLineNumberBoxWidth + leftWidth + rightWidth

        drawText(withFrame: cellFrame)
        super.draw(dirtyRect)

        if let sectionSeparatorLine = CommonPrefs.shared.fileColor(.sectionSeparatorLine)?.text {
            drawSectionSeparatorLine(withFrame: cellFrame, sectionColor: sectionSeparatorLine)
        }
    }

    private func drawLineNumber(_ cellFrame: NSRect) -> NSRect {
        guard let diffLine else {
            return cellFrame
        }

        var rect = NSRect(
            x: cellFrame.origin.x + leftWidth,
            y: cellFrame.origin.y,
            width: minLineNumberBoxWidth,
            height: cellFrame.size.height
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.lineBreakMode = .byClipping

        var attrs: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: lineNumberTextColor() ?? NSColor.white,
        ]
        if let font {
            attrs[.font] = font
        }

        let lineText = String(format: "%ld", diffLine.number) as NSString
        lineText.draw(in: rect, withAttributes: attrs)

        rect.origin.x += minLineNumberBoxWidth + rightWidth

        return cellFrame
    }

    private func highlightColor() -> NSColor? {
        diffLine?.color(
            for: .background,
            isSelected: isHighlighted
        )
    }

    private func drawText(withFrame frame: NSRect) {
        guard let diffLine, diffLine.number > 0 else {
            return
        }
        let textColor = diffLine.color(
            for: .text,
            isSelected: isSelected
        )
        // the background of the selected row has been drawn inside LineNumberTableRowView
        let backgroundColor = isSelected
            ? NSColor.clear
            : diffLine.color(
                for: .background,
                isSelected: false
            )

        backgroundColor.setFill()
        frame.fill()

        var textRect = frame
        textRect.origin.x += leadingTextPadding

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping

        var attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle,
        ]
        if let font {
            attrs[.font] = font
        }

        let lineText = (formattedText ?? diffLine.text) as NSString
        lineText.draw(in: textRect, withAttributes: attrs)
    }

    private func drawContent(withFrame frame: NSRect) -> NSRect {
        var cellFrame = frame

        if let diffLine,
           diffLine.number > 0 {
            cellFrame = drawLineNumber(cellFrame)
        } else {
            cellFrame = drawMissingLine(withFrame: cellFrame)
        }

        return cellFrame
    }

    private func drawLineNumberSeparator(withFrame cellFrame: NSRect, lineColor: NSColor) -> NSRect {
        // Draw line number separator vertical line
        let rectBorder = NSRect(
            x: cellFrame.origin.x + minLineNumberBoxWidth + leftWidth + rightWidth - separatorWidth,
            y: cellFrame.origin.y,
            width: separatorWidth,
            height: cellFrame.size.height
        )
        lineColor.setFill()
        rectBorder.fill()

        return cellFrame
    }

    @discardableResult
    private func drawSectionSeparatorLine(withFrame frame: NSRect, sectionColor: NSColor) -> NSRect {
        var cellFrame = frame

        if let diffLine,
           diffLine.isSectionSeparator {
            cellFrame.origin.y += cellFrame.size.height - sectionSeparatorHeight
            cellFrame.size.height = sectionSeparatorHeight

            sectionColor.set()
            cellFrame.fill()
        }
        return cellFrame
    }

    private func drawMissingLine(withFrame frame: NSRect) -> NSRect {
        guard let emptyImage = NSImage(named: VDImageNameEmpty) else {
            return frame
        }

        var rect = frame

        rect.origin.x += minLineNumberBoxWidth + leftWidth + rightWidth

        emptyImage.size = NSSize(width: rect.height, height: rect.height)
        let imageWidth = emptyImage.size.width
        let width = rect.width + rect.width / imageWidth

        rect.size = emptyImage.size

        while rect.origin.x < width {
            emptyImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            rect.origin.x += imageWidth
        }

        return frame
    }

    // MARK: - Size, font

    private func lineNumberTextColor() -> NSColor? {
        if isSelected {
            return diffLine?.color(
                for: .text,
                isSelected: isHighlighted
            )
        }
        return CommonPrefs.shared.fileColor(.lineNumber)?.text
    }

    @objc func setMinBoxWidthByLineCount(_ count: Int) {
        var attributes = [NSAttributedString.Key: Any]()

        if let font {
            attributes[.font] = font
        }

        let str = String(format: "%lld", max(count, 100)) as NSString
        minLineNumberBoxWidth = str.size(withAttributes: attributes).width
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
