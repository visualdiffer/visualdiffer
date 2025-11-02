//
//  CopyFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class CopyFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    var title = NSLocalizedString("Copy", comment: "")
    var summary = NSLocalizedString("Copy selected files and folders", comment: "")
    var image: NSImage?
    var progressLabel = NSLocalizedString("Copying", comment: "")
    var prefName: CommonPrefs.Name? = .confirmCopy

    private let side: DisplaySide

    private let items: [CompareItem]

    var operationOnSingleItem: Bool {
        items.count == 1 && items[0].isFile
    }

    private let srcBaseDir: String
    private let destBaseDir: String

    init(
        srcBaseDir: String,
        destBaseDir: String,
        items: [CompareItem],
        side: DisplaySide
    ) {
        self.srcBaseDir = srcBaseDir
        self.destBaseDir = destBaseDir
        self.side = side
        self.items = items

        image = NSImage(named: side == .left ? VDImageNameCopyRight : VDImageNameCopyLeft)
    }

    func execute(_ manager: FileOperationManagerAction, payload _: Sendable?) {
        for item in items {
            manager.copy(
                item,
                srcBaseDir: srcBaseDir,
                destBaseDir: destBaseDir
            )
        }
    }
}
