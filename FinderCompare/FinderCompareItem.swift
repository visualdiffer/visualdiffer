//
//  FinderCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/01/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Foundation

enum DisplaySide: Int {
    case left = 1
    case right
}

enum FileType {
    case file
    case directory

    init?(url: URL) throws {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey])
        guard let isDirectory = values.isDirectory else {
            return nil
        }

        self = isDirectory ? .directory : .file
    }
}

struct FinderCompareItem {
    let url: URL
    let type: FileType
    let side: DisplaySide

    init?(url: URL, side: DisplaySide) throws {
        guard let type = try FileType(url: url) else {
            return nil
        }
        self.url = url
        self.type = type
        self.side = side
    }

    func sidePlacement(for other: URL) -> (left: URL, right: URL) {
        switch side {
        case .left:
            (url, other)
        case .right:
            (other, url)
        }
    }
}

extension DisplaySide {
    func selectTitleFor(url: URL, fileType _: FileType) -> String {
        switch self {
        case .left:
            String.localizedStringWithFormat(
                NSLocalizedString("Select “%@” on Left", comment: ""), url.filename()
            )
        case .right:
            String.localizedStringWithFormat(
                NSLocalizedString("Select “%@” on Right", comment: ""), url.filename()
            )
        }
    }
}

extension FileType {
    func compareTitle(leftURL: URL, rightURL: URL) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString("Compare “%@” with “%@”", comment: ""),
            leftURL.filename(maxLength: 20),
            rightURL.filename(maxLength: 20)
        )
    }
}

extension URL {
    func filename(maxLength: Int = 30) -> String {
        let ellipsis = "..."
        let filename = lastPathComponent

        guard filename.count > maxLength else {
            return filename
        }

        return "\(filename.prefix(maxLength - ellipsis.count))\(ellipsis)"
    }
}
