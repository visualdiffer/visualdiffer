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
    case focus = "--focus"
    case noWarning = "--no-warning"

    func isEqual(_ lhs: String) -> Bool {
        rawValue.caseInsensitiveCompare(lhs) == .orderedSame
    }
}

func showHelp() {
    let message = """
    Usage: visdiff [arguments] <left file or folder> <right file or folder>

    Arguments:
      \(Flags.wait.rawValue):          wait until the diff window is closed before returning
      \(Flags.focus.rawValue):         restore the caller app focus after waiting, valid only with \(Flags.wait.rawValue)
      \(Flags.noWarning.rawValue):    suppress the sandbox warning message
      \(Flags.version.rawValue):       show version and exit

    Notes:
      Left and right must both be files or both be folders.
    """

    print(message)
}

func showVersion() {
    print(version)
}

func printStdErr(_ message: String) {
    try? FileHandle.standardError.write(contentsOf: Data(message.utf8))
}

enum PathResolutionError: LocalizedError {
    case missingWorkingDirectory(path: String)

    var errorDescription: String? {
        switch self {
        case let .missingWorkingDirectory(path):
            """
            Unable to resolve relative path: \(path)

            visdiff is sandboxed and cannot safely use the process working directory.
            Relative paths require the caller shell to provide PWD.
            Pass absolute paths instead if PWD is not available.

            See more at https://wiki.visualdiffer.com/unixshell.html#how_visdiff_resolves_relative_paths
            """
        }
    }
}

func resolvePath(_ path: String, shellWorkingDirectory: String?) throws -> URL {
    guard !path.hasPrefix("/") else {
        return URL(filePath: path).standardizedFileURL
    }
    guard let shellWorkingDirectory, !shellWorkingDirectory.isEmpty else {
        throw PathResolutionError.missingWorkingDirectory(path: path)
    }

    return URL(filePath: path, relativeTo: URL(filePath: shellWorkingDirectory, directoryHint: .isDirectory))
        .standardizedFileURL
}

func main() -> Int32 {
    var waitClose = false
    var restoreFocus = false
    var showWarning = true
    var positionalArgs: [String] = []

    let args = ProcessInfo.processInfo.arguments.dropFirst()

    for arg in args {
        if Flags.version.isEqual(arg) {
            showVersion()
            return 1
        } else if Flags.wait.isEqual(arg) {
            waitClose = true
        } else if Flags.focus.isEqual(arg) {
            restoreFocus = true
        } else if Flags.noWarning.isEqual(arg) {
            showWarning = false
        } else {
            // treat anything that is not a known flag as a positional argument
            positionalArgs.append(arg)
        }
    }

    // validate that exactly two positional arguments (left and right paths) were provided
    guard positionalArgs.count == 2 else {
        showHelp()
        return 1
    }

    if showWarning {
        let message = """
        warning: VisualDiffer is sandboxed.

        To let visdiff work without asking again, choose a folder in the app
        that contains the files you want to compare.

        If your files are stored in different locations, you can select a common
        parent directory (or even "/" if appropriate). The app will only access
        files within the folder you choose and its subfolders.

        You can change this anytime in Settings -> Trusted Paths.
        Use --no-warning to suppress this message.

        """
        printStdErr(message)
    }

    do {
        let shellWorkingDirectory = ProcessInfo.processInfo.environment["PWD"]
        let l = try resolvePath(positionalArgs[0], shellWorkingDirectory: shellWorkingDirectory)
        let r = try resolvePath(positionalArgs[1], shellWorkingDirectory: shellWorkingDirectory)
        let options = DocumentWaiter.Options(
            waitClose: waitClose,
            shouldRestoreFocus: restoreFocus
        )

        try DocumentWaiter(
            leftPath: l,
            rightPath: r,
            options: options
        ).openDocument()
    } catch {
        printStdErr("\(error.localizedDescription)\n")
        return 1
    }

    return 0
}

exit(main())
