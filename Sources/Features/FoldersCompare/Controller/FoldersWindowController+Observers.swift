//
//  FoldersWindowController+Observers.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import UserNotifications

private final class RefreshItemComparatorDelegate: ItemComparatorDelegate {
    var isRunning: Bool

    init(isRunning: Bool = true) {
        self.isRunning = isRunning
    }

    func isRunning(_: ItemComparator) -> Bool {
        isRunning
    }
}

extension FoldersWindowController {
    func setupObservers() {
        // a register for those notifications on the synchronized content view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fontDidChange),
            name: .prefsChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshCompareItem),
            name: .fileSaved,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appAppearanceDidChange),
            name: .appAppearanceDidChange,
            object: nil
        )

        let comparatorOptionsObservation = sessionDiff.observeComparatorOptions { flags in
            Task { @MainActor in
                self.comparatorMethod = flags.onlyMethodFlags
            }
        }

        observations.append(contentsOf: [comparatorOptionsObservation])

        UNUserNotificationCenter.current().delegate = self
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: .prefsChanged,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .fileSaved,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .appAppearanceDidChange,
            object: nil
        )

        observations.forEach { $0.invalidate() }

        // don't show notification if this window is closing
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    @objc
    func appAppearanceDidChange(_: Notification) {
        leftView.reloadData()
        rightView.reloadData()

        updateStatusBar()
    }

    @objc
    func refreshCompareItem(_ notification: Notification) {
        guard let comparator,
              let userInfo = notification.userInfo as? [FileSavedKey: String],
              let (item, itemSide) = resolveCompareItem(fromUserInfo: userInfo) else {
            return
        }

        let filterConfig = FilterConfig(
            from: sessionDiff,
            showFilteredFiles: showFilteredFiles,
            hideEmptyFolders: hideEmptyFolders
        )

        // handle the case where a missing counterpart was created by the save operation
        if let orphan = item.path == nil ? item : item.linkedItem?.path == nil ? item.linkedItem : nil,
           let path = userInfo[itemSide == .left ? .rightPath : .leftPath],
           orphan.linkedItem?.fileName == URL(filePath: path).lastPathComponent,
           let attrs = try? FileManager.default.attributesOfItem(atPath: path) {
            orphan.path = path
            orphan.setAttributes(attrs, fileExtraOptions: filterConfig.fileExtraOptions)
        }

        // capture before refresh - may be filtered out after type changes to .same
        let anchor = item.visibleItem

        let refreshDelegate = RefreshItemComparatorDelegate()
        let refreshComparator = comparator.copy(delegate: refreshDelegate)

        withExtendedLifetime(refreshDelegate) {
            item.refresh(
                filterConfig: filterConfig,
                comparator: refreshComparator
            )
        }

        leftView.reloadData()
        rightView.reloadData()

        restoreSelectionAfterRefresh(
            item: item,
            anchor: anchor,
            view: itemSide == .left ? leftView : rightView,
            limitToCurrentFolder: false
        )
    }

    private func resolveCompareItem(
        fromUserInfo userInfo: [FileSavedKey: String?]
    ) -> (item: CompareItem, itemSide: DisplaySide)? {
        guard let leftItemOriginal,
              let rightItemOriginal,
              let sessionLeftPath = sessionDiff.leftPath,
              let sessionRightPath = sessionDiff.rightPath else {
            return nil
        }

        if let leftPath = userInfo[.leftPath] as? String {
            if leftPath.hasPrefix(sessionLeftPath),
               let item = CompareItem.find(withPath: leftPath, from: leftItemOriginal) {
                return (item, .left)
            }
            if leftPath.hasPrefix(sessionRightPath),
               let item = CompareItem.find(withPath: leftPath, from: rightItemOriginal) {
                return (item, .right)
            }
        }

        if let rightPath = userInfo[.rightPath] as? String {
            if rightPath.hasPrefix(sessionLeftPath),
               let item = CompareItem.find(withPath: rightPath, from: leftItemOriginal) {
                return (item, .left)
            }
            if rightPath.hasPrefix(sessionRightPath),
               let item = CompareItem.find(withPath: rightPath, from: rightItemOriginal) {
                return (item, .right)
            }
        }

        return nil
    }

    @objc
    func fontDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let target = userInfo[PrefChangedKey.target] as? PrefChangedKey.Target else {
            return
        }

        if target == .folder {
            fontZoomFactor = 0
        }
    }

    private func restoreSelectionAfterRefresh(
        item: CompareItem,
        anchor: VisibleItem?,
        view: FoldersOutlineView,
        limitToCurrentFolder: Bool
    ) {
        // item still visible after refresh - select it directly
        if let vi = item.visibleItem, view.row(forItem: vi) >= 0 {
            view.select(visibleItems: [vi], scrollToFirst: true, center: true, selectLinked: true)
            return
        }

        // item filtered out - use anchor as starting point for findNearest
        guard let vi = anchor else {
            return
        }

        // try next first, then fall back to previous
        let parentPath = item.parent?.path
        if let found = findNearest(
            view: view,
            item: vi,
            parentPath: parentPath,
            direction: .next,
            limitToCurrentFolder: limitToCurrentFolder
        ),
            let nextVI = view.item(atRow: found.row) as? VisibleItem {
            view.select(visibleItems: [nextVI], scrollToFirst: true, center: true, selectLinked: true)
            return
        }

        if let found = findNearest(
            view: view,
            item: vi,
            parentPath: parentPath,
            direction: .previous,
            limitToCurrentFolder: limitToCurrentFolder
        ),
            let prevVI = view.item(atRow: found.row) as? VisibleItem {
            view.select(visibleItems: [prevVI], scrollToFirst: true, center: true, selectLinked: true)
        }
    }
}
