//
//  FilterConfig.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

public struct FilterConfig {
    public let showFilteredFiles: Bool
    public let hideEmptyFolders: Bool
    public let followSymLinks: Bool
    public let skipPackages: Bool
    public let traverseFilteredFolders: Bool
    public let predicate: NSPredicate?
    public let displayOptions: DisplayOptions
    public let fileExtraOptions: FileExtraOptions

    public init(
        showFilteredFiles: Bool,
        hideEmptyFolders: Bool,
        followSymLinks: Bool,
        skipPackages: Bool,
        traverseFilteredFolders: Bool,
        predicate: NSPredicate?,
        fileExtraOptions: FileExtraOptions,
        displayOptions: DisplayOptions
    ) {
        self.showFilteredFiles = showFilteredFiles
        self.hideEmptyFolders = hideEmptyFolders
        self.followSymLinks = followSymLinks
        self.skipPackages = skipPackages
        self.traverseFilteredFolders = traverseFilteredFolders
        self.predicate = predicate
        self.displayOptions = displayOptions
        self.fileExtraOptions = fileExtraOptions
    }
}

extension FilterConfig {
    init(
        from sessionDiff: SessionDiff,
        showFilteredFiles: Bool,
        hideEmptyFolders: Bool
    ) {
        self.init(
            showFilteredFiles: showFilteredFiles,
            hideEmptyFolders: hideEmptyFolders,
            followSymLinks: sessionDiff.followSymLinks,
            skipPackages: sessionDiff.skipPackages,
            traverseFilteredFolders: sessionDiff.traverseFilteredFolders,
            predicate: sessionDiff.exclusionFileFiltersPredicate,
            fileExtraOptions: sessionDiff.fileExtraOptions,
            displayOptions: sessionDiff.displayOptions
        )
    }
}
