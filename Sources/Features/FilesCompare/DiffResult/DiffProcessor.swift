//
//  DiffProcessor.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/05/26.
//  Copyright (c) 2026 visualdiffer.com
//

struct DiffProcessor {
    let leftLines: [DiffLineComponent]
    let rightLines: [DiffLineComponent]
    let options: DiffResult.Options

    private(set) var leftSide = DiffSide()
    private(set) var rightSide = DiffSide()
    private(set) var sections = [DiffSection]()
    private(set) var summary = DiffSummary()

    private var leftIndex = 0
    private var rightIndex = 0

    init(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        options: DiffResult.Options
    ) {
        self.leftLines = leftLines
        self.rightLines = rightLines
        self.options = options
    }

    mutating func process(changes: UDiffChange?) {
        sections.removeAll(keepingCapacity: true)
        summary.reset()

        leftSide.eol = leftLines.detectEOL()
        rightSide.eol = rightLines.detectEOL()

        leftIndex = 0
        rightIndex = 0

        var script = changes

        while let localScript = script {
            updateMatchingLines(
                leftCount: Int(localScript.line0),
                rightCount: Int(localScript.line1)
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
                lineCount: commonLines
            )

            if diffLines > 0 {
                updateDeletedLines(
                    lineCount: diffLines
                )
            } else {
                updateAddedLines(
                    lineCount: -diffLines
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
            rightCount: rightLines.count
        )
    }

    private mutating func updateMatchingLines(
        leftCount: Int,
        rightCount: Int
    ) {
        summary.matching += leftCount - leftIndex
        let startIndex = leftSide.lines.count

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

        updateIgnored(from: startIndex)
    }

    private mutating func updateIgnored(from startIndex: Int) {
        if options.isEmpty {
            return
        }
        for i in startIndex ..< leftSide.lines.count {
            let leftLine = leftSide.lines[i]
            let rightLine = rightSide.lines[i]

            if options.containsIgnoreFor(differenceBetween: leftLine.component, and: rightLine.component) {
                leftLine.hasIgnoredDifferences = true
                rightLine.hasIgnoredDifferences = true
                summary.ignored += 1
            }
        }
    }

    private mutating func updateChangedLines(
        lineCount: Int
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

    private mutating func updateDeletedLines(
        lineCount: Int
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

    private mutating func updateAddedLines(
        lineCount: Int
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
}
