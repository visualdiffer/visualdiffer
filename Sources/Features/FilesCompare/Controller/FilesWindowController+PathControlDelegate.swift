//
//  FilesWindowController+PathControlDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: PathControlDelegate {
    func pathControl(_ pathControl: PathControl, willContextMenu menu: NSMenu) {
        guard let url = pathControl.url else {
            return
        }
        menu.setSubmenu(
            NSMenu.appsMenuForFile(
                url,
                openAppAction: #selector(openWithApp),
                openOtherAppAction: #selector(openWithOther)
            ),
            for: menu.addItem(
                withTitle: NSLocalizedString("Open With", comment: ""),
                action: nil,
                keyEquivalent: ""
            )
        )
    }

    func pathControl(_: PathControl, chosenUrl _: URL) {
        // no need to check which path is changed (left or right) because
        // the binding value has already set sessionDiff.<left|right>Path
        reloadAllMove(toFirstDifference: false)
    }

    public func pathControl(_: NSPathControl, willDisplay openPanel: NSOpenPanel) {
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
    }

    public func pathControl(_ pathControl: PathControl, openWithApp app: URL) {
        guard let editorData = editorDataFrom(pathControl) else {
            return
        }
        openWith(app: app, attributes: [editorData])
    }

    public func pathControlOpenWithOtherApp(_ pathControl: PathControl) {
        guard let editorData = editorDataFrom(pathControl) else {
            return
        }
        openWithOtherApp(editorData)
    }

    func editorDataFrom(_ pathControl: PathControl) -> OpenEditorAttribute? {
        if pathControl === leftPanelView.pathView.pathControl {
            return leftView.editorData(sessionDiff)
        } else if pathControl === rightPanelView.pathView.pathControl {
            return rightView.editorData(sessionDiff)
        }
        fatalError("Unable to determine which editor data to return")
    }
}
