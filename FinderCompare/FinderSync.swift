//
//  FinderSync.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/01/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Cocoa
import FinderSync
import ScriptingBridge
import os.log

final class FinderSync: FIFinderSync, SBApplicationDelegate {
    private let workspaceCenter = NSWorkspace.shared.notificationCenter
    private var mountObserver: NSObjectProtocol?
    private var unmountObserver: NSObjectProtocol?

    static let subsystem = Bundle.main.bundleIdentifier ?? "visualdiffer.FinderSync"
    static let general = Logger(subsystem: subsystem, category: "General")

    override init() {
        super.init()

        updateDirectoryURLs()
        observeVolumeChanges()
    }

    deinit {
        if let mountObserver {
            workspaceCenter.removeObserver(mountObserver)
        }
        if let unmountObserver {
            workspaceCenter.removeObserver(unmountObserver)
        }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer:
            createContextMenu()
        default:
            nil
        }
    }

    // MARK: - Menu actions

    @objc private func selectItem(_ sender: Any?) {
        guard let selectedURL = selectedURL(),
              let tag = (sender as? NSMenuItem)?.tag,
              let side = DisplaySide(rawValue: tag) else {
            return
        }
        UserDefaults.standard.setCompareItem(url: selectedURL, side: side)
    }

    @objc private func compareWithSaved(_: Any?) {
        guard let compareItem = try? UserDefaults.standard.compareItem(),
              let selectedURL = selectedURL() else {
            return
        }
        UserDefaults.standard.removeCompareItem()
        let sides = compareItem.sidePlacement(for: selectedURL)
        handleCompare(leftURL: sides.left, rightURL: sides.right)
    }

    @objc private func compareSelected(_: Any?) {
        guard let selectedURLs = FIFinderSyncController.default().selectedItemURLs(),
              selectedURLs.count == 2,
              let leftItem = try? FinderCompareItem(url: selectedURLs[0], side: .left),
              let rightItem = try? FinderCompareItem(url: selectedURLs[1], side: .right),
              leftItem.type == rightItem.type else {
            return
        }
        handleCompare(leftURL: leftItem.url, rightURL: rightItem.url)
    }

    @objc private func clearSelection(_: Any?) {
        UserDefaults.standard.removeCompareItem()
    }

    // MARK: - Menu creation methods

    private func createContextMenu() -> NSMenu? {
        let submenu = NSMenu(title: "")

        let compareItem = try? UserDefaults.standard.compareItem()
        let canShowMenu = if let compareItem {
            appendCompareSavedMenuItems(submenu: submenu, compareItem: compareItem)
        } else if let comparableItems = comparableSelectedItems() {
            appendCompareSelectedMenuItems(
                submenu: submenu,
                items: comparableItems
            )
        } else {
            appendSelectOnSideMenuItems(submenu: submenu)
        }
        guard canShowMenu else {
            return nil
        }
        let rootItem = NSMenuItem(
            title: NSLocalizedString("VisualDiffer", comment: ""),
            action: nil,
            keyEquivalent: ""
        )

        rootItem.submenu = submenu
        let menu = NSMenu(title: "")
        menu.addItem(rootItem)

        return menu
    }

    private func comparableSelectedItems() -> (left: FinderCompareItem, right: FinderCompareItem)? {
        guard let selectedURLs = FIFinderSyncController.default().selectedItemURLs(),
              selectedURLs.count == 2,
              let leftItem = try? FinderCompareItem(url: selectedURLs[0], side: .left),
              let rightItem = try? FinderCompareItem(url: selectedURLs[1], side: .right),
              leftItem.type == rightItem.type else {
            return nil
        }

        return (left: leftItem, right: rightItem)
    }

    private func createMenuItem(
        title: String,
        action: Selector?,
        tag: Int = 0
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: ""
        )
        item.target = self
        item.tag = tag

        return item
    }

    private func appendCompareSavedMenuItems(submenu: NSMenu, compareItem: FinderCompareItem) -> Bool {
        if let url = selectedURL(),
           let selectedFileType = try? FileType(url: url) {
            let urls = compareItem.sidePlacement(for: url)
            let item = createMenuItem(
                title: selectedFileType.compareTitle(leftURL: urls.left, rightURL: urls.right),
                action: #selector(compareWithSaved(_:))
            )
            item.isEnabled = selectedFileType == compareItem.type
            submenu.addItem(item)
        }
        // the NSMenuItem.separator() doesn't show the horizontal line on FinderSync
        // so I prefer to adhere to the absurd Apple decisions
        submenu.addItem(createMenuItem(
            title: NSLocalizedString("Clear", comment: ""),
            action: #selector(clearSelection(_:))
        ))

        return true
    }

    private func appendCompareSelectedMenuItems(
        submenu: NSMenu,
        items: (left: FinderCompareItem, right: FinderCompareItem)
    ) -> Bool {
        submenu.addItem(
            createMenuItem(
                title: items.left.type.compareTitle(leftURL: items.left.url, rightURL: items.right.url),
                action: #selector(compareSelected(_:))
            )
        )
        return true
    }

    private func appendSelectOnSideMenuItems(submenu: NSMenu) -> Bool {
        guard let url = selectedURL(),
              let selectedFileType = try? FileType(url: url) else {
            return false
        }
        submenu.addItem(
            createMenuItem(
                title: DisplaySide.left.selectTitleFor(url: url, fileType: selectedFileType),
                action: #selector(selectItem(_:)),
                tag: DisplaySide.left.rawValue
            )
        )
        submenu.addItem(
            createMenuItem(
                title: DisplaySide.right.selectTitleFor(url: url, fileType: selectedFileType),
                action: #selector(selectItem(_:)),
                tag: DisplaySide.right.rawValue
            )
        )
        return true
    }

    // MARK: - Helper methods

    private func selectedURL() -> URL? {
        let controller = FIFinderSyncController.default()
        if let selectedURL = controller.selectedItemURLs()?.first {
            return selectedURL
        }
        return controller.targetedURL()
    }

    private func handleCompare(leftURL: URL, rightURL: URL) {
        guard let app = SBApplication(bundleIdentifier: "com.visualdiffer") else {
            return
        }
        app.delegate = self
        app.activate()

        // using the dynamic approach keeps the AppleScript bridge simple
        app.perform(
            NSSelectorFromString("openDiffLeftPath:rightPath:"),
            with: leftURL.path(percentEncoded: false),
            with: rightURL.path(percentEncoded: false)
        )
    }

    private func observeVolumeChanges() {
        mountObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDirectoryURLs()
        }
        unmountObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDirectoryURLs()
        }
    }

    private func updateDirectoryURLs() {
        var urls = Set<URL>()

        urls.insert(URL(fileURLWithPath: "/"))
        if let volumeUrls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: []
        ) {
            urls.formUnion(volumeUrls)
        }
        FIFinderSyncController.default().directoryURLs = urls
    }

    // MARK: - SBApplicationDelegate delegate

    func eventDidFail(_: UnsafePointer<AppleEvent>, withError error: any Error) -> Any? {
        Self.general.error("Error while comparing, error \(error.localizedDescription).")
        return nil
    }
}
