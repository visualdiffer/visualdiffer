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
        isClosed = true
        statusMessageTask?.cancel()
        removeObservers()
        if let document = document as? VDDocument {
            document.parentSession?.removeChildDocument(document)
        }

        leftPanelView.unbindControls()
        rightPanelView.unbindControls()
    }

    public func windowDidBecomeMain(_: Notification) {
        Self.switchMenu()

        reloadFilesIfNeeded()
    }

    public func window(_: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        [proposedOptions, .autoHideToolbar]
    }

    func resetStatusBarMessage() {
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
                // silent reload discard, the confirm above can be suppressed and the
                // reload would then throw the unsaved edits away without a word
                guard alertSaveDirtyFiles() else {
                    return
                }

                leftView.isDirty = false
                rightView.isDirty = false
                NotificationCenter.default.postFileUpdated(
                    leftPath: sessionDiff.leftPath,
                    rightPath: sessionDiff.rightPath
                )
                let message = if leftChanged, rightChanged {
                    NSLocalizedString("Reloaded left and right files", comment: "")
                } else if leftChanged {
                    NSLocalizedString("Reloaded left file", comment: "")
                } else {
                    NSLocalizedString("Reloaded right file", comment: "")
                }

                // the comparison refreshes the counters, the confirmation travels
                // with the request so it is shown by whichever run re-reads the file
                reloadRestoringPosition(statusMessage: message)
            }
        }
    }

    func showStatusMessage(_ message: String) {
        differenceCounters.stringValue = message

        statusMessageTask?.cancel()
        statusMessageTask = Task {
            let timeout = UserDefaults.standard.double(forKey: statusBarShowMessageTimeoutPrefName)

            // a cancelled wait means a newer message took over, the counters must stay away
            guard await (try? Task.sleep(for: .seconds(timeout))) != nil else {
                return
            }

            resetStatusBarMessage()
        }
    }
}
