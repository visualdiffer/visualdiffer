//
//  FilesTableView+EditorData.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesTableView {
    func editorData(_ sessionDiff: SessionDiff) -> OpenEditorAttribute? {
        let path = switch side {
        case .left:
            sessionDiff.leftPath
        case .right:
            sessionDiff.rightPath
        }
        guard let path else {
            return nil
        }
        var editorData = OpenEditorAttribute(path: path)

        if let diffSide, selectedRow >= 0 {
            let subset = diffSide.lines[0 ... selectedRow]
            for line in subset.reversed() where line.type != .missing {
                editorData.lineNumber = line.number
                break
            }
        }
        return editorData
    }
}
