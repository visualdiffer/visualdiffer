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

    func isEqual(_ lhs: String) -> Bool {
        rawValue.caseInsensitiveCompare(lhs) == .orderedSame
    }
}

func showHelp() {
    print("Usage: leftFileOrFolder rightFileOrFolder \(Flags.version.rawValue) \(Flags.wait.rawValue)\nNotes: left and right must be both files or both folders\n")
}

func showVersion() {
    print(version)
}

func main() -> Int32 {
    var waitClose = false

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
        }
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
