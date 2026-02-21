//
//  OutlineViewItemDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

/**
 * Used to inform when expansion/collapse is done on FoldersOutlineView
 * This is necessary to minimize the times the updates to UI (bottom bar) are called
 * The views in sync expand and collapse items and must take care to disable notification when necessary
 */
protocol OutlineViewItemDelegate: AnyObject {
    @MainActor
    func itemDidExpand(_ item: Any?, outlineView: NSOutlineView)
    @MainActor
    func itemDidCollapse(_ item: Any?, outlineView: NSOutlineView)
}
