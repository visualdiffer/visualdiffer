//
//  SecureBookmark.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation
import os.log

private let sandboxedPaths = "sandboxedPaths"

class SecureBookmark: @unchecked Sendable {
    static let shared = SecureBookmark()

    private init() {}

    /// Adds a new URL to the secure bookmarks.
    /// - Parameters:
    ///   - path: the URL to bookmark
    ///   - searchClosestPath: when `true`, reuses an ancestor bookmark if one already covers `path`
    ///   - forceUpdate: when `true`, skips the cache lookup and always (re)creates and stores the bookmark
    ///     for the exact path, overwriting any stale entry already cached under that path
    /// - Returns: `true` if the URL is bookmarked successfully, `false` otherwise
    @discardableResult
    func add(
        _ path: URL,
        searchClosestPath: Bool = true,
        forceUpdate: Bool = false
    ) -> Bool {
        let bookmark = findBookmark(path, searchClosestPath: searchClosestPath, forceUpdate: forceUpdate)

        guard bookmark == nil else {
            return true
        }

        return storeBookmark(for: path, key: path.osPath)
    }

    func secure(fromBookmark path: URL?, startSecured: Bool) -> URL? {
        guard let path else {
            return nil
        }
        guard let dict = securedPaths,
              let bookmarkPath = findClosestPath(to: path, searchPaths: Array(dict.keys)),
              let data = dict[bookmarkPath] else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            // a security scope must be active both to keep the caller accessing and to
            // regenerate a stale bookmark, so open it when either reason applies
            var didStartAccessing = false
            if startSecured || isStale {
                didStartAccessing = url.startAccessingSecurityScopedResource()
            }
            if isStale {
                storeBookmark(for: url, key: bookmarkPath)
                // release the scope that was opened only to refresh the stale bookmark,
                // but only if the start actually succeeded so the reference count stays balanced
                if !startSecured, didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            return url
        } catch {
            Logger.general.error("Secure bookmark error while resolving bookmark \(error)")
        }
        return nil
    }

    func stopAccessing(url: URL?) {
        url?.stopAccessingSecurityScopedResource()
    }

    func removePaths(_ paths: [String]) {
        guard var dict = securedPaths else {
            return
        }

        for path in paths {
            dict.removeValue(forKey: path)
        }
        UserDefaults.standard.set(dict, forKey: sandboxedPaths)
    }

    var securedPaths: [String: Data]? {
        UserDefaults.standard.dictionary(forKey: sandboxedPaths) as? [String: Data]
    }

    func findClosestPath(to path: URL, searchPaths: [String]) -> String? {
        // it does not matter whether path is a file or a directory, add the separator in any case
        // so hasPrefix works correctly with the last path component
        // for example "/Users/app 2 3" has prefix "/Users/app 2" but
        // "/Users/app 2 3/" does not have prefix "/Users/app 2/" and that is the correct result
        let pathWithSep = path.osPath + "/"
        let sorted = searchPaths.sorted {
            $0.caseInsensitiveCompare($1) == .orderedDescending
        }
        for key in sorted where pathWithSep.hasPrefix(key + "/") {
            return key
        }
        return nil
    }

    private func findBookmark(
        _ path: URL,
        searchClosestPath: Bool,
        forceUpdate: Bool
    ) -> Data? {
        if forceUpdate {
            return nil
        }

        guard let securedPaths else {
            return nil
        }

        if !searchClosestPath {
            return securedPaths[path.osPath]
        }

        guard let closestPath = findClosestPath(to: path, searchPaths: Array(securedPaths.keys)) else {
            return nil
        }

        return securedPaths[closestPath]
    }

    @discardableResult
    private func storeBookmark(for url: URL, key: String) -> Bool {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            var dict = securedPaths ?? [String: Data]()
            dict[key] = bookmark
            UserDefaults.standard.set(dict, forKey: sandboxedPaths)
            return true
        } catch {
            Logger.general.error("Secure bookmark failed \(error)")
            return false
        }
    }
}
