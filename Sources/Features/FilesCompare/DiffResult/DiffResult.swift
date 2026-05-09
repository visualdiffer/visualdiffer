//
//  DiffResult.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

class DiffResult {
    struct Options: OptionSet {
        let rawValue: Int

        static let ignoreLineEndings = Options(rawValue: 1 << 0)
        static let ignoreLeadingWhitespaces = Options(rawValue: 1 << 1)
        static let ignoreTrailingWhitespaces = Options(rawValue: 1 << 2)
        static let ignoreInternalWhitespaces = Options(rawValue: 1 << 3)
        static let ignoreCharacterCase = Options(rawValue: 1 << 4)
    }

    private(set) var leftSide = DiffSide()
    private(set) var rightSide = DiffSide()
    private(set) var sections = [DiffSection]()
    private(set) var summary = DiffSummary()

    convenience init(sections: [DiffSection]) {
        self.init()

        self.sections = sections
    }

    func diffSide(for side: DisplaySide) -> DiffSide {
        switch side {
        case .left:
            leftSide
        case .right:
            rightSide
        }
    }

    // currently used only by the unit tests
    // periphery:ignore
    func diff(
        leftText: String,
        rightText: String,
        options: Options = []
    ) {
        diff(
            leftLines: DiffLineComponent.splitLines(leftText),
            rightLines: DiffLineComponent.splitLines(rightText),
            options: options
        )
    }

    func diff(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        options: Options = []
    ) {
        // swiftlint:disable force_cast
        let stringifier: (Any) -> String = {
            options.applyTransformations(component: $0 as! DiffLineComponent)
        }
        // swiftlint:enable force_cast

        let udiff = UnifiedDiff(
            originalLines: leftLines,
            revisedLines: rightLines,
            stringifier: stringifier
        )
        let script = udiff.diff_2(false)

        var processor = DiffProcessor(
            leftLines: leftLines,
            rightLines: rightLines,
            options: options
        )
        processor.process(changes: script)

        leftSide = processor.leftSide
        rightSide = processor.rightSide
        sections = processor.sections
        summary = processor.summary
    }

    @discardableResult
    func insert(
        text: String,
        at startIndex: Int,
        side: DisplaySide
    ) -> Int {
        switch side {
        case .left:
            insertLines(
                text: text,
                destination: leftSide,
                otherSide: rightSide,
                at: startIndex,
                type: .deleted
            )
        case .right:
            insertLines(
                text: text,
                destination: rightSide,
                otherSide: leftSide,
                at: startIndex,
                type: .added
            )
        }
    }

    private func insertLines(
        text: String,
        destination: DiffSide,
        otherSide: DiffSide,
        at startIndex: Int,
        type: DiffChangeType
    ) -> Int {
        // adding lines beyond the end is not allowed
        if startIndex > destination.lines.count {
            return -1
        }
        var index = startIndex

        DiffLineComponent.enumerateLines(text: text) { component in
            // adds missing lines to both diff sides to accommodate insertion at the specified index
            if index == destination.lines.count {
                destination.insert(DiffLine.missingLine(), at: index)
                otherSide.insert(DiffLine.missingLine(), at: index)
            }
            let destLine = destination.lines[index]
            if destLine.type == .missing {
                destLine.component = component
                let otherLine = otherSide.lines[index]
                // simple comparison
                if otherLine.text == component.text {
                    otherLine.type = .matching
                    destLine.type = .matching
                } else {
                    if otherLine.type == .missing {
                        destLine.type = type
                    } else {
                        otherLine.type = .changed
                        destLine.type = .changed
                    }
                }
            } else {
                // line numbers will be set correctly below
                destination.insert(DiffLine(with: type, number: 0, component: component), at: index)
                otherSide.insert(DiffLine.missingLine(), at: index)
            }
            index += 1
        }
        destination.renumberLines()

        return index < destination.lines.count ? index : index - 1
    }

    func removeLine(at index: Int) {
        leftSide.removeLine(at: index)
        rightSide.removeLine(at: index)
    }

    @discardableResult
    func remove(line: DiffLine) -> Bool {
        if let index = leftSide.index(of: line) {
            removeLine(at: index)
            return true
        }
        return false
    }

    func refreshSections() {
        sections = createSections()
        refreshSummary()
    }

    func refreshSummary() {
        summary.refresh(leftSide.lines)
    }
}
