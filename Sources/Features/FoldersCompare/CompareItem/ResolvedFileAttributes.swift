//
//  ResolvedFileAttributes.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

struct FileFlags: FlagSet {
    var rawValue: Int

    static let isFile = FileFlags(rawValue: 1 << 0)
    static let isFolder = FileFlags(rawValue: 1 << 1)
    static let isSymbolicLink = FileFlags(rawValue: 1 << 2)
    static let isPackage = FileFlags(rawValue: 1 << 3)
    static let isResourceFork = FileFlags(rawValue: 1 << 4)
    static let isLocked = FileFlags(rawValue: 1 << 5)
    static let isValidFile = FileFlags(rawValue: 1 << 6)
}

struct ResolvedFileAttributes {
    let rawAttributes: [FileAttributeKey: Any]
    let flags: FileFlags
    let fileSize: Int64
    let modificationDate: Date?
}

extension FileManager {
    func resolvedAttributes(
        atPath path: String,
        options: FileExtraOptions
    ) throws -> ResolvedFileAttributes {
        let attrs = try attributesOfItem(atPath: path)

        let fileType = attrs.fileAttributeType

        // if the object is a symlink then we use the destination file attributes
        // so we refer to destFileAttrs instead of the original input
        var destFileAttrs = attrs
        var isFolder = false
        var isPackage = false
        var isResourceFork = false
        let isLocked = (attrs[.immutable] as? NSNumber)?.boolValue ?? false
        let isSymbolicLink = fileType == .typeSymbolicLink

        // at this time we don't know if path is a directory or file, so force .notDirectory
        let url = URL(filePath: path, directoryHint: .notDirectory)

        if isSymbolicLink {
            let symLinkDest = url.resolvingSymlinksInPath().osPath
            if let symLinkAttrs = try? attributesOfItem(atPath: symLinkDest) {
                let symLinkFileType = symLinkAttrs.fileAttributeType
                isFolder = symLinkFileType == .typeDirectory
                destFileAttrs = symLinkAttrs
            }
        } else {
            isFolder = fileType == .typeDirectory
        }

        var realSize: Int64
        if isFolder {
            // this is necessary because the returned value can be > 0 also for directories
            // but we don't care about its real internal size
            realSize = 0

            isPackage = NSWorkspace.shared.isFilePackage(atPath: path)
            isResourceFork = false
        } else {
            isResourceFork = false
            realSize = (destFileAttrs[.size] as? NSNumber)?.int64Value ?? 0

            if options.contains(.resourceFork),
               let size = try? url.resourceForkSize() {
                realSize = Int64(size)
                isResourceFork = true
            }

            isPackage = false
        }

        var flags = FileFlags()
        flags[.isFile] = !isFolder
        flags[.isFolder] = isFolder
        flags[.isSymbolicLink] = isSymbolicLink
        flags[.isPackage] = isPackage
        flags[.isResourceFork] = isResourceFork
        flags[.isLocked] = isLocked
        flags[.isValidFile] = true

        return ResolvedFileAttributes(
            rawAttributes: attrs,
            flags: flags,
            fileSize: realSize,
            modificationDate: destFileAttrs[.modificationDate] as? Date
        )
    }
}
