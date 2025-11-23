//
//  DiffResult+Lines.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension DiffResult {
    ///
    /// Copy lines from source to destination.
    /// - Parameters:
    ///   - all: the DiffResult with all lines visible
    ///   - current: the DiffResult currently used, contains the filtered lines, could be the same of allResult if no filter is applied
    ///   - rows: the rows to copy
    ///   - source: the source side used to copy line
    ///   - visibility: used to update the filtered DiffResult
    ///
    static func copyLines(
        all: DiffResult,
        current: DiffResult,
        rows: IndexSet,
        source side: DisplaySide,
        visibility: DiffLine.Visibility
    ) {
        let fromLeft = side == .left
        let srcLines = fromLeft ? current.leftSide.lines : current.rightSide.lines
        let destLines = fromLeft ? current.rightSide.lines : current.leftSide.lines

        for row in rows.reversed() {
            let srcLine = srcLines[row]
            let destLine = destLines[row]

            if srcLine.type == .missing {
                if visibility == .differences {
                    if fromLeft {
                        all.remove(line: srcLine)
                    } else {
                        all.remove(line: destLine)
                    }
                }
                current.removeLine(at: row)
            } else {
                srcLine.type = .matching

                destLine.mode = .merged
                destLine.type = .matching
                destLine.component = srcLine.component

                // now lines match so remove them from view
                if visibility == .differences {
                    current.removeLine(at: row)
                }
            }
        }

        let diffSide = fromLeft ? all.rightSide : all.leftSide
        diffSide.renumberLines()
    }

    ///
    /// Delete lines from source.
    /// - Parameters:
    ///   - all: the DiffResult with all lines visible
    ///   - current: the DiffResult currently used, contains the filtered lines, could be the same of allDiffResult if no filter is applied
    ///   - rows: the rows to delete
    ///   - side: the side used to delete lines
    ///   - visibility: used to update the filtered DiffResult
    ///
    static func deleteLines(
        all: DiffResult,
        current: DiffResult,
        rows: IndexSet,
        side: DisplaySide,
        visibility: DiffLine.Visibility
    ) {
        let fromLeft = side == .left
        let srcLines = fromLeft ? current.leftSide.lines : current.rightSide.lines
        let destLines = fromLeft ? current.rightSide.lines : current.leftSide.lines

        for row in rows.reversed() {
            let srcLine = srcLines[row]
            let destLine = destLines[row]

            // can't delete an already missing line
            if srcLine.type == .missing {
                continue
            }

            if destLine.type == .missing {
                if visibility == .differences {
                    if fromLeft {
                        all.remove(line: srcLine)
                    } else {
                        all.remove(line: destLine)
                    }
                }
                current.removeLine(at: row)
            } else {
                srcLine.makeMissing()

                if fromLeft {
                    destLine.type = .added
                } else {
                    destLine.type = .deleted
                }

                // now lines differ so remove them from view
                if visibility == .matches {
                    current.removeLine(at: row)
                }
            }
        }
        let destAllLinesStatus = fromLeft ? all.leftSide : all.rightSide

        destAllLinesStatus.renumberLines()
    }

    static func justDifferentLines(_ result: DiffResult) -> DiffResult {
        let onlyMismatches = DiffResult(sections: DiffSection.compact(sections: result.sections))

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
        // Difference sections are not visible
        let onlyMatches = DiffResult()

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
