//
//  RSVerticallyCenteredTextFieldCell.swift
//  VisualDiffer
//
//  Created by Daniel Jalkut on 6/17/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//

class RSVerticallyCenteredTextFieldCell: NSTextFieldCell {
    private var isEditingOrSelecting = false

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        // Get the parent's idea of where we should draw
        var newRect = super.drawingRect(forBounds: rect)

        // When the text field is being
        // edited or selected, we have to turn off the magic because it screws up
        // the configuration of the field editor.  We sneak around this by
        // intercepting selectWithFrame and editWithFrame and sneaking a
        // reduced, centered rect in at the last minute.
        if !isEditingOrSelecting {
            // Get our ideal size for current text
            let textSize = cellSize(forBounds: rect)

            // Center that in the proposed rect
            let heightDelta = newRect.size.height - textSize.height
            if heightDelta > 0 {
                newRect.size.height -= heightDelta
                newRect.origin.y += (heightDelta / 2)
            }
        }

        return newRect
    }
}
