//
//  PreferredEditorPopupCell.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/12/12.
//  Copyright (c) 2012 visualdiffer.com
//

@objc class PreferredEditorPopupCell: NSPopUpButtonCell {
    override init(textCell stringValue: String, pullsDown pullDown: Bool) {
        super.init(textCell: stringValue, pullsDown: pullDown)
        setupPopUpCell()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupPopUpCell()
    }

    /**
     * Do not allow selecting the "Choose" item and the separator before it.
     * (Note that the Choose item can be chosen and an action will be sent, but the selection doesn't change to it.)
     */
    override func selectItem(at index: Int) {
        if (index + 2) <= numberOfItems {
            super.selectItem(at: index)
        }
    }

    private func setupPopUpCell() {
        removeAllItems()

        if let editorPath = UserDefaults.standard.string(forKey: NSMenu.preferredEditorPrefName) {
            addItem(withTitle: "")
            if let lastItem {
                fillPath(menuItem: lastItem, path: URL(filePath: editorPath))
            }
        } else {
            addItem(withTitle: NSLocalizedString("<None>", comment: ""))
        }
        menu?.addItem(NSMenuItem.separator())

        addItem(withTitle: NSLocalizedString("Choose...", comment: ""))
        if let lastItem {
            lastItem.action = #selector(choosePreferredEditor)
            lastItem.target = self
        }

        selectItem(at: 0)
    }

    func fillPath(menuItem item: NSMenuItem, path: URL) {
        guard let defaultAppPath = NSWorkspace.shared.urlForApplication(toOpen: path) else {
            return
        }
        // get the localized display name for the app
        if let values = try? defaultAppPath.resourceValues(forKeys: [URLResourceKey.localizedNameKey]),
           let defaultAppName = values.localizedName {
            item.title = defaultAppName
        } else {
            item.title = defaultAppPath.lastPathComponent
        }
        let image = NSWorkspace.shared.icon(forFile: path.osPath)
        image.size = NSSize(width: 16.0, height: 16.0)
        item.image = image
    }

    @objc func choosePreferredEditor(_: AnyObject) {
        let openPanel = NSOpenPanel()
            .openApplication(title: NSLocalizedString("Select Preferred Editor", comment: ""))

        if openPanel.runModal() == .OK {
            if let applicationPath = openPanel.urls.first?.osPath {
                UserDefaults.standard.setValue(
                    applicationPath,
                    forKey: NSMenu.preferredEditorPrefName
                )
                setupPopUpCell()
            }
        }
    }

    @objc func removePreferredEditor(_: AnyObject) {
        UserDefaults.standard.removeObject(forKey: NSMenu.preferredEditorPrefName)
        setupPopUpCell()
    }
}
