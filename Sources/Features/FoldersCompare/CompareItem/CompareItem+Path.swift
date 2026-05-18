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
    ) -> URL {
        guard let srcURL = toURL() else {
            fatalError("Path is not present on \(self)")
        }

        let linkedURL = linkedItem?.toURL()
        return URL.buildDestinationPath(srcURL, linkedURL, srcBaseURL, destBaseURL)
    }

    func toURL() -> URL? {
        if let path {
            URL(filePath: path, directoryHint: isFolder ? .isDirectory : .notDirectory)
        } else {
            nil
        }
    }
}
