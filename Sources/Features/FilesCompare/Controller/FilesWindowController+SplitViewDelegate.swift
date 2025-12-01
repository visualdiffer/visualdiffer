//
//  FilesWindowController+SplitViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: NSSplitViewDelegate {
    func splitViewDidResizeSubviews(_: Notification) {
        rowHeightCalculator.reloadData()
    }
}
