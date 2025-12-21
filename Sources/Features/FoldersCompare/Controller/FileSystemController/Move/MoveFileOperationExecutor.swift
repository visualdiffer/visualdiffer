//
//  MoveFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class MoveFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    var title = NSLocalizedString("Move", comment: "")
    var summary = NSLocalizedString("Move selected files and folders", comment: "")
    var image: NSImage?
    var progressLabel = NSLocalizedString("Moving", comment: "")
    var prefName: CommonPrefs.Name? = .confirmMove

    // periphery:ignore
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

        image = NSImage(named: side == .left ? VDImageNameMoveRight : VDImageNameMoveLeft)
    }

    func execute(_ manager: FileOperationManagerAction, payload _: Sendable?) {
        for item in items {
            manager.move(
                item,
                srcBaseDir: srcBaseDir,
                destBaseDir: destBaseDir
            )
        }
    }
}
