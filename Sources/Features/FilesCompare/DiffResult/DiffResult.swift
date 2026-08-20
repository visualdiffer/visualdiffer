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

    // the options the comparison ran with, the editing paths must classify a pair
    // of lines with the same equality the engine used
    let options: Options

    init(options: Options = []) {
        self.options = options
    }

    convenience init(sections: [DiffSection], options: Options) {
        self.init(options: options)

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
        rightText: String
    ) {
        diff(
            leftLines: DiffLineComponent.splitLines(leftText),
            rightLines: DiffLineComponent.splitLines(rightText)
        )
    }

    func diff(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent]
    ) {
        let changes = SequenceDiff.changes(
            left: leftLines.map { options.key(for: $0) },
            right: rightLines.map { options.key(for: $0) }
        )

        var processor = DiffProcessor(
            leftLines: leftLines,
            rightLines: rightLines,
            options: options
        )
        processor.process(changes: changes)

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

        DiffLineComponent.enumerateLines(text: text) { pastedComponent in
            // adds missing lines to both diff sides to accommodate insertion at the specified index
            if index == destination.lines.count {
                destination.insert(DiffLine.missingLine(), at: index)
                otherSide.insert(DiffLine.missingLine(), at: index)
            }
            let component = self.adoptingEOL(of: destination, for: pastedComponent)
            let destLine = destination.lines[index]
            if destLine.type == .missing {
                destLine.component = component
                let otherLine = otherSide.lines[index]

                if self.matches(otherLine.component, component) {
                    otherLine.type = .matching
                    destLine.type = .matching

                    let hasIgnored = self.options.containsIgnoreFor(
                        differenceBetween: otherLine.component,
                        and: component
                    )
                    otherLine.hasIgnoredDifferences = hasIgnored
                    destLine.hasIgnoredDifferences = hasIgnored
                } else {
                    if otherLine.type == .missing {
                        destLine.type = type
                    } else {
                        otherLine.type = .changed
                        destLine.type = .changed

                        InlineDiff.apply(to: otherLine, and: destLine, options: self.options)
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

    // a weaker comparison than the engine one would show a pair as matching while the
    // two lines differ, and the difference would appear out of nowhere on the next comparison
    private func matches(_ leftLine: DiffLineComponent, _ rightLine: DiffLineComponent) -> Bool {
        options.key(for: leftLine) == options.key(for: rightLine)
    }

    // pasted text always carries a unix line ending, the destination one must win,
    // as it does when copying lines between the two sides
    private func adoptingEOL(
        of destination: DiffSide,
        for component: DiffLineComponent
    ) -> DiffLineComponent {
        guard destination.eol != .mixed,
              destination.eol != .missing,
              component.eol != .missing else {
            return component
        }

        return DiffLineComponent(text: component.text, eol: destination.eol)
    }
}
