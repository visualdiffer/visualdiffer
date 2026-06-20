//
//  DiffResult+Lines.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

/// describes the context needed to edit selected diff lines
struct LineEditOperation {
    /// the diff result with all lines visible
    let all: DiffResult

    /// the diff result containing filtered lines, could be the same of all if no filter is applied
    let filtered: DiffResult

    /// the visible rows to copy or delete
    let rows: IndexSet

    /// the side used as the source of the edit
    let sourceSide: DisplaySide

    /// the active visibility mode used to keep the filtered diff result in sync
    let visibility: DiffLine.Visibility

    var sourceLines: [DiffLine] {
        filtered.diffSide(for: sourceSide).lines
    }

    var destinationLines: [DiffLine] {
        filtered.diffSide(for: sourceSide.opposite).lines
    }

    var destinationEOL: EndOfLine {
        all.diffSide(for: sourceSide.opposite).eol
    }

    var sourceAllSide: DiffSide {
        all.diffSide(for: sourceSide)
    }

    var destinationAllSide: DiffSide {
        all.diffSide(for: sourceSide.opposite)
    }
}

extension LineEditOperation {
    ///
    /// copy lines from source to destination
    /// - Parameters:
    ///   - useDestinationEOL: true when copied text should keep the destination line ending
    ///
    func copyLines(
        useDestinationEOL: Bool
    ) {
        let fromLeft = sourceSide == .left

        for row in rows.reversed() {
            let sourceLine = sourceLines[row]
            let destinationLine = destinationLines[row]

            if sourceLine.type == .missing {
                if visibility == .differences {
                    if fromLeft {
                        all.remove(line: sourceLine)
                    } else {
                        all.remove(line: destinationLine)
                    }
                }
                filtered.removeLine(at: row)
            } else {
                sourceLine.type = .matching
                sourceLine.hasIgnoredDifferences = false

                destinationLine.mode = .merged
                destinationLine.type = .matching
                destinationLine.hasIgnoredDifferences = false

                if useDestinationEOL,
                   destinationEOL != .mixed,
                   sourceLine.component.eol != .missing {
                    destinationLine.component = DiffLineComponent(text: sourceLine.text, eol: destinationEOL)
                } else {
                    destinationLine.component = sourceLine.component
                }

                // now lines match so remove them from view
                if visibility == .differences {
                    filtered.removeLine(at: row)
                }
            }
        }

        destinationAllSide.renumberLines()
    }

    ///
    /// delete lines from source
    ///
    func deleteLines() {
        let fromLeft = sourceSide == .left

        for row in rows.reversed() {
            let sourceLine = sourceLines[row]
            let destinationLine = destinationLines[row]

            // can't delete an already missing line
            if sourceLine.type == .missing {
                continue
            }

            if destinationLine.type == .missing {
                if visibility == .differences {
                    if fromLeft {
                        all.remove(line: sourceLine)
                    } else {
                        all.remove(line: destinationLine)
                    }
                }
                filtered.removeLine(at: row)
            } else {
                sourceLine.makeMissing()

                if fromLeft {
                    destinationLine.type = .added
                } else {
                    destinationLine.type = .deleted
                }

                // now lines differ so remove them from view
                if visibility == .matches {
                    filtered.removeLine(at: row)
                }
            }
        }

        sourceAllSide.renumberLines()
    }
}

extension DiffResult {
    static func justDifferentLines(_ result: DiffResult) -> DiffResult {
        let onlyMismatches = DiffResult(sections: DiffSection.compact(sections: result.sections))
        onlyMismatches.leftSide.eol = result.leftSide.eol
        onlyMismatches.rightSide.eol = result.rightSide.eol

        let leftSide = onlyMismatches.leftSide
        let rightSide = onlyMismatches.rightSide

        var lastInSection: DiffLine?
        // previous is used to group by difference type (eg. .added or .changed)
        var previous: DiffLine?

        for line in result.leftSide.lines {
            line.isSectionSeparator = false
            if line.type != .matching {
                if let previous,
                   line.type != previous.type {
                    previous.isSectionSeparator = true
                }
                leftSide.add(line: line)
                lastInSection = line
                previous = line
            } else {
                if let lastInSection {
                    lastInSection.isSectionSeparator = true
                }
                lastInSection = nil
            }
            line.filteredIndex = leftSide.lines.count - 1
        }

        for line in result.rightSide.lines {
            line.isSectionSeparator = false
            if line.type != .matching {
                if let previous,
                   line.type != previous.type {
                    previous.isSectionSeparator = true
                }
                rightSide.add(line: line)
                lastInSection = line
                previous = line
            } else {
                if let lastInSection {
                    lastInSection.isSectionSeparator = true
                }
                lastInSection = nil
            }
            line.filteredIndex = rightSide.lines.count - 1
        }

        return onlyMismatches
    }

    static func justMatchingLines(_ result: DiffResult) -> DiffResult {
        // difference sections are not visible
        let onlyMatches = DiffResult()
        onlyMatches.leftSide.eol = result.leftSide.eol
        onlyMatches.rightSide.eol = result.rightSide.eol

        let leftSide = onlyMatches.leftSide
        let rightSide = onlyMatches.rightSide

        var lastInSection: DiffLine?

        for line in result.leftSide.lines {
            line.isSectionSeparator = false
            if line.type == .matching {
                leftSide.add(line: line)
                lastInSection = line
            } else {
                if let lastInSection {
                    lastInSection.isSectionSeparator = true
                }
                lastInSection = nil
            }
            line.filteredIndex = leftSide.lines.count - 1
        }

        lastInSection = nil
        for line in result.rightSide.lines {
            line.isSectionSeparator = false
            if line.type == .matching {
                rightSide.add(line: line)
                lastInSection = line
            } else {
                if let lastInSection {
                    lastInSection.isSectionSeparator = true
                }
                lastInSection = nil
            }
            line.filteredIndex = rightSide.lines.count - 1
        }

        return onlyMatches
    }
}
