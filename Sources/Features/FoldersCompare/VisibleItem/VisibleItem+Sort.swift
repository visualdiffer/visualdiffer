//
//  VisibleItem+Sort.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
    lhs == rhs ? .orderedSame : lhs < rhs ? .orderedAscending : .orderedDescending
}

@objc extension VisibleItem {
    func sort(
        byFileName ascending: Bool,
        ignoreCase: Bool,
        followSymLinks: Bool
    ) {
        sortChildren(ascending, ignoreCase: ignoreCase) { fs1, fs2 in
            fs1.compare(forList: fs2, followSymLinks: followSymLinks)
        }
    }

    func sort(
        byDate ascending: Bool,
        ignoreCase: Bool
    ) {
        sortChildren(ascending, ignoreCase: ignoreCase) { fs1, fs2 in
            guard let date1 = fs1.fileModificationDate else {
                return .orderedDescending
            }
            guard let date2 = fs2.fileModificationDate else {
                return .orderedAscending
            }
            return date1.compare(date2)
        }
    }

    func sort(
        byFileSize ascending: Bool,
        ignoreCase: Bool
    ) {
        sortChildren(ascending, ignoreCase: ignoreCase) { fs1, fs2 in
            if fs1.isFolder {
                return compare(fs1.subfoldersSize, fs2.subfoldersSize)
            }
            return compare(fs1.fileSize, fs2.fileSize)
        }
    }
}
