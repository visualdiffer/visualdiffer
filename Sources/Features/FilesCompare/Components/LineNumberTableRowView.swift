//
//  LineNumberTableRowView.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

class LineNumberTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        guard let selectionColor = CommonPrefs.shared.fileColor(.selectedRow)?.background else {
            return
        }

        // if the enclosing tableview has the focus use the color without modification
        if isEmphasized {
            selectionColor.set()
        } else {
            (selectionColor.shadow(withLevel: 0.25) ?? selectionColor).set()
        }
        dirtyRect.fill()
    }
}
