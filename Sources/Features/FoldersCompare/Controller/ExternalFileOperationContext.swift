//
//  ExternalFileOperationContext.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/03/26.
//  Copyright (c) 2026 visualdiffer.com
//

@MainActor
struct ExternalFileOperationContext {
    let srcBaseDir: URL
    let destBaseDir: URL

    var destination: FileOperationDestination {
        .external(baseDir: destBaseDir)
    }

    static func create(
        from view: FoldersOutlineView,
        selectedItems: [CompareItem]
    ) -> ExternalFileOperationContext? {
        guard let vi = view.dataSource?.outlineView?(view, child: 0, ofItem: nil) as? VisibleItem,
              let root = vi.item.parent,
              let srcBaseDir = root.toUrl() else {
            return nil
        }

        guard let destBaseDir = srcBaseDir.promptUrl(
            at: srcBaseDir,
            title: NSLocalizedString("Select destination folder", comment: ""),
            chooseDirectories: true,
            chooseFiles: false,
            canCreateDirectories: true
        ) else {
            return nil
        }

        if containsInvalidPath(
            selectedItems: selectedItems,
            srcBasePath: srcBaseDir,
            destinationPath: destBaseDir
        ) {
            NSAlert(
                error: FolderManagerError.destinationContainsSelectedSource
            ).runModal()
            return nil
        }

        return ExternalFileOperationContext(
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir
        )
    }

    private init(
        srcBaseDir: URL,
        destBaseDir: URL
    ) {
        self.srcBaseDir = srcBaseDir
        self.destBaseDir = destBaseDir
    }

    private static func containsInvalidPath(
        selectedItems: [CompareItem],
        srcBasePath: URL,
        destinationPath: URL
    ) -> Bool {
        let normalizedDestinationPath = destinationPath.standardizingPath

        for item in selectedItems {
            guard let itemPath = item.path else {
                continue
            }
            guard let itemURL = item.toUrl() else {
                continue
            }
            let normalizedItemPath = URL(
                filePath: itemPath,
                directoryHint: item.isFolder ? .isDirectory : .notDirectory
            ).standardizingPath

            if normalizedDestinationPath == normalizedItemPath ||
                normalizedDestinationPath.hasPrefix("\(normalizedItemPath)/") {
                return true
            }
            let destinationItemPath = URL.buildDestinationPath(
                itemURL, nil, srcBasePath, destinationPath
            ).standardizingPath

            if destinationItemPath == normalizedItemPath || destinationItemPath.hasPrefix("\(normalizedItemPath)/") {
                return true
            }
        }
        return false
    }
}
