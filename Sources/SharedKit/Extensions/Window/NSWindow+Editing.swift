//
//  NSWindow+Editing.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/12/15.
//  Copyright (c) 2015 visualdiffer.com
//

// Copied from https://red-sweater.com/blog/229/stay-responsive
// see http://stackoverflow.com/questions/14049913/update-property-bound-from-text-field-without-needing-to-press-enter
// This category allows to update text field's bindings without pressing enter or changing first responder

extension NSWindow {
    func endEditing() {
        // Save the current first responder, respecting the fact
        // that it might conceptually be the delegate of the
        // field editor that is "first responder."
        var oldFirstResponder: NSResponder?

        if let textView = firstResponder as? NSTextView,
           textView.isFieldEditor {
            // A field editor's delegate is the view we're editing
            if let responder = textView.delegate as? NSResponder {
                oldFirstResponder = responder
            }
        }
        // Gracefully end all editing in our window (from Erik Buck).
        // This will cause the user's changes to be committed.
        if makeFirstResponder(self) {
            // All editing is now ended and delegate messages sent etc.
        } else {
            // For some reason the text object being edited will
            // not resign first responder status so force an
            /// end to editing anyway
            endEditing(for: nil)
        }

        // If we had a first responder before, restore it
        if let oldFirstResponder {
            makeFirstResponder(oldFirstResponder)
        }
    }
}
