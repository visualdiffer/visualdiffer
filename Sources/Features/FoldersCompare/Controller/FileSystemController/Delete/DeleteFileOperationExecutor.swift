//
//  DeleteFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DeleteFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    var title = NSLocalizedString("Delete", comment: "")
    var summary = NSLocalizedString("Delete selected files and folders", comment: "")
    var image: NSImage?
    var progressLabel = NSLocalizedString("Deleting", comment: "")
    var prefName: CommonPrefs.Name? = .confirmDelete

    private let items: [CompareItem]

    // delete operation doesn't use it
    var operationOnSingleItem = false

    private let srcBaseDir: String

    init(
        srcBaseDir: String,
        items: [CompareItem]
    ) {
        self.srcBaseDir = srcBaseDir
        self.items = items

        image = NSImage(named: VDImageNameDelete)
    }

    func execute(_ manager: FileOperationManagerAction, payload _: Sendable?) {
        for item in items {
            manager.delete(
                item,
                srcBaseDir: srcBaseDir
            )
        }
    }
}
