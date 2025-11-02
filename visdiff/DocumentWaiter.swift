//
//  DocumentWaiter.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/08/11.
//  Copyright (c) 2011 visualdiffer.com
//

import ScriptingBridge

let documentClosedNotification = NSNotification.Name("VDDocumentClosedNotification")

enum ComparisonLaunchError: Error, LocalizedError {
    case launch(description: String)
    case script(error: any Error)

    var errorDescription: String? {
        switch self {
        case let .launch(description):
            description
        case let .script(error):
            ((error as NSError).userInfo["ErrorString"] as? String) ?? error.localizedDescription
        }
    }
}

class DocumentWaiter: NSObject, SBApplicationDelegate {
    var leftPath: URL
    var rightPath: URL
    var uuid: String?

    private var waitClose: Bool
    private var error: (any Error)?

    init(
        leftPath: URL,
        rightPath: URL,
        waitClose: Bool
    ) {
        self.leftPath = leftPath
        self.rightPath = rightPath
        self.waitClose = waitClose

        super.init()

        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(exitFromApp),
            name: documentClosedNotification,
            object: nil
        )
    }

    @objc func exitFromApp(_ notification: NSNotification) {
        let uuidNotification = notification.object as? String

        if uuid == uuidNotification {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    func openDocument() throws {
        guard let app = SBApplication(bundleIdentifier: "com.visualdiffer") else {
            throw ComparisonLaunchError.launch(description: "Unable to find VisualDiffer application")
        }
        app.delegate = self
        app.activate()

        // in Swift is more simple to use the dynamic approach
        uuid = app.perform(
            NSSelectorFromString("openDiffLeftPath:rightPath:"),
            with: leftPath.path(percentEncoded: false),
            with: rightPath.path(percentEncoded: false)
        )?.takeRetainedValue() as? String // swiftlint:disable:this multiline_function_chains

        if let error {
            throw ComparisonLaunchError.script(error: error)
        }

        #if DEBUG
            if uuid == nil {
                print("UUID is null. Note to myself. If application is launched from XCode this doesn't work. Close the app and launch it from dock")
            }
        #endif
        if uuid != nil {
            if waitClose {
                CFRunLoopRun()
            }
        }
    }

    func eventDidFail(_: UnsafePointer<AppleEvent>, withError error: any Error) -> Any? {
        self.error = error
        return nil
    }
}
