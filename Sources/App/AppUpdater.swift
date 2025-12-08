//
//  AppUpdater.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

#if SPARKLE_ENABLED
    import Sparkle

    class AppUpdater {
        private var updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        @MainActor func configure() {
            guard let mainMenu = NSApp.mainMenu,
                  let applicationMenu = mainMenu.item(withTag: MainMenu.application.rawValue)?.submenu else {
                return
            }
            let checkForUpdatesItem = NSMenuItem(
                title: "Check for Updates…",
                action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
                keyEquivalent: ""
            )
            checkForUpdatesItem.target = updaterController
            applicationMenu.insertItem(checkForUpdatesItem, at: 4)
        }
    }

#endif
