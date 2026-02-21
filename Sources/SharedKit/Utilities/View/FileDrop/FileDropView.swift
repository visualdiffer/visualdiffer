//
//  FileDropView.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/03/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Foundation
import Cocoa

@MainActor
protocol FileDropImageViewDelegate: AnyObject {
    // Return true if delegate update path
    func fileDropImageViewUpdatePath(_ view: FileDropView, paths: [URL]) -> Bool
}

class FileDropView: NSImageView {
    var filePath = "" {
        willSet {
            if filePath != newValue {
                updateDropImage(newValue)
            }
        }
    }

    var delegate: FileDropImageViewDelegate?

    var dragEntered = false
    var currentIcon: NSImage?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        imageScaling = .scaleProportionallyUpOrDown
        imageFrameStyle = .grayBezel
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        if dragEntered {
            NSColor.keyboardFocusIndicatorColor.set()
            let path = NSBezierPath()
            path.appendRoundedRect(bounds, xRadius: 5, yRadius: 5)
            path.fill()
        }

        super.draw(dirtyRect)
    }

    // MARK: Drag & Drop

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard

        guard pasteboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) != nil,
              let arr = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return []
        }

        highlightDropArea()
        updateDropImage(arr[0].path)

        return .copy
    }

    override func draggingExited(_: (any NSDraggingInfo)?) {
        if let currentIcon {
            image = currentIcon
        }
        removeDropAreaHighlight()
    }

    override func draggingEnded(_: any NSDraggingInfo) {
        removeDropAreaHighlight()
    }

    override func prepareForDragOperation(_: any NSDraggingInfo) -> Bool {
        true
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        guard pasteboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) != nil,
              let arr = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }

        if let delegate,
           !delegate.fileDropImageViewUpdatePath(self, paths: arr) {
            filePath = arr[0].path
        }
        return true
    }

    // MARK: Private Methods

    private func updateDropImage(_ path: String) {
        if FileManager.default.fileExists(atPath: path) {
            image = NSWorkspace.shared.icon(forFile: path)
        } else {
            image = NSImage(named: NSImage.cautionName)
        }
        if let image {
            image.size = NSSize(width: 100.0, height: 100.0)
        }
    }

    private func highlightDropArea() {
        if currentIcon == nil {
            currentIcon = image
        }
        dragEntered = true
        needsDisplay = true
    }

    private func removeDropAreaHighlight() {
        currentIcon = nil
        dragEntered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            if FileManager.default.fileExists(atPath: filePath) {
                // for some unknown (to me!!) reason mouseDown is called inside a different runloop context
                // preventing the sandbox to correctly "talk" with Finder so we must explicitly call `show` inside the main thread
                DispatchQueue.main.async {
                    NSWorkspace.shared.show(inFinder: [self.filePath])
                }
            }
        }
        super.mouseDown(with: event)
    }
}
