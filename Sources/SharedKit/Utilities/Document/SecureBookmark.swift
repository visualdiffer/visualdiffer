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

    private let lock = NSLock()

    private init() {}

    /// Adds a new URL to the secure bookmarks.
    /// - Parameters:
    ///   - path: the URL to bookmark
    ///   - searchClosestPath: when `true`, reuses an ancestor bookmark if one already covers `path`
    ///   - forceUpdate: when `true`, skips the cache lookup and always (re)creates and stores the bookmark
    ///     for the exact path, overwriting any stale entry already cached under that path and dropping any
    ///     cached descendant bookmarks, which the freshly stored bookmark already covers
    /// - Returns: `true` if the URL is bookmarked successfully, `false` otherwise
    @discardableResult
    func add(
        _ path: URL,
        searchClosestPath: Bool = true,
        forceUpdate: Bool = false
    ) -> Bool {
        if findBookmark(path, searchClosestPath: searchClosestPath, forceUpdate: forceUpdate) != nil {
            return true
        }

        return storeBookmark(for: path, key: path.osPath, forceUpdate: forceUpdate)
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
            if startSecured {
                _ = url.startAccessingSecurityScopedResource()
                if isStale {
                    storeBookmark(for: url, key: bookmarkPath)
                }
            } else if isStale {
                // a security scope must be active to regenerate a stale bookmark, so open a
                // transient one and release it once refreshed, but only if the start actually
                // succeeded so the reference count stays balanced
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                storeBookmark(for: url, key: bookmarkPath)
                if didStartAccessing {
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
        lock.lock()
        defer { lock.unlock() }
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
        let pathWithSep = withPathSeparator(path.osPath)
        let sorted = searchPaths.sorted {
            $0.caseInsensitiveCompare($1) == .orderedDescending
        }
        for key in sorted where pathWithSep.hasPrefix(withPathSeparator(key)) {
            return key
        }
        return nil
    }

    private func findBookmark(
        _ path: URL,
        searchClosestPath: Bool,
        forceUpdate: Bool
    ) -> Data? {
        guard !forceUpdate, let securedPaths else {
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
    private func storeBookmark(
        for url: URL,
        key: String,
        forceUpdate: Bool = false
    ) -> Bool {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            lock.lock()
            defer { lock.unlock() }
            var dict = securedPaths ?? [String: Data]()
            if forceUpdate {
                // a freshly granted bookmark covers its whole subtree, so any cached
                // descendant is now redundant and safe to drop
                let prefix = withPathSeparator(key)
                dict = dict.filter { !$0.key.hasPrefix(prefix) }
            }
            dict[key] = bookmark
            UserDefaults.standard.set(dict, forKey: sandboxedPaths)
            return true
        } catch {
            Logger.general.error("Secure bookmark failed \(error)")
            return false
        }
    }

    private func withPathSeparator(_ path: String) -> String {
        // it does not matter whether path is a file or a directory, add the separator in any case
        // so hasPrefix works correctly with the last path component
        // for example "/Users/app 2 3" has prefix "/Users/app 2" but
        // "/Users/app 2 3/" does not have prefix "/Users/app 2/" and that is the correct result
        path + "/"
    }
}
