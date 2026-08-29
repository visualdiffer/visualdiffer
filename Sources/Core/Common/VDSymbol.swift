//
//  VDSymbol.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

// images still backed by png assets
let VDImageNameEmpty = NSImage.Name("empty")

protocol VDSymbolImage: RawRepresentable where RawValue == String {}

// single source of truth mapping logical icon names to symbol names,
// adjust the raw values here to change the icon shown everywhere,
// names prefixed with "vd." are custom symbols bundled in the asset catalog,
// all the others are system SF Symbols
enum VDSymbol {
    enum Asset: String, VDSymbolImage {
        case rewind = "vd.rewind"
        case nextFile = "vd.file_next"
        case prevFile = "vd.file_prev"
        case top = "vd.top"
        case bottom = "vd.bottom"
        case emptyPath = "square.dashed"
    }

    enum Toolbar: String, VDSymbolImage {
        case copyLeft = "vd.copyl"
        case copyRight = "vd.copyr"
        case moveLeft = "vd.movel"
        case moveRight = "vd.mover"
        case syncLeft = "vd.syncl"
        case syncRight = "vd.syncr"
        case syncBoth = "vd.syncBoth"
        case delete = "vd.delete"
        case copyLinesLeft = "vd.copyLinesl"
        case copyLinesRight = "vd.copyLinesr"
        case dateTime = "vd.datetime"
        case expand = "vd.expand"
        case collapse = "vd.collapse"
        case filter = "vd.filter"
        case nextDifference = "vd.next"
        case prevDifference = "vd.prev"
        case refresh = "vd.refresh"
        case sessionPreferences = "slider.vertical.3"
        case showInFinder = "vd.finder"
        case openWith = "vd.openWith"
        case comparisonMethod = "list.bullet.rectangle"
        case wordWrapOn = "vd.wordWrapOn"
        case wordWrapOff = "vd.wordWrapOff"
        case compareItems = "vd.compareItems"
    }

    enum Button: String, VDSymbolImage {
        case stop = "vd.stop"
        case browse = "vd.browse"
        case save = "vd.save"
    }

    enum Preference: String, VDSymbolImage {
        case general = "gearshape"
        case folder
        case font = "textformat.size"
        case text = "doc.plaintext"
        case paths = "lock.open"
        case confirmations = "exclamationmark.triangle"
        case keyboard = "command"
    }
}

extension VDSymbol {
    // custom symbols bundled in the asset catalog use this prefix
    static let customSymbolPrefix = "vd."

    static let summaryIconPointSize: CGFloat = 64
}

extension VDSymbolImage {
    func image(accessibilityDescription: String? = nil) -> NSImage {
        if rawValue.hasPrefix(VDSymbol.customSymbolPrefix) {
            // asset catalog name with the custom prefix stripped
            let image = NSImage.required(named: String(rawValue.dropFirst(VDSymbol.customSymbolPrefix.count)))
            image.accessibilityDescription = accessibilityDescription

            return image
        }
        guard let image = NSImage(systemSymbolName: rawValue, accessibilityDescription: accessibilityDescription) else {
            preconditionFailure("Unable to find the system symbol named '\(rawValue)'")
        }

        return image
    }

    func image(pointSize: CGFloat, tint: NSColor? = nil, accessibilityDescription: String? = nil) -> NSImage {
        var configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        if let tint {
            // palette color renders the symbol tinted instead of as a template
            configuration = configuration.applying(.init(paletteColors: [tint]))
        }
        guard let image = image(accessibilityDescription: accessibilityDescription)
            .withSymbolConfiguration(configuration) else {
            preconditionFailure("Unable to configure the system symbol named '\(rawValue)'")
        }

        return image
    }

    func summaryImage(tint: NSColor? = nil) -> NSImage {
        image(pointSize: VDSymbol.summaryIconPointSize, tint: tint)
    }
}
