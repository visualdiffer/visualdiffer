//
//  TableViewCommon.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/04/14.
//  Copyright (c) 2014 visualdiffer.com
//

protocol TableViewCommonDelegate: AnyObject {
    @MainActor func tableViewCommonKeyDown(_ tableView: NSTableView, event: NSEvent) -> Bool
}

class TableViewCommon: NSTableView {
    override func keyDown(with event: NSEvent) {
        if let delegate = delegate as? TableViewCommonDelegate {
            if delegate.tableViewCommonKeyDown(self, event: event) {
                return
            }
        }
        super.keyDown(with: event)
    }
}
