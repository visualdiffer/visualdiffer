//
//  URL+SymLink.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/08/11.
//  Copyright (c) 2011 visualdiffer.com
//

import os.log

extension URL {
    // MARK: - SymLinks

    ///
    /// This differs from `[NSString stringByResolvingSymlinksInPath]` in the fact that
    /// `/private` is resolved, too
    /// - Returns: The resolved `URL`
    /// - Throws: `POSIXError` if resolution fails
    ///
    func resolveSymlinks() throws -> URL {
        guard let cPath = osPath.cString(using: .utf8) else {
            throw EncodingError.conversionFailed(.utf8)
        }

        guard let result = realpath(cPath, nil) else {
            throw POSIXError(.init(rawValue: errno) ?? .ENOENT)
        }

        let resolved = String(cString: result)

        free(result)

        return URL(filePath: resolved)
    }

    ///
    /// Resolve any symlink and alias from `self` then check if path is already secured.
    /// If isn't secured shows the open panel to select path and then store it as secured
    /// - Parameters:
    ///   - chooseFiles: Can choose files
    ///   - chooseDirectories: Can choose directories
    ///   - panelTitle: The text to show as title if the open panel must be shown
    ///   - alwaysResolveSymlinks: Try to resolve symlinks before check for aliases
    /// - Returns: A tuple containing:
    ///   - `resolvedPath`: The selected path with aliases and symlinks resolved
    ///   - `userSelectOtherPath`: `true` if the selected path differs from the passed one
    ///   -  Returns `nil` if the user doesn't select any path
    ///
    @MainActor
    func resolveSymLinksAndAliases(
        chooseFiles: Bool,
        chooseDirectories: Bool,
        panelTitle: String,
        alwaysResolveSymlinks: Bool
    ) -> (resolvedPath: URL, userSelectOtherPath: Bool)? {
        // temporary files saved on /private require to be opened using resolved symlinks
        // otherwise the paths contained inside secure bookmarks don't match
        var path = self
        if alwaysResolveSymlinks {
            do {
                path = try path.resolveSymlinks()
            } catch {
                Logger.general.error("unable to resolve symlink for \(path) (error \(error))")
            }
        }
        do {
            if try path.isAliasFile() {
                path = try path.realPathByAlias()
            }
        } catch {
            Logger.general.error("unable to resolve alias for \(path) (error \(error))")
        }

        let selectedPath = if path.isSandboxed(allowFile: chooseFiles, allowDirectory: chooseDirectories) {
            path
        } else {
            path.selectPath(
                panelTitle: panelTitle,
                chooseFiles: chooseFiles,
                chooseDirectories: chooseDirectories
            )
        }

        guard let selectedPath else {
            return nil
        }
        return (selectedPath, selectedPath != path)
    }

    // MARK: - Aliases

    func isAliasFile() throws -> Bool {
        guard let contentType = try resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return contentType == .aliasFile
    }

    func realPathByAlias() throws -> URL {
        let alias = try URL.bookmarkData(withContentsOf: self)

        var isStale = false
        return try URL(
            resolvingBookmarkData: alias,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
}
