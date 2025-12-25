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

    func diff(
        leftText: String,
        rightText: String,
        options: Options = []
    ) {
        sections = []
        summary.reset()

        let leftLines = DiffLineComponent.splitLines(leftText)
        let rightLines = DiffLineComponent.splitLines(rightText)

        leftSide.eol = leftLines.detectEOL()
        rightSide.eol = rightLines.detectEOL()

        // swiftlint:disable force_cast
        let stringifier: (Any) -> String = {
            options.applyTransformations(component: $0 as! DiffLineComponent)
        }
        // swiftlint:enable force_cast

        let udiff = UnifiedDiff(originalLines: leftLines, revisedLines: rightLines, stringifier: stringifier)
        var script = udiff.diff_2(false)

        var leftIndex = 0
        var rightIndex = 0

        while let localScript = script {
            updateMatchingLines(
                leftCount: Int(localScript.line0),
                rightCount: Int(localScript.line1),
                leftLines: leftLines,
                rightLines: rightLines,
                leftIndex: &leftIndex,
                rightIndex: &rightIndex
            )

            let commonLines = Int(min(localScript.deleted, localScript.inserted))
            let diffLines = Int(localScript.deleted - localScript.inserted)

            var start = leftSide.lines.count

            // Create a new section to distinguish adjacent
            // .deleted from .added lines
            if commonLines > 0, localScript.deleted != localScript.inserted {
                sections.append(DiffSection(
                    start: start,
                    end: leftSide.lines.count + commonLines - 1
                ))
                start = leftSide.lines.count + commonLines
            }

            updateChangedLines(
                lineCount: commonLines,
                leftLines: leftLines,
                rightLines: rightLines,
                leftIndex: &leftIndex,
                rightIndex: &rightIndex
            )

            if diffLines > 0 {
                updateDeletedLines(
                    lineCount: diffLines,
                    leftLines: leftLines,
                    rightLines: rightLines,
                    leftIndex: &leftIndex,
                    rightIndex: &rightIndex
                )
            } else {
                updateAddedLines(
                    lineCount: -diffLines,
                    leftLines: leftLines,
                    rightLines: rightLines,
                    leftIndex: &leftIndex,
                    rightIndex: &rightIndex
                )
            }

            sections.append(DiffSection(
                start: start,
                end: leftSide.lines.count - 1
            ))

            script = localScript.link
        }

        updateMatchingLines(
            leftCount: leftLines.count,
            rightCount: rightLines.count,
            leftLines: leftLines,
            rightLines: rightLines,
            leftIndex: &leftIndex,
            rightIndex: &rightIndex
        )
    }

    // swiftlint:disable:next function_parameter_count
    private func updateMatchingLines(
        leftCount: Int,
        rightCount: Int,
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        leftIndex: inout Int,
        rightIndex: inout Int
    ) {
        summary.matching += leftCount - leftIndex

        while leftIndex < leftCount {
            let line = DiffLine(
                with: .matching,
                number: leftIndex + 1,
                component: leftLines[leftIndex]
            )
            leftSide.add(line: line)
            leftIndex += 1
        }

        while rightIndex < rightCount {
            let line = DiffLine(
                with: .matching,
                number: rightIndex + 1,
                component: rightLines[rightIndex]
            )
            rightSide.add(line: line)
            rightIndex += 1
        }
    }

    private func updateChangedLines(
        lineCount: Int,
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        leftIndex: inout Int,
        rightIndex: inout Int
    ) {
        // update changed lines
        summary.changed += lineCount

        for _ in 0 ..< lineCount {
            let leftLine = DiffLine(
                with: .changed,
                number: leftIndex + 1,
                component: leftLines[leftIndex]
            )
            leftSide.add(line: leftLine)

            let rightLine = DiffLine(
                with: .changed,
                number: rightIndex + 1,
                component: rightLines[rightIndex]
            )
            rightSide.add(line: rightLine)
            leftIndex += 1
            rightIndex += 1
        }
    }

    private func updateDeletedLines(
        lineCount: Int,
        leftLines: [DiffLineComponent],
        rightLines _: [DiffLineComponent],
        leftIndex: inout Int,
        rightIndex _: inout Int
    ) {
        summary.deleted += lineCount

        for _ in 0 ..< lineCount {
            let line = DiffLine(
                with: .deleted,
                number: leftIndex + 1,
                component: leftLines[leftIndex]
            )
            leftSide.add(line: line)
            leftIndex += 1
        }
        for _ in 0 ..< lineCount {
            let line = DiffLine.missingLine()
            rightSide.add(line: line)
        }
    }

    private func updateAddedLines(
        lineCount: Int,
        leftLines _: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        leftIndex _: inout Int,
        rightIndex: inout Int
    ) {
        for _ in 0 ..< lineCount {
            let line = DiffLine.missingLine()
            leftSide.add(line: line)
        }

        summary.added += lineCount

        for _ in 0 ..< lineCount {
            let line = DiffLine(
                with: .added,
                number: rightIndex + 1,
                component: rightLines[rightIndex]
            )
            rightSide.add(line: line)
            rightIndex += 1
        }
    }

    func insert(
        text: String,
        at startIndex: Int,
        side: DisplaySide
    ) {
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
    ) {
        var index = startIndex

        DiffLineComponent.enumerateLines(text: text) { component in
            let destLine = destination.lines[index]
            if destLine.type == .missing {
                destLine.component = component
                let otherLine = otherSide.lines[index]
                // simple comparison
                if otherLine.text == component.text {
                    otherLine.type = .matching
                    destLine.type = .matching
                } else {
                    otherLine.type = .changed
                    destLine.type = .changed
                }
            } else {
                // line numbers will be set correctly below
                destination.insert(DiffLine(with: type, number: 0, component: component), at: index)
                otherSide.insert(DiffLine.missingLine(), at: index)
            }
            index += 1
        }
        destination.renumberLines()
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
