//
//  FilesWindowController+NSWindowDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

// The amount of seconds the message text stay visible on status bar before restoring the counters
let statusBarShowMessageTimeoutPrefName = "filesStatusBarShowMessageTimeout"

extension FilesWindowController: NSWindowDelegate {
    public func windowWillClose(_: Notification) {
        removeObservers()
        if let document = document as? VDDocument {
            document.parentSession?.removeChildDocument(document)
        }
    }

    public func windowDidBecomeMain(_: Notification) {
        Self.switchMenu()

        reloadFilesIfNeeded()
    }

    public func window(_: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        [proposedOptions, .autoHideToolbar]
    }

    @objc func resetStatusBarMessage(_: AnyObject?) {
        guard let diffResult else {
            return
        }
        differenceCounters.update(counters: DiffCountersItem.diffCounter(withResult: diffResult))
    }

    func reloadFilesIfNeeded() {
        guard let resolvedLeftPath,
              let resolvedRightPath else {
            return
        }

        let leftChanged = leftPanelView.fileInfoBar.updateFileAttrsFromPath(resolvedLeftPath.osPath)
        let rightChanged = rightPanelView.fileInfoBar.updateFileAttrsFromPath(resolvedRightPath.osPath)

        if leftChanged || rightChanged {
            if askReload() {
                leftView.isDirty = false
                rightView.isDirty = false
                reload(nil)
                if leftChanged, rightChanged {
                    differenceCounters.stringValue = NSLocalizedString("Reloaded left and right files", comment: "")
                } else if leftChanged {
                    differenceCounters.stringValue = NSLocalizedString("Reloaded left file", comment: "")
                } else if rightChanged {
                    differenceCounters.stringValue = NSLocalizedString("Reloaded right file", comment: "")
                }
                perform(
                    #selector(resetStatusBarMessage),
                    with: nil,
                    afterDelay: UserDefaults.standard.double(forKey: statusBarShowMessageTimeoutPrefName)
                )
            }
        }
    }
}
