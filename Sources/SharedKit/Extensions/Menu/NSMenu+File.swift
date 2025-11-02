//
//  NSMenu+File.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/12/12.
//  Copyright (c) 2012 visualdiffer.com
//

enum AppNameAttributeKey: String {
    case preferred = "appNamePreferred"
    case system = "appNameSystem"
}

extension NSMenu {
    static let preferredEditorPrefName = "preferredEditor"

    @objc static func appsMenuForFile(
        _ path: URL?,
        openAppAction: Selector,
        openOtherAppAction: Selector
    ) -> NSMenu {
        let appsMenu = NSMenu()

        appsMenu.addMenuItemsForFile(
            path,
            openAppAction: openAppAction,
            openOtherAppAction: openOtherAppAction
        )

        return appsMenu
    }

    @objc func addMenuItemsForFile(
        _ path: URL?,
        openAppAction: Selector,
        openOtherAppAction: Selector
    ) {
        guard let path else {
            addItem(
                withTitle: NSLocalizedString("<None>", comment: ""),
                action: nil,
                keyEquivalent: ""
            )
            return
        }

        let appNames = addTopMenusForFile(
            path,
            descriptionColor: NSColor.gray,
            openAppAction: openAppAction
        )

        // get all apps able to open path
        let url = path as CFURL
        guard let arr = LSCopyApplicationURLsForURL(url, .all)?.takeRetainedValue() as? [URL] else {
            return
        }

        // if default app exists it is surely into array
        if arr.isEmpty {
            if appNames[.preferred] == nil {
                addItem(
                    withTitle: NSLocalizedString("<None>", comment: ""),
                    action: nil,
                    keyEquivalent: ""
                )
            }
        } else {
            if !appNames.isEmpty {
                addItem(NSMenuItem.separator())
            }

            addAppMenuItems(
                mapAppNameToPath(arr, excludeAppNames: Array(appNames.values)),
                openAppAction: openAppAction
            )
        }

        // this happens when the preferred editor is equal to the default system
        // application and it is the only application
        if let item = item(at: numberOfItems - 1),
           !item.isSeparatorItem {
            addItem(NSMenuItem.separator())
        }
        addItem(
            withTitle: NSLocalizedString("Other...", comment: ""),
            action: openOtherAppAction,
            keyEquivalent: ""
        )
    }

    func addAppMenuItems(
        _ dictAppNames: [String: URL],
        openAppAction: Selector
    ) {
        let arrNames = dictAppNames.keys.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        for name in arrNames {
            if let path = dictAppNames[name] {
                addAppItem(
                    title: name,
                    openAppAction: openAppAction,
                    appPath: path
                )
            }
        }
    }

    func addTopMenusForFile(
        _ path: URL,
        descriptionColor: NSColor,
        openAppAction: Selector
    ) -> [AppNameAttributeKey: String] {
        var appNames = [AppNameAttributeKey: String]()

        let (defaultAppUrl, defaultAppName) = getSystemDefaultAppForFile(path)
        let (preferredAppUrl, preferredAppName) = getPreferredAppForFile(path)

        if let defaultAppUrl, let preferredAppUrl, defaultAppUrl == preferredAppUrl {
            addItem(
                defaultAppName ?? "",
                description: NSLocalizedString(" (System Default)", comment: ""),
                descriptionColor: descriptionColor,
                appPath: defaultAppUrl,
                openAppAction: openAppAction
            )
            appNames[.preferred] = preferredAppName
            appNames[.system] = defaultAppName
        } else {
            if let preferredAppName, let preferredAppUrl {
                addItem(
                    preferredAppName,
                    description: NSLocalizedString(" (App Default)", comment: ""),
                    descriptionColor: descriptionColor,
                    appPath: preferredAppUrl,
                    openAppAction: openAppAction
                )
                appNames[.preferred] = preferredAppName
            }
            if let defaultAppName, let defaultAppUrl {
                addItem(
                    defaultAppName,
                    description: NSLocalizedString(" (System Default)", comment: ""),
                    descriptionColor: descriptionColor,
                    appPath: defaultAppUrl,
                    openAppAction: openAppAction
                )
                appNames[.system] = defaultAppName
            }
        }

        return appNames
    }

    @discardableResult
    func addItem(
        _ title: String,
        description: String,
        descriptionColor: NSColor,
        appPath: URL,
        openAppAction: Selector
    ) -> NSMenuItem {
        let item = addAppItem(
            title: "",
            openAppAction: openAppAction,
            appPath: appPath
        )
        if let font {
            let attributes = AttributedMenuItem.createAttributes(
                title: title,
                description: description,
                descriptionColor: descriptionColor,
                font: font
            )
            item.attributedTitle = AttributedMenuItem.createTitle(attributes)
        }

        return item
    }

    @discardableResult
    func addAppItem(
        title: String,
        openAppAction: Selector,
        appPath: URL
    ) -> NSMenuItem {
        let image = NSWorkspace.shared.icon(forFile: appPath.osPath)
        image.size = NSSize(width: 16.0, height: 16.0)

        let item = addItem(
            withTitle: title,
            action: openAppAction,
            keyEquivalent: ""
        )
        item.representedObject = appPath.osPath
        item.image = image

        return item
    }

    func getSystemDefaultAppForFile(_ path: URL) -> (appUrl: URL?, appName: String?) {
        guard let appUrl = NSWorkspace.shared.urlForApplication(toOpen: path) else {
            return (nil, nil)
        }
        guard let values = try? appUrl.resourceValues(forKeys: [URLResourceKey.localizedNameKey]),
              let appName = values.localizedName else {
            return (appUrl, nil)
        }

        return (appUrl, appName)
    }

    func getPreferredAppForFile(_: URL) -> (appUrl: URL?, appName: String?) {
        guard let appPath = UserDefaults.standard.string(forKey: Self.preferredEditorPrefName) else {
            return (nil, nil)
        }

        let appUrl = URL(filePath: appPath)

        guard let values = try? appUrl.resourceValues(forKeys: [URLResourceKey.localizedNameKey]),
              let appName = values.localizedName else {
            return (appUrl, nil)
        }

        return (appUrl, appName)
    }

    func mapAppNameToPath(
        _ appUrls: [URL],
        excludeAppNames: [String]
    ) -> [String: URL] {
        var dictAppNames = [String: URL]()

        for url in appUrls {
            if let values = try? url.resourceValues(forKeys: [.localizedNameKey]),
               let displayName = values.localizedName {
                dictAppNames[displayName] = url
            } else {
                dictAppNames[url.lastPathComponent] = url
            }
        }

        for appName in excludeAppNames {
            dictAppNames.removeValue(forKey: appName)
        }

        return dictAppNames
    }
}
