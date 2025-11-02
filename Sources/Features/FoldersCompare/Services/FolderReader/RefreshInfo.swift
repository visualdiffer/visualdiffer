//
//  RefreshInfo.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

public struct RefreshInfo {
    let refreshFolders: Bool
    let realign: Bool
    let refreshComparison: Bool
    let expandAllFolders: Bool

    init(
        initState: Bool,
        realign: Bool? = nil,
        refreshComparison: Bool? = nil,
        expandAllFolders: Bool? = nil
    ) {
        refreshFolders = initState
        // refresh folders forces reAlign
        self.realign = refreshFolders ? true : realign ?? initState
        // reAlign forces refreshComparison
        self.refreshComparison = self.realign ? true : refreshComparison ?? initState
        self.expandAllFolders = expandAllFolders ?? initState
    }
}
