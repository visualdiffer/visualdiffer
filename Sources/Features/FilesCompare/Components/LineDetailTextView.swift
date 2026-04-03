//
//  LineDetailTextView.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/04/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// renders the detail line text and protects the trailing line ending marker from selection and copy
final class LineDetailTextView: NSTextView {
    private static let minimumLineEndingContrast: CGFloat = 2.6
    private static let minimumLineEndingContrastOnDark: CGFloat = 4.0
    private static let initialLineEndingBlendFraction: CGFloat = 0.55
    private static let initialLineEndingBlendFractionOnDark: CGFloat = 0.35
    private static let darkBackgroundLuminanceThreshold: CGFloat = 0.5
    private static let lineEndingAdjustmentStart: CGFloat = 0.15
    private static let lineEndingAdjustmentStep: CGFloat = 0.1
    private static let lineEndingAdjustmentEnd: CGFloat = 1.0
    private static let contrastRatioBias: CGFloat = 0.05

    var protectedSuffixLength: Int = 0 {
        didSet {
            clampSelection()
        }
    }

    private var selectableLength: Int {
        let stringLength = (string as NSString).length
        let clampedSuffixLength = max(0, min(protectedSuffixLength, stringLength))

        return max(0, stringLength - clampedSuffixLength)
    }

    private var protectedRange: NSRange {
        let stringLength = (string as NSString).length
        let clampedSuffixLength = max(0, min(protectedSuffixLength, stringLength))

        return NSRange(location: selectableLength, length: clampedSuffixLength)
    }

    override func selectionRange(
        forProposedRange proposedCharRange: NSRange,
        granularity: NSSelectionGranularity
    ) -> NSRange {
        clamp(super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity))
    }

    override func setSelectedRange(_ charRange: NSRange) {
        super.setSelectedRange(clamp(charRange))
    }

    override func setSelectedRange(
        _ charRange: NSRange,
        affinity: NSSelectionAffinity,
        stillSelecting flag: Bool
    ) {
        super.setSelectedRange(clamp(charRange), affinity: affinity, stillSelecting: flag)
    }

    override func setSelectedRanges(
        _ ranges: [NSValue],
        affinity: NSSelectionAffinity,
        stillSelecting flag: Bool
    ) {
        let clampedRanges = ranges.map { NSValue(range: clamp($0.rangeValue)) }

        super.setSelectedRanges(clampedRanges, affinity: affinity, stillSelecting: flag)
    }

    override func copy(_: Any?) {
        let range = clamp(selectedRange())

        guard range.length > 0 else {
            return
        }

        let selectedString = (string as NSString).substring(with: range)
        let pasteboard = NSPasteboard.general

        pasteboard.clearContents()
        pasteboard.setString(selectedString, forType: .string)
    }

    func clearContent() {
        string = ""
        protectedSuffixLength = 0
    }

    func updateContent(
        text: String,
        lineEnding: String,
        textColor: NSColor?,
        backgroundColor: NSColor?
    ) {
        string = text + lineEnding
        // use the NSString length because NSTextView selection ranges are NSRange-based
        protectedSuffixLength = (lineEnding as NSString).length

        if let textColor, let backgroundColor {
            setTextColor(textColor, backgroundColor: backgroundColor)
        } else {
            setTextColor(.controlTextColor, backgroundColor: .clear)
        }

        applyLineEndingStyle(textColor: textColor, backgroundColor: backgroundColor)
    }

    private func applyLineEndingStyle(textColor: NSColor?, backgroundColor: NSColor?) {
        guard protectedRange.length > 0 else {
            return
        }
        guard let textStorage else {
            return
        }

        let resolvedTextColor = textColor ?? .labelColor
        let resolvedBackgroundColor = backgroundColor ?? .textBackgroundColor
        let lineEndingColor = resolvedLineEndingColor(
            textColor: resolvedTextColor,
            backgroundColor: resolvedBackgroundColor
        )

        textStorage.addAttribute(.foregroundColor, value: lineEndingColor, range: protectedRange)
        textStorage.addAttribute(.backgroundColor, value: resolvedBackgroundColor, range: protectedRange)
    }

    private func clamp(_ range: NSRange) -> NSRange {
        let maxLocation = selectableLength
        let location = min(max(0, range.location), maxLocation)
        let endLocation = min(max(location, NSMaxRange(range)), maxLocation)

        return NSRange(location: location, length: endLocation - location)
    }

    private func clampSelection() {
        setSelectedRanges(selectedRanges, affinity: selectionAffinity, stillSelecting: false)
    }

    private func resolvedLineEndingColor(textColor: NSColor, backgroundColor: NSColor) -> NSColor {
        let isDarkBackground = backgroundColor.relativeLuminance < Self.darkBackgroundLuminanceThreshold
        let minimumContrast = isDarkBackground
            ? Self.minimumLineEndingContrastOnDark
            : Self.minimumLineEndingContrast
        let initialBlendTarget: NSColor = isDarkBackground ? .white : backgroundColor
        let initialBlendFraction = isDarkBackground
            ? Self.initialLineEndingBlendFractionOnDark
            : Self.initialLineEndingBlendFraction
        let initialColor = textColor.blended(
            withFraction: initialBlendFraction,
            of: initialBlendTarget
        ) ?? NSColor.secondaryLabelColor

        if contrastRatio(between: initialColor, and: backgroundColor) >= minimumContrast {
            return initialColor
        }

        let targetColor: NSColor = isDarkBackground
            ? .white
            : .black

        for step in stride(
            from: Self.lineEndingAdjustmentStart,
            through: Self.lineEndingAdjustmentEnd,
            by: Self.lineEndingAdjustmentStep
        ) {
            guard let adjustedColor = initialColor.blended(withFraction: step, of: targetColor) else {
                continue
            }

            if contrastRatio(between: adjustedColor, and: backgroundColor) >= minimumContrast {
                return adjustedColor
            }
        }

        return targetColor
    }

    private func contrastRatio(between firstColor: NSColor, and secondColor: NSColor) -> CGFloat {
        let firstLuminance = firstColor.relativeLuminance
        let secondLuminance = secondColor.relativeLuminance
        let lighterColor = max(firstLuminance, secondLuminance)
        let darkerColor = min(firstLuminance, secondLuminance)

        return (lighterColor + Self.contrastRatioBias) / (darkerColor + Self.contrastRatioBias)
    }
}

private extension NSColor {
    private static let redLuminanceWeight: CGFloat = 0.2126
    private static let greenLuminanceWeight: CGFloat = 0.7152
    private static let blueLuminanceWeight: CGFloat = 0.0722
    private static let linearizationThreshold: CGFloat = 0.03928
    private static let lowRangeDivisor: CGFloat = 12.92
    private static let gammaOffset: CGFloat = 0.055
    private static let gammaDivisor: CGFloat = 1.055
    private static let gammaExponent: CGFloat = 2.4

    var relativeLuminance: CGFloat {
        guard let rgbColor = usingColorSpace(.sRGB) else {
            return 0
        }

        let components = [rgbColor.redComponent, rgbColor.greenComponent, rgbColor.blueComponent]
            .map(Self.linearizedComponent)

        return (Self.redLuminanceWeight * components[0])
            + (Self.greenLuminanceWeight * components[1])
            + (Self.blueLuminanceWeight * components[2])
    }

    static func linearizedComponent(_ value: CGFloat) -> CGFloat {
        if value <= linearizationThreshold {
            return value / lowRangeDivisor
        }

        return pow((value + gammaOffset) / gammaDivisor, gammaExponent)
    }
}
