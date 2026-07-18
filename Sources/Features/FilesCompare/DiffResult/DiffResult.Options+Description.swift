//
//  DiffResult.Options+Description.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/07/26.
//  Copyright (c) 2026 visualdiffer.com
//

extension DiffResult.Options: CustomStringConvertible {
    var description: String {
        if isEmpty {
            return NSLocalizedString("Exact match", comment: "")
        }
        var parts = [String]()

        if contains(.ignoreLineEndings) {
            parts.append(NSLocalizedString("Line endings", comment: ""))
        }

        let spaces = spacesDescription
        if !spaces.isEmpty {
            parts.append(spaces)
        }

        if contains(.ignoreCharacterCase) {
            parts.append(NSLocalizedString("Case", comment: ""))
        }

        let prefix = NSLocalizedString("Ignore:", comment: "")
        return prefix + " " + parts.joined(separator: " · ")
    }

    private var spacesDescription: String {
        var spaceParts = [String]()

        if contains(.ignoreLeadingWhitespaces) {
            spaceParts.append(NSLocalizedString("Lead", comment: ""))
        }
        if contains(.ignoreTrailingWhitespaces) {
            spaceParts.append(NSLocalizedString("Trail", comment: ""))
        }
        if contains(.ignoreInternalWhitespaces) {
            spaceParts.append(NSLocalizedString("Internal", comment: ""))
        }

        if spaceParts.isEmpty {
            return ""
        }

        let spacesLabel = NSLocalizedString("Spaces", comment: "")
        return spacesLabel + " (" + spaceParts.joined(separator: "+") + ")"
    }
}
