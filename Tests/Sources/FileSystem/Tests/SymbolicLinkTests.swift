//
//  SymbolicLinkTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class SymbolicLinkTests: BaseTests {
    @Test
    func symbolicLinkLoop() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: false,
            followSymLinks: true,
            skipPackages: false,
            traverseFilteredFolders: false,
            predicate: defaultPredicate,
            fileExtraOptions: [],
            displayOptions: .onlyMismatches
        )
        let folderReaderDelegate = MockFolderReaderDelegate(isRunning: true)
        let folderReader = FolderReader(
            with: folderReaderDelegate,
            comparator: comparator,
            filterConfig: filterConfig,
            refreshInfo: RefreshInfo(initState: true)
        )

        try removeItem("l")
        try removeItem("r")

        // create folders
        try createFolder("l/parent")
        try createSymlink("l/parent/sym_parent", "../parent")

        try createFolder("r")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        assertErrors(
            folderReaderDelegate.errors, [
                FileError.symlinkLoop(path: appendFolder("l/parent/sym_parent").osPath),
            ]
        )
    }
}
