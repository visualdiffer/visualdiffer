//
//  CopyFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class CopyFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    var title = NSLocalizedString("Copy", comment: "")
    var summary: String
    var image: NSImage?
    var progressLabel = NSLocalizedString("Copying", comment: "")
    var prefName: CommonPrefs.Name? = .confirmCopy

    private let side: DisplaySide

    private let items: [CompareItem]
    private let srcBaseDir: String
    private let destination: FileOperationDestination

    var operationOnSingleItem: Bool {
        items.count == 1 && items[0].isFile
    }

    init(
        srcBaseDir: String,
        destination: FileOperationDestination,
        items: [CompareItem],
        side: DisplaySide
    ) {
        self.srcBaseDir = srcBaseDir
        self.destination = destination
        self.side = side
        self.items = items

        summary = switch destination {
        case .linkedSide:
            NSLocalizedString("Copy selected files and folders", comment: "")
        case .external:
            NSLocalizedString("Copy selected files and folders to external path", comment: "")
        }
        image = NSImage(named: side == .left ? VDImageNameCopyRight : VDImageNameCopyLeft)
    }

    func execute(_ manager: FileOperationManagerAction, payload _: Sendable?) {
        for item in items {
            manager.copy(
                item,
                srcBaseDir: srcBaseDir,
                destination: destination
            )
        }
    }
}
