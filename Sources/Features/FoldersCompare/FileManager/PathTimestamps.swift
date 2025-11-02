//
//  PathTimestamps.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct DirectoryOptions: OptionSet {
    let rawValue: Int

    static let copyLabels = DirectoryOptions(rawValue: 1 << 0)
    static let copyTags = DirectoryOptions(rawValue: 1 << 1)
}

struct PathTimestamps {
    private(set) var timestamps = [FileAttributeKey: Any]()

    init() {}

    init(fromFileAttributes attrs: [FileAttributeKey: Any]) {
        if let creationDate = attrs[.creationDate] as? Date {
            timestamps[.creationDate] = creationDate
        }
        if let modificationDate = attrs[.modificationDate] as? Date {
            timestamps[.modificationDate] = modificationDate
        }
    }

    func applyTo(itemAtPath path: URL) throws {
        try FileManager.default.setAttributes(timestamps, ofItemAtPath: path.osPath)
    }
}

@discardableResult
func createDirectory(
    atPath baseDestPath: URL,
    srcBaseDir: URL,
    namesFrom srcRoot: CompareItem,
    options: DirectoryOptions
) throws -> PathTimestamps? {
    var item: CompareItem? = srcRoot

    if srcRoot.isFile {
        item = srcRoot.parent
    }

    var directories: [CompareItem] = []

    while let localItem = item,
          let url = localItem.toUrl(),
          url != srcBaseDir {
        directories.insert(localItem, at: 0)
        item = localItem.parent
    }

    let fm = FileManager.default
    var path = baseDestPath
    var attrs: PathTimestamps?

    for fsDir in directories {
        guard let fsPath = fsDir.path,
              let fsFileName = fsDir.fileName else {
            break
        }
        path = path.appending(path: fsFileName, directoryHint: fsDir.isFolder ? .isDirectory : .notDirectory)

        if fm.fileExists(atPath: path.osPath) {
            continue
        }

        try fm.createDirectory(
            at: path,
            withIntermediateDirectories: false,
            attributes: nil
        )
        try attrs?.applyTo(itemAtPath: path.deletingLastPathComponent())

        if options.contains(.copyLabels) {
            try fsDir.toUrl()?.copyLabel(to: &path)
        }

        if options.contains(.copyTags) {
            try fsDir.toUrl()?.copyTags(to: &path)
        }

        attrs = try PathTimestamps(fromFileAttributes: fm.attributesOfItem(atPath: fsPath))
    }

    try attrs?.applyTo(itemAtPath: path)

    return attrs
}
