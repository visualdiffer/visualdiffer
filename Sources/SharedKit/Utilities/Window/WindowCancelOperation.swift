//
//  WindowCancelOperation.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/01/14.
//  Copyright (c) 2014 visualdiffer.com
//

class WindowCancelOperation: NSWindow {
    private static let maxContentSize = NSSize(width: 1100, height: 600)
    private static let minWindowSize = NSSize(width: 480, height: 400)
    private static let minContentSize = NSSize(width: 300, height: 200)
    // a window opened for the first time never covers more than this fraction of the visible screen
    private static let maxScreenFillRatio = 0.75

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

    @objc
    static func createWindow() -> WindowCancelOperation {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]

        let window = WindowCancelOperation(
            contentRect: NSRect(origin: .zero, size: defaultContentSize()),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.hasShadow = true
        window.isReleasedWhenClosed = true
        window.allowsToolTipsWhenApplicationIsInactive = true
        window.autorecalculatesKeyViewLoop = false
        window.setIsVisible(false)
        window.minSize = minWindowSize
        window.contentMinSize = minContentSize
        window.contentView?.autoresizingMask = [.width, .height]

        // a fixed origin lands on a different screen spot depending on the screen size,
        // center() keeps the window above the visual center as the fixed origin used to do
        window.center()

        return window
    }

    private static func defaultContentSize() -> NSSize {
        guard let visibleFrame = NSScreen.main?.visibleFrame else {
            return maxContentSize
        }

        return NSSize(
            width: min(maxContentSize.width, visibleFrame.width * maxScreenFillRatio),
            height: min(maxContentSize.height, visibleFrame.height * maxScreenFillRatio)
        )
    }
}
