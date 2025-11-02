//
//  FoldersWindowControllerTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping
final class FoldersWindowControllerTests: BaseTests {
    // This create a test case to generate the error trapped on
    // [FoldersWindowController (id)outlineView: outlineView child: (NSInteger)index ofItem: (id)item]
    @Test func savedFromArrayOutOfBound() throws {
        try removeItem("l")
        try removeItem("r")

        // create folders
        try createFolder("l/empty_folder1")
        try createFolder("r/empty_folder1")
        try createFolder("l/empty_folder2")
        try createFolder("r/folder_one_file_inside")

        // create files
        try createFile("r/folder_one_file_inside/AppDelegate.m", "12345")
    }

    @Test("This isn't a test but a way to prepare the folders for the test") func excludingByName() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: false,
            followSymLinks: false,
            skipPackages: false,
            traverseFilteredFolders: false,
            predicate: defaultPredicate,
            fileExtraOptions: [],
            displayOptions: .showAll
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
        try createFolder("l/folder1")
        try createFolder("r/folder1")
        try createFolder("l/folder1/folder2")
        try createFolder("r/folder1/folder2")

        // create files
        try createFile("l/folder1/folder2/file3.txt", "12345")
        try createFile("r/folder1/folder2/file3.txt", "12")
        try createFile("l/folder1/file2.txt", "12")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!

        let child1 = rootL.children[0] // l
        assertItem(child1, 0, 1, 1, 0, 2, "folder1", .orphan, 7)
        assertItem(child1.linkedItem, 0, 1, 0, 0, 2, "folder1", .orphan, 2)

        let child2 = child1.children[0] // folder1
        assertItem(child2, 0, 1, 0, 0, 1, "folder2", .orphan, 5)
        assertItem(child2.linkedItem, 0, 1, 0, 0, 1, "folder2", .orphan, 2)

        let child3 = child2.children[0] // folder2
        assertItem(child3, 0, 1, 0, 0, 0, "file3.txt", .changed, 5)
        assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "file3.txt", .changed, 2)

        let child4 = child1.children[1] // folder1
        assertItem(child4, 0, 0, 1, 0, 0, "file2.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
    }
}

// swiftlint:enable force_unwrapping
