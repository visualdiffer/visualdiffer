//
//  OpenEditor.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os.log

struct OpenEditor {
    let attributes: [OpenEditorAttribute]

    init(attributes: [OpenEditorAttribute]) {
        self.attributes = attributes
    }

    init(attributes: OpenEditorAttribute) {
        self.init(attributes: [attributes])
    }

    init(path: String) {
        self.init(attributes: [OpenEditorAttribute(path: path)])
    }
}

extension OpenEditor {
    @MainActor func browseApplicationAndLaunch() throws {
        let openPanel = NSOpenPanel().openApplication(title: NSLocalizedString("Select Application", comment: ""))

        if openPanel.runModal() == .OK {
            try open(withApplication: openPanel.urls[0])
        }
    }

    /**
     * Run the editor application opening passed files and if editor is supported
     * move the cursor to the line/column specified into attributes
     * @param application the application path used to open the files, if nil uses the default system application
     **/
    func open(withApplication: URL?) throws {
        guard let item = attributes.first,
              let secureURL = SecureBookmark.shared.secure(fromBookmark: item.path, startSecured: true) else {
            return
        }
        defer {
            SecureBookmark.shared.stopAccessing(url: secureURL)
        }
        let application = if let withApplication {
            withApplication
        } else {
            NSWorkspace.shared.urlForApplication(toOpen: item.path)
        }

        guard let application else {
            throw OpenEditorError.applicationNotFound(item.path)
        }
        if let scriptURL = fullScriptURL(application) {
            try runUnixScript(scriptURL)
        } else {
            NSWorkspace.shared.open(
                [item.path],
                withApplicationAt: application,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, error in
                if let error {
                    Logger.general.error("Unable to open file \(item.path): \(error)")
                }
            }
        }
    }

    private func fullScriptURL(_ application: URL) -> URL? {
        guard let scriptsURL = try? FileManager.default.url(
            for: .applicationScriptsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ),
            let bundle = Bundle(url: application),
            let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        var fullScriptURL = scriptsURL
        fullScriptURL.appendPathComponent("editors")
        fullScriptURL.appendPathComponent(bundleIdentifier)
        fullScriptURL.appendPathExtension("sh")

        return FileManager.default.fileExists(atPath: fullScriptURL.osPath) ? fullScriptURL : nil
    }

    func runUnixScript(_ scriptURL: URL) throws {
        do {
            let task = try NSUserUnixTask(url: scriptURL)
            task.execute(withArguments: arguments()) { taskError in
                if let taskError {
                    Logger.general.error("Unable to launch \(scriptURL.osPath), \(taskError)")
                }
            }
        } catch {
            try checkExecutablePermissions(scriptURL, rethrow: error)
        }
    }

    private func checkExecutablePermissions(_ scriptURL: URL, rethrow _: Error) throws {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: scriptURL.osPath),
              let permissions = attrs[.posixPermissions] as? Int,
              (permissions & 0o100) == 0 else {
            return
        }

        throw OpenEditorError.missingExecutePermission(scriptURL)
    }

    private func arguments() -> [String] {
        attributes.flatMap { $0.arguments() }
    }
}
