//
//  FileOperationManager+Util.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FileOperationManager {
    func canRemoveDirectory(_ item: CompareItem) -> Bool {
        if !filterConfig.followSymLinks, item.isSymbolicLink {
            // unlink folder without deleting files pointed to real path
            return true
        }
        // if some error occurred while deleting files or
        // directory isn't empty (can contain filtered files) it can't be deleted
        if let path = item.path,
           let dirEnum = FileManager.default.enumerator(atPath: path) {
            return dirEnum.nextObject() == nil
        }
        return false
    }

    func createSymLink(
        atPath path: URL,
        destinationOfSymLinkAtPath srcPath: URL
    ) throws {
        let canCreateSymLink = try overwriteSymLink(path)

        if canCreateSymLink {
            // don't normalize relative path to absolute one
            // this allow us to recreate relative path to destBaseDir
            let real = try srcPath.destinationOfSymbolicLink()
            try path.createSymbolicLink(withDestination: real)
        } else {
            throw FileError.createSymLink(path: path.osPath)
        }
    }

    /**
     * check if we can "overwrite" the file with symlink
     */
    func overwriteSymLink(_ url: URL) throws -> Bool {
        do {
            let urlPath = url.osPath
            let cleanPath = urlPath.hasSuffix("/") ? String(urlPath.dropLast()) : urlPath
            let attrs = try FileManager.default.attributesOfItem(atPath: cleanPath)
            if let fileType = attrs[.type] as? String,
               fileType == FileAttributeType.typeSymbolicLink.rawValue {
                // should call doDelete
                try FileManager.default.removeItem(at: url)
                return true
            }
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain,
               error.code == NSFileReadNoSuchFileError {
                return true
            }
        }
        return false
    }

    func timestampAttributesFrom(_ srcAttrs: [FileAttributeKey: Any]) -> [FileAttributeKey: Any] {
        var timestampAttrs = [FileAttributeKey: Any]()
        let keys: [FileAttributeKey] = [.creationDate, .modificationDate]

        for key in keys {
            if let value = srcAttrs[key] {
                timestampAttrs[key] = value
            }
        }

        return timestampAttrs
    }

    func createDestinationDirectory(
        _ srcRoot: CompareItem,
        destRoot _: CompareItem,
        srcBaseDir: URL,
        destBaseDir: URL,
        destFullPath: URL
    ) throws {
        if !filterConfig.followSymLinks, srcRoot.isSymbolicLink {
            guard let srcRootPath = srcRoot.toUrl() else {
                throw FolderManagerError.nilPath
            }
            try createSymLink(
                atPath: destFullPath,
                destinationOfSymLinkAtPath: srcRootPath
            )
        } else {
            // Directory can be empty so we ensure it is created
            try createDirectory(
                atPath: destBaseDir,
                srcBaseDir: srcBaseDir,
                namesFrom: srcRoot,
                options: comparator.options.directoryOptions
            )
        }
    }
}

extension ComparatorOptions {
    var directoryOptions: DirectoryOptions {
        var options: DirectoryOptions = []

        if contains(.finderLabel) {
            options.insert(.copyLabels)
        }
        if contains(.finderTags) {
            options.insert(.copyTags)
        }

        return options
    }
}
