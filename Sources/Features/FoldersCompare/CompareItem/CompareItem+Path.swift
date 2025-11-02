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
        var rootPath = currentPath

        while let p = parent, let parentPath = p.path {
            rootPath = parentPath
            parent = p.parent
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
        from srcBaseUrl: URL,
        to destBaseUrl: URL
    ) -> URL {
        guard let srcUrl = toUrl() else {
            fatalError("Path is not present on \(self)")
        }
        let linkedUrl = linkedItem?.toUrl()
        return URL.buildDestinationPath(srcUrl, linkedUrl, srcBaseUrl, destBaseUrl)
    }

    func toUrl() -> URL? {
        if let path {
            URL(filePath: path, directoryHint: isFolder ? .isDirectory : .notDirectory)
        } else {
            nil
        }
    }
}
