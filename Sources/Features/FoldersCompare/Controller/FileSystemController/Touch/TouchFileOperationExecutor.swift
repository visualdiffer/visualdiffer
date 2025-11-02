//
//  TouchFileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class TouchFileOperationExecutor: FileOperationExecutor, @unchecked Sendable {
    var title = NSLocalizedString("Run", comment: "")
    var summary = NSLocalizedString("Set Modification Date for files and folders", comment: "")
    var image: NSImage?
    var progressLabel = NSLocalizedString("Setting modification date", comment: "")
    var prefName: CommonPrefs.Name?

    private let items: [CompareItem]

    // delete operation doesn't use it
    var operationOnSingleItem = false

    var touchDate: Date?
    var includeSubfolders = false

    init(items: [CompareItem]) {
        self.items = items

        image = NSImage(named: VDImageNameDateTime)
    }

    func execute(_ manager: FileOperationManagerAction, payload _: Sendable?) {
        for item in items {
            manager.touch(
                item,
                includeSubfolders: includeSubfolders,
                touch: touchDate
            )
        }
    }
}
