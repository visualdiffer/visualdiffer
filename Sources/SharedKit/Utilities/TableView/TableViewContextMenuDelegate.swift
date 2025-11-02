//
//  TableViewContextMenuDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 03/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

protocol TableViewContextMenuDelegate: AnyObject {
    @MainActor func tableView(_ tableView: NSTableView, menuItem: NSMenuItem, hideMenuItem hide: inout Bool) -> Bool
}
