//
//  WindowCancelOperation.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/01/14.
//  Copyright (c) 2014 visualdiffer.com
//

class WindowCancelOperation: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        // override NSWindow.cancelOperation() instead of NSWindowController.cancelOperation()
        // because on NSWindowController the standard beep is played
        // (unless overriding first responder's cancelOperation like NSTableView)

        // if sender is nil (eg when on search fields) doesn't close window/app
        // if window is full screen doesn't close window/app
        if let sender,
           CommonPrefs.shared.bool(forKey: .escCloseWindow),
           !styleMask.contains(.fullScreen) {
            let docs = NSDocumentController.shared.documents

            if docs.count == 1 {
                NSApp.terminate(sender)
            } else {
                performClose(sender)
            }
        } else {
            super.cancelOperation(sender)
        }
    }

    @objc static func createWindow() -> WindowCancelOperation {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]

        let window = WindowCancelOperation(
            contentRect: NSRect(x: 500, y: 600, width: 1100, height: 600),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.hasShadow = true
        window.isReleasedWhenClosed = true
        window.allowsToolTipsWhenApplicationIsInactive = true
        window.autorecalculatesKeyViewLoop = false
        window.setIsVisible(false)
        window.minSize = NSSize(width: 480, height: 400)
        window.contentMinSize = NSSize(width: 300, height: 200)
        window.contentView?.autoresizingMask = [.width, .height]

        return window
    }
}
