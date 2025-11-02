//
//  TextFieldSelectionHolder.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

/*
 * Hold the selected text range set when the field loses focus.
 * If user clicks on attached popup menu while this field hasn't the focus
 * the field become first responder and selection is restored.
 */
class TextFieldSelectionHolder: NSTextField, NSMenuDelegate {
    private var selectionRange = NSRange(location: NSNotFound, length: 0)

    @objc func attachTo(popUpButton popup: NSPopUpButton) {
        popup.menu?.delegate = self
    }

    override func textShouldEndEditing(_ textObject: NSText) -> Bool {
        if let currentEditor = currentEditor() {
            selectionRange = currentEditor.selectedRange
        }
        return super.textShouldEndEditing(textObject)
    }

    func menuWillOpen(_: NSMenu) {
        // currentEditor is nil until the input box got focus (by clicking, on entering text)
        if currentEditor() == nil {
            window?.makeFirstResponder(self)
            restoreSelectionRange()
        }
    }

    private func restoreSelectionRange() {
        if selectionRange.location == NSNotFound {
            selectionRange = NSRange(location: stringValue.count, length: 0)
        }
        currentEditor()?.selectedRange = selectionRange
    }
}
