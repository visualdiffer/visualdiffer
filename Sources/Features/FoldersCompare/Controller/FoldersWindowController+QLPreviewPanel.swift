//
//  FoldersWindowController+QLPreviewPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Quartz

// swiftlint:disable implicitly_unwrapped_optional
extension FoldersWindowController: @preconcurrency QLPreviewPanelDataSource,
    @preconcurrency QLPreviewPanelDelegate {
    @objc func togglePreviewPanel(_: AnyObject?) {
        QLPreviewPanel.toggle()
    }

    override open func acceptsPreviewPanelControl(_: QLPreviewPanel!) -> Bool {
        true
    }

    override open func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        // This document is now responsible of the preview panel
        // It is allowed to set the delegate, data source and refresh panel.
        MainActor.assumeIsolated {
            previewPanel = panel
            panel.delegate = self
            panel.dataSource = self
        }
    }

    override open func endPreviewPanelControl(_: QLPreviewPanel!) {
        // This document loses its responsibility on the preview panel
        // Until the next call to -beginPreviewPanelControl: it must not
        // change the panel's delegate, data source or refresh it.
        MainActor.assumeIsolated {
            previewPanel = nil
        }
    }

    // MARK: - Quick Look panel data source

    public func numberOfPreviewItems(in _: QLPreviewPanel!) -> Int {
        lastUsedView.selectionInfo.validObjectsIndexes.count
    }

    public func previewPanel(_: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        let row = lastUsedView.selectionInfo.validObjectsIndexes[index]
        return lastUsedView.item(atRow: row) as? VisibleItem
    }

    public func previewPanel(_: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        // redirect all key down events to the table view
        if event.type == .keyDown {
            lastUsedView.keyDown(with: event)
            return true
        }
        return false
    }

    // This delegate method provides the rect on screen from which the panel will zoom.
    public func previewPanel(_: QLPreviewPanel!, sourceFrameOnScreenFor item: (any QLPreviewItem)!) -> NSRect {
        let index = lastUsedView.row(forItem: item)

        if index == NSNotFound {
            return .zero
        }

        var iconRect = lastUsedView.frameOfCell(atColumn: 0, row: index)

        // check that the icon rect is visible on screen
        let visibleRect = lastUsedView.visibleRect

        if !visibleRect.intersects(iconRect) {
            return .zero
        }

        // convert icon rect to screen coordinates
        iconRect = lastUsedView.convert(iconRect, to: nil)
        if let window = lastUsedView.window {
            iconRect = window.convertToScreen(iconRect)
        }

        return iconRect
    }
}

// swiftlint:enable implicitly_unwrapped_optional
