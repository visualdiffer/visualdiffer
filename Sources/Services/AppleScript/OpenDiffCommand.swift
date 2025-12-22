//
//  OpenDiffCommand.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/11/20.
//  Copyright (c) 2020 visualdiffer.com
//

enum CommandError: Int {
    case invalidPath = 4000
    case invalidDocument
}

// the attribute @objc is necessary to work correctly in Swift
@objc(OpenDiffCommand) class OpenDiffCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let evaluatedArguments,
              let leftPath = evaluatedArguments["LeftPath"] as? String,
              let rightPath = evaluatedArguments["RightPath"] as? String else {
            return nil
        }

        let leftUrl = URL(filePath: leftPath)
        let rightUrl = URL(filePath: rightPath)

        var isDir = false
        var leftExists = false
        var rightExists = false

        let matches = leftUrl.matchesFileType(
            of: rightUrl,
            isDir: &isDir,
            leftExists: &leftExists,
            rightExists: &rightExists
        )

        if matches {
            return openDocument(
                leftUrl: leftUrl,
                rightUrl: rightUrl
            )
        } else {
            let message = invalidPathMessage(
                isDir: isDir,
                leftExists: leftExists,
                rightExists: rightExists
            )
            setScriptError(error: .invalidPath, message: message)
        }
        return nil
    }

    func openDocument(
        leftUrl: URL,
        rightUrl: URL
    ) -> String? {
        do {
            return try MainActor.assumeIsolated {
                try VDDocumentController.shared.openDifferDocument(
                    leftUrl: leftUrl,
                    rightUrl: rightUrl
                )?.uuid
            }
        } catch {
            setScriptError(error: .invalidDocument, message: error.localizedDescription)

            return nil
        }
    }

    func invalidPathMessage(isDir: Bool, leftExists: Bool, rightExists: Bool) -> String {
        if leftExists, rightExists {
            if isDir {
                return NSLocalizedString("Left path is a folder but the right is a file; both must be folders or files", comment: "")
            } else {
                return NSLocalizedString("Left path is a file but the right is a folder; both must be folders or files", comment: "")
            }
        }
        if !leftExists {
            return NSLocalizedString("Left path doesn't exist", comment: "")
        }
        return NSLocalizedString("Right path doesn't exist", comment: "")
    }

    func setScriptError(error: CommandError, message: String) {
        scriptErrorNumber = error.rawValue
        scriptErrorString = message
    }
}
