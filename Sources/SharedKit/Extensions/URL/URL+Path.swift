//
//  URL+Path.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

public extension URL {
    /**
     * Directory url contains "/" at the end and this cause many problems (eg symlinks)
     * so we return the path without it
     */
    var osPath: String {
        path(percentEncoded: false).trimmingSuffix("/")
    }

    /**
     * Standardize and then trim trailing separators
     */
    var standardizingPath: String {
        path(percentEncoded: false).standardizingPath
    }

    func volumeType() -> String? {
        if let values = try? resourceValues(forKeys: [.volumeTypeNameKey]),
           let type = values.volumeTypeName {
            return type
        }
        return nil
    }

    static func buildDestinationPath(
        _ srcURL: URL,
        _ destURL: URL?,
        _ srcBaseURL: URL,
        _ destBaseURL: URL
    ) -> URL {
        let srcBaseDir = srcBaseURL.osPath
        let srcPath = srcURL.osPath

        if let destURL {
            // use destination file name if it is present so
            // file names using a not match-case alignment works fine
            let lastPathIndex = srcPath.lastIndex(of: "/") ?? srcPath.startIndex
            let startIndex = srcBaseDir.endIndex
            let relativePath = srcPath[startIndex ..< lastPathIndex].trimmingPrefix("/")

            return destBaseURL
                .appending(path: String(relativePath))
                .appending(
                    path: destURL.lastPathComponent,
                    directoryHint: destURL.hasDirectoryPath ? .isDirectory : .notDirectory
                )
        }
        let trailingPath = String(srcPath[srcBaseDir.endIndex...]).trimmingPrefix("/")
        return destBaseURL
            .appending(path: trailingPath, directoryHint: srcURL.hasDirectoryPath ? .isDirectory : .notDirectory)
    }
}

// MARK: - Path check and selection

public extension URL {
    /**
     * Check that self is the same type as the passed item (both are files or both are folders)
     */
    func matchesFileType(
        of rightUrl: URL,
        isDir: inout Bool,
        leftExists: inout Bool,
        rightExists: inout Bool
    ) -> Bool {
        let fileManager = FileManager.default
        var isLeftDir = ObjCBool(false)
        var isRightDir = ObjCBool(false)

        let leftPath = osPath
        let rightPath = rightUrl.osPath

        leftExists = fileManager.fileExists(atPath: leftPath, isDirectory: &isLeftDir)
        rightExists = fileManager.fileExists(atPath: rightPath, isDirectory: &isRightDir)

        isDir = isLeftDir.boolValue
        // must be both folders or both files
        return leftExists && rightExists && (isLeftDir.boolValue == isRightDir.boolValue)
    }

    func matchesFileType(of rightUrl: URL) -> Bool {
        var isDir = false
        var leftExists = false
        var rightExists = false

        return matchesFileType(
            of: rightUrl,
            isDir: &isDir,
            leftExists: &leftExists,
            rightExists: &rightExists
        )
    }

    @MainActor func selectPath(
        panelTitle: String,
        chooseFiles: Bool,
        chooseDirectories: Bool
    ) -> URL? {
        let url = promptUrl(
            at: findNearestExistingDirectory(),
            title: panelTitle,
            chooseDirectories: chooseDirectories,
            chooseFiles: chooseFiles
        )

        if let url {
            SecureBookmark.shared.add(url)
        }

        return url
    }

    /**
     * Check if path is already sandboxed and doesn't need to be selected by user (e.g. using OpenPanel)
     * @param allowFile the url can be a file
     * @param allowDirectory the url can be a directory
     * @return true if file is sandboxed and its type matches the allowed types, false otherwise
     */
    func isSandboxed(allowFile: Bool, allowDirectory: Bool) -> Bool {
        let fileManager = FileManager.default
        var isDir = ObjCBool(false)
        let startDir = osPath

        let securedURL = SecureBookmark.shared.secure(fromBookmark: self, startSecured: true)
        defer {
            SecureBookmark.shared.stopAccessing(url: securedURL)
        }
        let result = fileManager.fileExists(atPath: startDir, isDirectory: &isDir)
            && fileManager.isReadableFile(atPath: startDir)

        let isFileTypeAllowed = if allowFile, allowDirectory {
            true
        } else if allowFile {
            isDir.boolValue == false
        } else if allowDirectory {
            isDir.boolValue == true
        } else {
            false
        }
        return result && isFileTypeAllowed
    }

    func findNearestExistingDirectory() -> URL {
        let fileManager = FileManager.default
        var isDir = ObjCBool(false)
        var currDir = self

        while !fileManager.fileExists(atPath: currDir.osPath, isDirectory: &isDir) || !isDir.boolValue {
            currDir.deleteLastPathComponent()
        }

        return currDir
    }

    @MainActor func promptUrl(
        at startUrl: URL,
        title: String,
        chooseDirectories: Bool,
        chooseFiles: Bool
    ) -> URL? {
        let openPanel = NSOpenPanel()

        openPanel.title = title
        openPanel.canChooseDirectories = chooseDirectories
        openPanel.canChooseFiles = chooseFiles
        // since 10.11 the title is no longer shown so we use the message property
        openPanel.message = title
        openPanel.directoryURL = startUrl

        if openPanel.runModal() == .OK {
            return openPanel.urls[0]
        }
        return nil
    }

    static func compare(fileName lhs: String, with rhs: String) -> ComparisonResult {
        lhs.localizedStandardCompare(rhs)
    }

    static func compare(
        path path1: URL?,
        with path2: URL?
    ) -> ComparisonResult {
        guard let path1 else {
            return .orderedAscending
        }
        guard let path2 else {
            return .orderedDescending
        }
        let components1 = path1.pathComponents
        let components2 = path2.pathComponents
        let count1 = components1.count
        let count2 = components2.count

        // do not compare last component because we compare only directory components
        let minComponents = min(count1, count2) - 1

        for i in 0 ..< minComponents {
            let comp1 = components1[i]
            let comp2 = components2[i]
            let compareResult = compare(fileName: comp1, with: comp2)

            if compareResult != .orderedSame {
                return compareResult
            }
        }

        let delta = count1 - count2
        var comp1: String
        var comp2: String

        var isDir1 = path1.hasDirectoryPath
        var isDir2 = path2.hasDirectoryPath

        if delta > 0 {
            comp1 = components1[minComponents]
            comp2 = components2[count2 - 1]
            isDir1 = true
            // comp1 is a comp2's subdirectory so we can compare them
            if isDir2 {
                let r = compare(fileName: comp1, with: comp2)
                if r == .orderedSame {
                    return .orderedDescending
                }
                return r
            }
        } else if delta < 0 {
            comp1 = components1[count1 - 1]
            comp2 = components2[minComponents]
            isDir2 = true
            // comp2 is a subdirectory so we can compare them
            if isDir1 {
                let r = compare(fileName: comp1, with: comp2)
                if r == .orderedSame {
                    return .orderedAscending
                }
                return r
            }
        } else {
            comp1 = components1[count1 - 1]
            comp2 = components2[count2 - 1]
        }

        if isDir1 == isDir2 {
            return comp1.compare(comp2, options: .caseInsensitive)
        }

        return isDir1 ? .orderedAscending : .orderedDescending
    }
}
