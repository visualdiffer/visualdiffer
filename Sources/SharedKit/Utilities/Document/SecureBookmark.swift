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

    /**
     * Add a new url to the secure bookmarks
     * @return true if the url is bookmarked with success, false otherwise
     */
    @discardableResult
    func add(_ path: URL, searchClosestPath: Bool = true) -> Bool {
        var bookmark: Data?

        if searchClosestPath,
           let securedPaths {
            if let closestPath = findClosestPath(to: path, searchPaths: Array(securedPaths.keys)) {
                bookmark = securedPaths[closestPath]
            }
        } else {
            bookmark = securedPaths?[path.osPath]
        }

        if bookmark == nil {
            do {
                bookmark = try path.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                var dict = securedPaths

                if dict == nil {
                    dict = [String: Data]()
                }
                // swiftlint:disable:next force_unwrapping
                dict![path.osPath] = bookmark
                UserDefaults.standard.set(dict, forKey: sandboxedPaths)
            } catch {
                Logger.general.error("Secure bookmark failed \(error)")
                return false
            }
        }
        return true
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
        // don't matter if path is a file or a directory, add the separator in any case
        // so hasPrefix works fine with last path component
        // eg "/Users/app 2 3" has prefix "/Users/app 2" but
        // "/Users/app 2 3/" hasn't prefix "/Users/app 2/" and this is the correct result
        let pathWithSep = path.osPath + "/"
        let sorted = searchPaths.sorted {
            $0.caseInsensitiveCompare($1) == .orderedDescending
        }
        for key in sorted where pathWithSep.hasPrefix(key + "/") {
            return key
        }
        return nil
    }
}
