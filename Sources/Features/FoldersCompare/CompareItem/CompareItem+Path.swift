//
//  CompareItem+Path.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension CompareItem {
    var pathRelativeToRoot: String? {
        guard let currentPath = path else {
            return nil
        }

        var parent = parent
        var rootPath: String?

        while let p = parent, let parentPath = p.path {
            rootPath = parentPath
            parent = p.parent
        }

        guard let rootPath else {
            return nil
        }

        // skip path separator
        let start = currentPath.index(currentPath.startIndex, offsetBy: rootPath.count + 1)
        return String(currentPath[start...])
    }

    static func find(
        withPath path: String,
        from root: CompareItem
    ) -> CompareItem? {
        guard root.isValidFile else {
            return nil
        }

        if root.path == path {
            return root
        }
        for item in root.children where item.isValidFile {
            if item.path == path {
                return item
            }

            if item.isFolder {
                if let retval = find(withPath: path, from: item) {
                    return retval
                }
            }
        }
        return nil
    }

    func findChildFileNameIndex(_ fileName: String, typeIsFile: Bool) -> Int {
        var index = 0

        for item in children {
            if item.fileName == fileName,
               item.isFile == typeIsFile {
                return index
            }
            index += 1
        }
        return NSNotFound
    }

    func buildDestinationPath(
        from srcBaseURL: URL,
        to destBaseURL: URL
    ) -> URL? {
        guard let srcURL = toURL() else {
            return nil
        }

        if let linkedURL = linkedItem?.toURL() {
            return linkedURL
        }

        guard let anchor = nearestLinkedAnchor(includingSelf: false),
              let anchorSrcURL = anchor.toURL(),
              let anchorDestURL = anchor.linkedItem?.toURL() else {
            return URL.buildDestinationPath(srcURL, nil, srcBaseURL, destBaseURL)
        }

        return URL.buildDestinationPath(srcURL, nil, anchorSrcURL, anchorDestURL)
    }

    func toURL() -> URL? {
        if let path {
            URL(filePath: path, directoryHint: isFolder ? .isDirectory : .notDirectory)
        } else {
            nil
        }
    }

    /// returns the closest linked base for creating destination directories
    func linkedDestinationDirectoryBase(
        from srcBaseURL: URL,
        to destBaseURL: URL
    ) -> DirectoryBase {
        guard let anchor = nearestLinkedAnchor(includingSelf: true),
              let anchorSrcURL = anchor.toURL(),
              let anchorDestURL = anchor.linkedItem?.toURL() else {
            return (srcBaseURL, destBaseURL)
        }

        return (anchorSrcURL, anchorDestURL)
    }

    /// walks up the tree until a linked item has a real path
    /// includes this item when includingSelf is true and it is a folder
    private func nearestLinkedAnchor(includingSelf: Bool) -> CompareItem? {
        var currentItem = includingSelf && isFolder ? self : parent

        while let current = currentItem {
            if current.linkedItem?.toURL() != nil {
                return current
            }
            currentItem = current.parent
        }
        return nil
    }
}
