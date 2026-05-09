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
@objc(OpenDiffCommand)
class OpenDiffCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let evaluatedArguments,
              let leftPath = evaluatedArguments["LeftPath"] as? String,
              let rightPath = evaluatedArguments["RightPath"] as? String else {
            return nil
        }

        let leftURL = URL(filePath: leftPath)
        let rightURL = URL(filePath: rightPath)

        var isDir = false
        var leftExists = false
        var rightExists = false

        let matches = leftURL.matchesFileType(
            of: rightURL,
            isDir: &isDir,
            leftExists: &leftExists,
            rightExists: &rightExists
        )

        if matches {
            return openDocument(
                leftURL: leftURL,
                rightURL: rightURL
            )
        } else {
            let message = SessionTypeError.invalidPathMessage(
                isDir: isDir,
                leftExists: leftExists,
                rightExists: rightExists
            )
            setScriptError(error: .invalidPath, message: message)
        }
        return nil
    }

    func openDocument(
        leftURL: URL,
        rightURL: URL
    ) -> String? {
        do {
            return try MainActor.assumeIsolated {
                try VDDocumentController.shared.openDifferDocument(
                    leftURL: leftURL,
                    rightURL: rightURL
                )?.uuid
            }
        } catch {
            setScriptError(error: .invalidDocument, message: error.localizedDescription)

            return nil
        }
    }

    func setScriptError(error: CommandError, message: String) {
        scriptErrorNumber = error.rawValue
        scriptErrorString = message
    }
}
