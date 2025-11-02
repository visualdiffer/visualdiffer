//
//  DiffResult.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

class DiffResult {
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
        rightText: String
    ) {
        leftSide.setupEOL(text: leftText)
        rightSide.setupEOL(text: rightText)

        sections = []
        summary.reset()

        let leftLines = splitLines(leftText)
        let rightLines = splitLines(rightText)

        let udiff = UnifiedDiff(originalLines: leftLines, revisedLines: rightLines)
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
        leftLines: [String],
        rightLines: [String],
        leftIndex: inout Int,
        rightIndex: inout Int
    ) {
        summary.matching += leftCount - leftIndex

        while leftIndex < leftCount {
            let line = DiffLine(
                with: .matching,
                number: leftIndex + 1,
                text: leftLines[leftIndex]
            )
            leftSide.add(line: line)
            leftIndex += 1
        }

        while rightIndex < rightCount {
            let line = DiffLine(
                with: .matching,
                number: rightIndex + 1,
                text: rightLines[rightIndex]
            )
            rightSide.add(line: line)
            rightIndex += 1
        }
    }

    private func updateChangedLines(
        lineCount: Int,
        leftLines: [String],
        rightLines: [String],
        leftIndex: inout Int,
        rightIndex: inout Int
    ) {
        // update changed lines
        summary.changed += lineCount

        for _ in 0 ..< lineCount {
            let leftLine = DiffLine(
                with: .changed,
                number: leftIndex + 1,
                text: leftLines[leftIndex]
            )
            leftSide.add(line: leftLine)

            let rightLine = DiffLine(
                with: .changed,
                number: rightIndex + 1,
                text: rightLines[rightIndex]
            )
            rightSide.add(line: rightLine)
            leftIndex += 1
            rightIndex += 1
        }
    }

    private func updateDeletedLines(
        lineCount: Int,
        leftLines: [String],
        rightLines _: [String],
        leftIndex: inout Int,
        rightIndex _: inout Int
    ) {
        summary.deleted += lineCount

        for _ in 0 ..< lineCount {
            let line = DiffLine(
                with: .deleted,
                number: leftIndex + 1,
                text: leftLines[leftIndex]
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
        leftLines _: [String],
        rightLines: [String],
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
                text: rightLines[rightIndex]
            )
            rightSide.add(line: line)
            rightIndex += 1
        }
    }

    private func splitLines(_ text: String) -> [String] {
        var lines: [String] = []
        text.enumerateLines { line, _ in
            lines.append(line)
        }

        return lines
    }

    func insert(
        text: String,
        at startIndex: Int,
        side: DisplaySide
    ) {
        var src: [DiffLine]
        var dest: [DiffLine]
        var type: DiffChangeType

        switch side {
        case .left:
            src = leftSide.lines
            dest = rightSide.lines
            type = .deleted
        case .right:
            src = rightSide.lines
            dest = leftSide.lines
            type = .added
        }

        var index = startIndex

        text.enumerateLines { line, _ in
            let srcLS = src[index]
            if srcLS.type == .missing {
                srcLS.text = line
                let destLS = dest[index]
                // simple comparison
                if destLS.text == line {
                    destLS.type = .matching
                    srcLS.type = .matching
                } else {
                    destLS.type = .changed
                    srcLS.type = .changed
                }
            } else {
                // line numbers will be set correctly below
                src.insert(DiffLine(with: type, number: 0, text: line), at: index)
                dest.insert(DiffLine.missingLine(), at: index)
            }
            index += 1
        }
        switch side {
        case .left:
            leftSide.renumberLines()
        case .right:
            rightSide.renumberLines()
        }
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
