//
//  FoldersWindowController+FilePreview.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Quartz

enum FilePreviewMode {
    // each panel previews the file selected on its own side, the two can be on different rows
    case selectedFiles
    // both panels preview the two items of the same row
    case sameRow
}

extension FoldersWindowController {
    // the two panels are paired so they are always collapsed or expanded together
    var isFilePreviewHidden: Bool {
        leftPreviewSplitter.hasSubviewCollapsed
    }

    @objc
    func toggleFilePreview(_: AnyObject?) {
        leftPreviewSplitter.toggleSubview()
        updateFilePreview(from: lastUsedView)
    }

    @objc
    func hideFilePreview(_: AnyObject?) {
        leftPreviewSplitter.collapseSubview()
        updateFilePreview(from: lastUsedView)
    }

    @objc
    func showPreviewSelectedFiles(_: AnyObject?) {
        filePreviewMode = .selectedFiles
        updateFilePreview(from: lastUsedView)
    }

    @objc
    func showPreviewSameRow(_: AnyObject?) {
        filePreviewMode = .sameRow
        updateFilePreview(from: lastUsedView)
    }

    func updateFilePreview(from view: FoldersOutlineView) {
        if isFilePreviewHidden {
            // a hidden preview would keep the Quick Look resources of the last item
            leftPreviewView.show(nil)
            rightPreviewView.show(nil)
            return
        }

        switch filePreviewMode {
        case .selectedFiles:
            // each panel keeps its own selection, so a side is empty until something is picked on it
            leftPreviewView.show(previewItem(in: leftView, at: leftView.selectedRow))
            rightPreviewView.show(previewItem(in: rightView, at: rightView.selectedRow))
        case .sameRow:
            // both sides are row aligned so the same index addresses the linked item
            let row = view.selectedRow
            leftPreviewView.show(previewItem(in: leftView, at: row))
            rightPreviewView.show(previewItem(in: rightView, at: row))
        }
    }

    private func previewItem(in view: FoldersOutlineView, at row: Int) -> QLPreviewItem? {
        guard row >= 0,
              let vi = view.item(atRow: row) as? VisibleItem,
              vi.item.path != nil else {
            return nil
        }

        return vi
    }
}
