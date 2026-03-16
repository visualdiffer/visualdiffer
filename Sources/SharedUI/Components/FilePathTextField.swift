//
//  FilePathTextField.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/09/20.
//  Copyright (c) 2020 visualdiffer.com
//

class FilePathTextField: NSTextField {
    private var displayPathText = ""

    var path = "" {
        didSet {
            if path.isEmpty {
                displayPathText = NSLocalizedString("(Empty Path)", comment: "")
                stringValue = displayPathText
                toolTip = NSLocalizedString("No Path Selected", comment: "")
                fileExists = false

                return
            }
            fileExists = FileManager.default.fileExists(atPath: path)

            if fileExists {
                stringValue = path
                displayPathText = path
                toolTip = path
            } else {
                stringValue = path
                displayPathText = path
                toolTip = NSLocalizedString("Path no longer exists", comment: "")
            }
        }
    }

    private(set) var fileExists = false
    var pattern: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    func highlightsPattern(_ backgroundStyle: NSView.BackgroundStyle) {
        var normalColor: NSColor
        var highlightColor: NSColor

        if backgroundStyle == .emphasized {
            normalColor = .alternateSelectedControlTextColor
            highlightColor = .alternateSelectedControlTextColor
        } else {
            if fileExists || path.isEmpty {
                normalColor = .controlTextColor
                highlightColor = .controlTextColor
            } else {
                normalColor = .systemRed
                highlightColor = .systemRed
            }
        }

        if let pattern,
           let font,
           !path.isEmpty {
            let ranges = path.rangesOfString(pattern, options: [.literal, .caseInsensitive])
            attributedStringValue = path.highlights(
                ranges,
                normalColor: normalColor,
                highlightColor: highlightColor,
                font: font
            )
        } else {
            stringValue = displayPathText
            textColor = normalColor
        }
    }
}
