//
//  DiffResult+Section.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension DiffResult {
    func createSections() -> [DiffSection] {
        let lines = leftSide.lines
        var sections = [DiffSection]()
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if line.type != .matching {
                // find end
                let start = i
                let currStatus = line.type
                i += 1
                i = lines[i...].firstIndex { $0.type != currStatus } ?? lines.count
                i -= 1
                sections.append(DiffSection(start: start, end: i))
            }

            i += 1
        }

        return sections
    }

    func findNextSection(
        by position: Int,
        wrapAround: Bool,
        didWrap: inout Bool
    ) -> DiffSection? {
        var sectionFound: DiffSection?
        var sectionIndex = 0

        while sectionIndex < sections.count {
            let section = sections[sectionIndex]
            sectionFound = section

            if section.start > position {
                break
            }
            sectionIndex += 1
        }

        if sectionIndex < sections.count {
            didWrap = false
            return sectionFound
        }
        if wrapAround {
            sectionFound = sections.isEmpty ? nil : sections[0]
            didWrap = sectionFound != nil
        }
        return sectionFound
    }

    func findPrevSection(
        by position: Int,
        wrapAround: Bool,
        didWrap: inout Bool
    ) -> DiffSection? {
        var sectionFound: DiffSection?
        var sectionIndex = sections.count - 1

        while sectionIndex >= 0 {
            let section = sections[sectionIndex]
            sectionFound = section

            if section.end < position {
                break
            }
            sectionIndex -= 1
        }

        if sectionIndex >= 0 {
            didWrap = false
            return sectionFound
        }
        if wrapAround {
            sectionFound = sections.last
            didWrap = sectionFound != nil
        }
        return sectionFound
    }

    func findSection(with line: Int) -> DiffSection? {
        sections.first { $0.start <= line && line <= $0.end }
    }

    func findSectionIndexSet(with index: Int) -> IndexSet? {
        guard index >= 0,
              let range = findSection(with: index)?.range else {
            return nil
        }

        return IndexSet(integersIn: range)
    }

    func resetSectionSeparators() {
        for (index, leftLine) in leftSide.lines.enumerated() {
            leftLine.isSectionSeparator = false
            let rightLine = rightSide.lines[index]
            rightLine.isSectionSeparator = false
        }
    }

    func findAdjacentSections(from index: Int) -> IndexSet? {
        guard index >= 0 else {
            return nil
        }
        var section = findSection(with: index)

        if section == nil {
            return nil
        }
        var indexes = IndexSet()

        // Store this value because section is overwritten to find previous sections
        // swiftlint:disable:next force_unwrapping
        var endRow = section!.end

        repeat {
            if let tmpSection = section {
                indexes.insert(integersIn: tmpSection.range)
                section = findSection(with: tmpSection.start - 1)
            }
        } while section != nil

        while let section = findSection(with: endRow + 1) {
            indexes.insert(integersIn: section.range)
            endRow = section.end
        }

        return indexes
    }
}
