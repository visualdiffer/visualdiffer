//
//  FoldersOutlineView+Enumerate.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

extension FoldersOutlineView {
    func enumerateSelectedValidFiles(block: (_ fs: CompareItem, _ stop: inout Bool) -> Void) {
        enumerateSelectedFiles(true, block: block)
    }

    func enumerateSelectedFiles(_ onlyValid: Bool, block: (_ fs: CompareItem, _ stop: inout Bool) -> Void) {
        var stop = false

        for row in selectedRowIndexes {
            if let vi = item(atRow: row) as? VisibleItem {
                let item = vi.item
                let skip = onlyValid && !item.isValidFile
                if !skip {
                    block(item, &stop)

                    if stop {
                        break
                    }
                }
            }
        }
    }
}
