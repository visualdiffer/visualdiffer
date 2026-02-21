//
//  AppDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    #if SPARKLE_ENABLED
        private var appUpdater = AppUpdater()
    #endif
    private var appearanceObservation: NSKeyValueObservation?

    func application(_: NSApplication, open _: [URL]) {
        // allows `open` to temporarily sandbox urls
        // see https://github.com/visualdiffer/visualdiffer/issues/21#issuecomment-3863880590
    }

    func applicationWillFinishLaunching(_: Notification) {
        initDefaults()
        NSAppearance.change()
        // ensure the colors are correctly updated after appearance change
        CommonPrefs.shared.appearanceChanged(postNotification: true)
    }

    func applicationDidFinishLaunching(_: Notification) {
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { app, _ in
            CommonPrefs.shared.appearanceChanged(postNotification: true, app)
            ColoredFoldersManager.shared.refresh()
        }
        #if SPARKLE_ENABLED
            appUpdater.configure()
        #endif
    }

    func applicationWillTerminate(_: Notification) {
        appearanceObservation?.invalidate()
        appearanceObservation = nil
    }

    func applicationOpenUntitledFile(_: NSApplication) -> Bool {
        NSDocumentController.shared.newDocument(self)
        return true
    }

    @objc
    func openWiki(_: AnyObject) {
        if let url = URL(string: "https://wiki.visualdiffer.com") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc
    func bugReport(_: AnyObject) {
        if let url = URL(string: "https://bugs.visualdiffer.com") {
            NSWorkspace.shared.open(url)
        }
    }

    private func initDefaults() {
        if let defaultsPath = Bundle.main.url(forResource: "VDDefaults", withExtension: "plist"),
           let data = try? Data(contentsOf: defaultsPath),
           let defaultsDict = try? PropertyListSerialization.propertyList(
               from: data,
               options: [],
               format: nil
           ) as? [String: Any] {
            UserDefaults.standard.register(defaults: defaultsDict)
        }
    }
}
