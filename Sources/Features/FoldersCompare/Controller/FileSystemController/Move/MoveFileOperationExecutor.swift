//
//  MoveFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class MoveFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    var title = NSLocalizedString("Move", comment: "")
    var summary: String
    var image: NSImage?
    var progressLabel = NSLocalizedString("Moving", comment: "")
    var prefName: CommonPrefs.Name? = .confirmMove

    private let side: DisplaySide

    private let items: [CompareItem]

    var operationOnSingleItem: Bool {
        items.count == 1 && items[0].isFile
    }

    private let srcBaseDir: String
    private let destination: FileOperationDestination

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
            NSLocalizedString("Move selected files and folders", comment: "")
        case .external:
            NSLocalizedString("Move selected files and folders to external path", comment: "")
        }
        image = NSImage(named: side == .left ? VDImageNameMoveRight : VDImageNameMoveLeft)
    }

    func execute(_ manager: FileOperationManagerAction, payload _: Sendable?) {
        let operationBaseDir = destination.resolveOperationBaseDir(
            items: items,
            srcBaseDir: srcBaseDir
        )
        for item in items {
            manager.move(
                item,
                srcBaseDir: operationBaseDir,
                destination: destination
            )
        }
    }
}
