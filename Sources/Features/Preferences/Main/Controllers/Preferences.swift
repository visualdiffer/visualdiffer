//
//  Preferences.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class Preferences: BasePreferences {
    private var loadedTabs = Set<NSToolbarItem.Identifier>()

    // Must have same values used for TabViewItem identifiers
    override var toolbarIdentifiers: [NSToolbarItem.Identifier] {
        [
            .generalPrefs,
            .fontsPrefs,
            .textPrefs,
            .folderPrefs,
            .confirmationsPrefs,
            .keyboardPrefs,
            .trustedPathsPrefs,
        ]
    }

    // MARK: - Toolbar creation

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        var toolbarItem: NSToolbarItem?

        if itemIdentifier == .generalPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("General", comment: ""),
                tooltip: NSLocalizedString("General Settings", comment: ""),
                image: NSImage.imageSymbolCompat(NSImage.preferencesGeneralName),
                target: self,
                action: #selector(selectPrefTab)
            )
        } else if itemIdentifier == .fontsPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Fonts", comment: ""),
                tooltip: NSLocalizedString("Change Fonts", comment: ""),
                image: NSImage.imageSymbolCompat(NSImage.fontPanelName),
                target: self,
                action: #selector(selectPrefTab)
            )
        } else if itemIdentifier == .textPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Text", comment: ""),
                tooltip: NSLocalizedString("Text Differences", comment: ""),
                image: NSImage.imageSymbolCompat("prefs_text"),
                target: self,
                action: #selector(selectPrefTab)
            )
        } else if itemIdentifier == .trustedPathsPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Trusted Paths", comment: ""),
                tooltip: NSLocalizedString("Paths granted access to VisualDiffer", comment: ""),
                image: NSImage.imageSymbolCompat("prefs_paths"),
                target: self,
                action: #selector(selectPrefTab)
            )
        } else if itemIdentifier == .folderPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Folder", comment: ""),
                tooltip: NSLocalizedString("Folder View", comment: ""),
                image: NSImage.imageSymbolCompat("prefs_folder"),
                target: self,
                action: #selector(selectPrefTab)
            )
        } else if itemIdentifier == .confirmationsPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Confirmations", comment: ""),
                tooltip: NSLocalizedString("Confirmations and Warnings", comment: ""),
                image: NSImage.imageSymbolCompat("prefs_confirmations"),
                target: self,
                action: #selector(selectPrefTab)
            )
        } else if itemIdentifier == .keyboardPrefs {
            toolbarItem = NSToolbarItem(
                identifier: itemIdentifier,
                label: NSLocalizedString("Keyboard", comment: ""),
                tooltip: NSLocalizedString("Keyboard shortcuts", comment: ""),
                image: NSImage.imageSymbolCompat("prefs_keyboard"),
                target: self,
                action: #selector(selectPrefTab)
            )
        }
        return toolbarItem
    }

    func tabView(_: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        guard let tabViewItem,
              let identifier = tabViewItem.identifier as? NSToolbarItem.Identifier else {
            return
        }

        if loadedTabs.contains(identifier) {
            return
        }
        loadedTabs.insert(identifier)

        if identifier == .generalPrefs {
            tabViewItem.view = GeneralPreferencesPanel(frame: .zero)
        } else if identifier == .fontsPrefs {
            tabViewItem.view = FontPreferencesPanel(frame: .zero)
        } else if identifier == .textPrefs {
            tabViewItem.view = TextPreferencesPanel(frame: .zero)
        } else if identifier == .trustedPathsPrefs {
            tabViewItem.view = TrustedPathsPreferencesPanel(frame: .zero)
        } else if identifier == .folderPrefs {
            tabViewItem.view = FolderPreferencesPanel(frame: .zero)
        } else if identifier == .confirmationsPrefs {
            tabViewItem.view = ConfirmationsPreferencesPanel(frame: .zero)
        } else if identifier == .keyboardPrefs {
            tabViewItem.view = KeyboardPreferencesPanel(frame: .zero)
        }
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)

        if let dataSource = tabViewItem?.view as? PreferencesPanelDataSource {
            dataSource.reloadData()
        }
    }
}

private extension NSToolbarItem.Identifier {
    static let generalPrefs = Self("general")
    static let fontsPrefs = Self("fonts")
    static let textPrefs = Self("text")
    static let trustedPathsPrefs = Self("trustedPaths")
    static let folderPrefs = Self("folder")
    static let confirmationsPrefs = Self("confirmations")
    static let keyboardPrefs = Self("keyboard")
}
