//
//  CompareItem+FilterConfig.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension CompareItem {
    @discardableResult
    func removeVisibleItems(
        filterConfig: FilterConfig,
        recursive: Bool = false
    ) -> Bool {
        removeVisibleItems(
            showFilteredFiles: filterConfig.showFilteredFiles,
            displayOptions: filterConfig.displayOptions,
            hideEmptyFolders: filterConfig.hideEmptyFolders,
            followSymLinks: filterConfig.followSymLinks,
            recursive: recursive
        )
    }
}
