//
//  FoldersWindowController+DisplayFiltersScopeBarDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: @preconcurrency DisplayFiltersScopeBarDelegate {
    func displayFiltersScopeBar(_: DisplayFiltersScopeBar, action: DisplayFiltersScopeBarAction, options: [DisplayFiltersScopeBarAttributeKey: Any]?) {
        switch action {
        case .selectFilter:
            select(displayOptions: options?[.filterFlagsDisplayFilters] as? NSNumber)
        case .showFiltered:
            toggleFilteredFiles(nil)
        case .showEmptyFolders:
            showEmptyFolders(nil)
        case .showNoOrphansFolders:
            noOrphansFolders(nil)
        }
    }

    func select(displayOptions newFlags: NSNumber?) {
        guard let newFlags = newFlags?.intValue else {
            return
        }
        let displayOptions = sessionDiff.displayOptions.changeWithoutMethod(newFlags)
        sessionDiff.displayOptions = displayOptions
        let refreshInfo = RefreshInfo(
            initState: false,
            expandAllFolders: sessionDiff.expandAllFolders
        )
        reloadAll(refreshInfo)
    }
}
