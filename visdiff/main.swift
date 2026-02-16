//
//  main.swift
//  visdiff
//
//  Created by davide ficano on 31/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

import Foundation

let version = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "n/a"

enum Flags: String {
    case version = "--version"
    case wait = "--wait"
    case noWarning = "--no-warning"

    func isEqual(_ lhs: String) -> Bool {
        rawValue.caseInsensitiveCompare(lhs) == .orderedSame
    }
}

func showHelp() {
    print("Usage: leftFileOrFolder rightFileOrFolder \(Flags.version.rawValue) \(Flags.wait.rawValue) \(Flags.noWarning.rawValue)\nNotes: left and right must be both files or both folders\n")
}

func showVersion() {
    print(version)
}

func main() -> Int32 {
    var waitClose = false
    var showWarning = true

    // remove executable path
    let argv = ProcessInfo.processInfo.arguments
    let argc = argv.count

    if argc == 2, Flags.version.isEqual(argv[1]) {
        showVersion()
        return 1
    } else if argc < 3 {
        showHelp()
        return 1
    }

    let l = URL(filePath: argv[1]).absoluteURL
    let r = URL(filePath: argv[2]).absoluteURL

    for arg in argv.dropFirst(3) {
        if Flags.version.isEqual(arg) {
            showVersion()
        } else if Flags.wait.isEqual(arg) {
            waitClose = true
        } else if Flags.noWarning.isEqual(arg) {
            showWarning = false
        }
    }

    if showWarning {
        let message = """
warning: VisualDiffer is sandboxed.

To let visdiff work without asking again, choose a folder in the app
that contains the files you want to compare.

If your files are stored in different locations, you can select a common
parent directory (or even "/" if appropriate). The app will only access
files within the folder you choose and its subfolders.

You can change this anytime in Settings -> Trusted Path.
Use --no-warning to suppress this message.

"""
        try? FileHandle.standardError.write(contentsOf: Data(message.utf8))
    }

    do {
        try DocumentWaiter(leftPath: l, rightPath: r, waitClose: waitClose).openDocument()
    } catch {
        print(error.localizedDescription)
        return 1
    }

    return 0
}

exit(main())
