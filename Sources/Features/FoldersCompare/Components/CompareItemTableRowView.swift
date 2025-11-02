//
//  CompareItemTableRowView.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/10/14.
//  Copyright (c) 2014 visualdiffer.com
//

class CompareItemTableRowView: NSTableRowView {
    @objc var item: CompareItem?

    override func drawSelection(in dirtyRect: NSRect) {
        guard let selectionColor = CommonPrefs.shared.folderColor(.selectedRow)?.background else {
            return
        }

        // if the enclosing tableview has the focus use the color without modification
        if isEmphasized {
            selectionColor.set()
        } else {
            selectionColor.blended(withFraction: 0.3, of: NSColor.gray)?.set()
        }
        dirtyRect.fill()
    }

    // http://stackoverflow.com/questions/11127764/how-to-customize-disclosure-cell-in-view-based-nsoutlineview
    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)

        guard let item,
              let button = subview as? NSButton else {
            return
        }

        // hide disclosure button on invalid files
        if button.identifier == NSOutlineView.disclosureButtonIdentifier {
            if !item.isValidFile {
                button.image = NSImage(size: NSSize(width: 16, height: 16))
            }
        }
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        // Change the background style because when row is selected the outline cell
        // (eg disclosure triangle) is drawn white but we want it uses the
        // same style used when it is not selected
        .normal
    }
}
