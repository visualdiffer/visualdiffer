//
//  RecentDocumentPopupMenu.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

private let showRecentDocumentsListPrefName = "showRecentDocumentsList"

class RecentDocumentPopupMenu: PopUpButtonUrl, NSMenuDelegate {
    init(title _: String, target: AnyObject?, action: Selector?) {
        super.init(
            title: NSLocalizedString("Open Recent", comment: ""),
            target: target,
            action: action,
            delegate: nil
        )

        menu?.delegate = self
    }

    func refresh() {
        let showRecentDocumentsList = UserDefaults.standard.bool(forKey: showRecentDocumentsListPrefName)
        let hasRecentDocuments = !NSDocumentController.shared.recentDocumentURLs.isEmpty
        isHidden = !(showRecentDocumentsList && hasRecentDocuments)
    }

    // MARK: - Main menu methods

    func menuNeedsUpdate(_: NSMenu) {
        let documentURLs = NSDocumentController.shared.recentDocumentURLs.sorted {
            $0.lastPathComponent.caseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }

        clear()
        fill(documentURLs)
    }
}
