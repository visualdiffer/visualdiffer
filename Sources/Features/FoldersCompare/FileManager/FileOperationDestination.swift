//
//  FileOperationDestination.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/02/26.
//  Copyright (c) 2026 visualdiffer.com
//

public struct FileDestinationContext {
    let baseDir: URL
    let isLinkedSide: Bool
    let isExternal: Bool

    // resolves destination path using source item, source base dir and optional source url
    private let resolvePath: (CompareItem, URL, URL?) throws -> URL

    init(destination: FileOperationDestination) {
        baseDir = destination.baseDir

        switch destination {
        case let .linkedSide(baseDir):
            isLinkedSide = true
            isExternal = false
            resolvePath = { srcRoot, srcBaseDir, _ in
                srcRoot.buildDestinationPath(from: srcBaseDir, to: baseDir)
            }
        case let .external(baseDir):
            isLinkedSide = false
            isExternal = true
            resolvePath = { _, srcBaseDir, srcURL in
                guard let srcURL else {
                    throw FolderManagerError.nilPath
                }

                return URL.buildDestinationPath(srcURL, nil, srcBaseDir, baseDir)
            }
        }
    }

    func destinationPath(
        srcRoot: CompareItem,
        srcBaseDir: URL,
        srcURL: URL?
    ) throws -> URL {
        try resolvePath(srcRoot, srcBaseDir, srcURL)
    }

    func destinationRoot(for srcRoot: CompareItem) -> CompareItem? {
        isLinkedSide ? srcRoot.linkedItem : nil
    }
}

public enum FileOperationDestination: Sendable {
    case linkedSide(baseDir: URL)
    case external(baseDir: URL)

    var baseDir: URL {
        switch self {
        case let .linkedSide(baseDir):
            baseDir
        case let .external(baseDir):
            baseDir
        }
    }

    // periphery:ignore
    var isLinkedSide: Bool {
        if case .linkedSide = self {
            return true
        }
        return false
    }

    var isExternal: Bool {
        if case .external = self {
            return true
        }
        return false
    }
}

extension FileOperationDestination {
    func resolveOperationBaseDir(
        items: [CompareItem],
        srcBaseDir: String
    ) -> String {
        guard isExternal else {
            return srcBaseDir
        }

        if items.count == 1 {
            return items[0].parent?.path ?? srcBaseDir
        }
        return CompareItem.commonAncestorPath(items) ?? srcBaseDir
    }
}
