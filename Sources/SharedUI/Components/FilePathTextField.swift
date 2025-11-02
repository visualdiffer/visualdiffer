//
//  FilePathTextField.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/09/20.
//  Copyright (c) 2020 visualdiffer.com
//

class FilePathTextField: NSTextField {
    var path = "" {
        didSet {
            fileExists = FileManager.default.fileExists(atPath: path)

            if fileExists {
                stringValue = path
                toolTip = path
            } else {
                stringValue = path
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
            if fileExists {
                normalColor = .controlTextColor
                highlightColor = .controlTextColor
            } else {
                normalColor = .systemRed
                highlightColor = .systemRed
            }
        }

        if let pattern,
           let font {
            let ranges = path.rangesOfString(pattern, options: [.literal, .caseInsensitive])
            attributedStringValue = path.highlights(
                ranges,
                normalColor: normalColor,
                highlightColor: highlightColor,
                font: font
            )
        } else {
            stringValue = path
            textColor = normalColor
        }
    }
}
