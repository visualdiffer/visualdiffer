//
//  DeleteFileTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class DeleteFileTests: BaseTests {
    /**
     * Delete folder with files on right: there is an orphan file and a newer file
     */
    @Test func deleteCreatingOrphan() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
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

        try createFolder("l/a/bb/ccc")
        try createFolder("r/a/bb/ccc")

        try createFile("l/a/bb/ccc/second.txt", "123456789012")

        try createFile("r/a/bb/ccc/file.txt", "123")
        try createFile("r/a/bb/ccc/second.txt", "12345678")

        try setFileTimestamp("l/a/bb/ccc/second.txt", "2001-03-24 10: 45: 32 +0600")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        let vi = rootL.visibleItem!

        var l = rootL.children[0]
        assertItem(l, 1, 0, 0, 0, 1, "a", .orphan, 12)
        assertItem(l.linkedItem, 0, 1, 1, 0, 1, "a", .orphan, 11)

        var child1 = l.children[0]
        assertItem(child1, 1, 0, 0, 0, 1, "bb", .orphan, 12)
        assertItem(child1.linkedItem, 0, 1, 1, 0, 1, "bb", .orphan, 11)

        var child2 = child1.children[0]
        assertItem(child2, 1, 0, 0, 0, 2, "ccc", .orphan, 12)
        assertItem(child2.linkedItem, 0, 1, 1, 0, 2, "ccc", .orphan, 11)

        var child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file.txt", .orphan, 3)

        let child4 = child2.children[1]
        assertItem(child4, 1, 0, 0, 0, 0, "second.txt", .old, 12)
        assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "second.txt", .changed, 8)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 0, 0, 0, 1, "a", .orphan, 12)
            assertItem(child1.linkedItem, 0, 1, 1, 0, 1, "a", .orphan, 11)

            let childVI2 = childVI1.children[0] // a <--> a
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // a <-> a
            assertItem(child2, 1, 0, 0, 0, 1, "bb", .orphan, 12)
            assertItem(child2.linkedItem, 0, 1, 1, 0, 1, "bb", .orphan, 11)

            let childVI3 = childVI2.children[0] // bb <--> bb
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // bb <-> bb
            assertItem(child3, 1, 0, 0, 0, 2, "ccc", .orphan, 12)
            assertItem(child3.linkedItem, 0, 1, 1, 0, 2, "ccc", .orphan, 11)

            let childVI4 = childVI3.children[0] // ccc <--> ccc
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // ccc <-> ccc
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file.txt", .orphan, 3)

            let childVI5 = childVI3.children[1] // ccc <--> ccc
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // ccc <-> ccc
            assertItem(child5, 1, 0, 0, 0, 0, "second.txt", .old, 12)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "second.txt", .changed, 8)
        }

        try assertOnlySetup()

        let fileOperaionDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperaionDelegate
        )
        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)

        fileOperation.delete(
            child2.linkedItem!,
            baseDir: appendFolder("r")
        )

        l = rootL.children[0]
        assertItem(l, 0, 0, 1, 0, 1, "a", .orphan, 12)
        assertItem(l.linkedItem, 0, 0, 0, 0, 1, "a", .orphan, 0)

        child1 = l.children[0]
        assertItem(child1, 0, 0, 1, 0, 1, "bb", .orphan, 12)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "bb", .orphan, 0)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 1, 0, 1, "ccc", .orphan, 12)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 1, 0, 0, "second.txt", .orphan, 12)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "a", .orphan, 12)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "a", .orphan, 0)

            let childVI2 = childVI1.children[0] // a <--> a
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // a <-> a
            assertItem(child2, 0, 0, 1, 0, 1, "bb", .orphan, 12)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "bb", .orphan, 0)

            let childVI3 = childVI2.children[0] // bb <--> bb
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // bb <-> bb
            assertItem(child3, 0, 0, 1, 0, 1, "ccc", .orphan, 12)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI4 = childVI3.children[0] // ccc <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // ccc <-> (null)
            assertItem(child4, 0, 0, 1, 0, 0, "second.txt", .orphan, 12)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    /**
     * Delete the folder on left including filtered files
     * Folder is orphan
     */
    @Test func deleteOrphanWithFiltered() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/only_on_left/second_folder/subfolder1")
        try createFolder("l/only_on_left/second_folder/subfolder2")

        try createFile("l/only_on_left/second_folder/test1.zip", "123456789")
        try createFile("l/only_on_left/test2.zip", "123456789")
        try createFile("l/.DS_Store", "1234567890123")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        var l = rootL.children[0]
        assertItem(l, 0, 0, 0, 0, 2, "only_on_left", .orphan, 18)
        assertItem(l.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

        let child1 = l.children[0]
        assertItem(child1, 0, 0, 0, 0, 3, "second_folder", .orphan, 9)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

        let child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 0, "subfolder1", .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child3 = child1.children[1]
        assertItem(child3, 0, 0, 0, 0, 0, "subfolder2", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child4 = child1.children[2]
        assertItem(child4, 0, 0, 0, 0, 0, "test1.zip", .orphan, 9)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child5 = l.children[1]
        assertItem(child5, 0, 0, 0, 0, 0, "test2.zip", .orphan, 9)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child6 = rootL.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, ".DS_Store", .orphan, 13)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 18)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> (null)
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // only_on_left <-> (null)
            assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 9)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // second_folder <--> (null)
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // second_folder <-> (null)
            assertItem(child3, 0, 0, 0, 0, 0, "subfolder1", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[1] // second_folder <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // second_folder <-> (null)
            assertItem(child4, 0, 0, 0, 0, 0, "subfolder2", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI2.children[2] // second_folder <--> (null)
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // second_folder <-> (null)
            assertItem(child5, 0, 0, 0, 0, 0, "test1.zip", .orphan, 9)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI1.children[1] // only_on_left <--> (null)
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // only_on_left <-> (null)
            assertItem(child6, 0, 0, 0, 0, 0, "test2.zip", .orphan, 9)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)

        fileOperation.delete(
            child1,
            baseDir: appendFolder("l/only_on_left/second_folder")
        )

        l = rootL.children[0]
        assertItem(l, 0, 0, 0, 0, 1, "only_on_left", .orphan, 9)
        assertItem(l.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        child5 = l.children[0]
        assertItem(child5, 0, 0, 0, 0, 0, "test2.zip", .orphan, 9)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child6 = rootL.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, ".DS_Store", .orphan, 13)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "only_on_left", .orphan, 9)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> (null)
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // only_on_left <-> (null)
            assertItem(child2, 0, 0, 0, 0, 0, "test2.zip", .orphan, 9)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    /**
     * Delete the folder on left, filtered files remain
     * Folder is orphan
     */
    @Test func deleteOrphanLeaveFiltered() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/only_on_left/second_folder/subfolder1")
        try createFolder("l/only_on_left/second_folder/subfolder2")
        try createFile("l/only_on_left/second_folder/test1.zip", "12345")
        try createFile("l/only_on_left/test2.zip", "12")
        try createFile("l/.DS_Store", "123456")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        var l = rootL.children[0]
        assertItem(l, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
        assertItem(l.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

        var child1 = l.children[0]
        assertItem(child1, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

        var child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 0, "subfolder1", .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child3 = child1.children[1]
        assertItem(child3, 0, 0, 0, 0, 0, "subfolder2", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child4 = child1.children[2]
        assertItem(child4, 0, 0, 0, 0, 0, "test1.zip", .orphan, 5)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child5 = l.children[1]
        assertItem(child5, 0, 0, 0, 0, 0, "test2.zip", .orphan, 2)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child6 = rootL.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, ".DS_Store", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> (null)
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // only_on_left <-> (null)
            assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // second_folder <--> (null)
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // second_folder <-> (null)
            assertItem(child3, 0, 0, 0, 0, 0, "subfolder1", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[1] // second_folder <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // second_folder <-> (null)
            assertItem(child4, 0, 0, 0, 0, 0, "subfolder2", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI2.children[2] // second_folder <--> (null)
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // second_folder <-> (null)
            assertItem(child5, 0, 0, 0, 0, 0, "test1.zip", .orphan, 5)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI1.children[1] // only_on_left <--> (null)
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // only_on_left <-> (null)
            assertItem(child6, 0, 0, 0, 0, 0, "test2.zip", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)

        fileOperation.delete(
            child1,
            baseDir: appendFolder("l/only_on_left/second_folder")
        )

        l = rootL.children[0]
        assertItem(l, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
        assertItem(l.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

        child1 = l.children[0]
        assertItem(child1, 0, 0, 0, 0, 1, "second_folder", .orphan, 5)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 0, "test1.zip", .orphan, 5)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child5 = l.children[1]
        assertItem(child5, 0, 0, 0, 0, 0, "test2.zip", .orphan, 2)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child6 = rootL.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, ".DS_Store", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> (null)
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // only_on_left <-> (null)
            assertItem(child2, 0, 0, 0, 0, 1, "second_folder", .orphan, 5)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // second_folder <--> (null)
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // second_folder <-> (null)
            assertItem(child3, 0, 0, 0, 0, 0, "test1.zip", .orphan, 5)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI1.children[1] // only_on_left <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // only_on_left <-> (null)
            assertItem(child4, 0, 0, 0, 0, 0, "test2.zip", .orphan, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func deleteFilesPresentOnBothSides() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
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
        try createFolder("l/folder_1/folder_1_1/folder_2_1")
        try createFolder("l/folder_1/folder_1_2")

        try createFolder("r/folder_1/folder_1_1/folder_2_1")
        try createFolder("r/folder_1/folder_1_2")

        // create files
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_changed.m", "123456")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_matched.txt", "12")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_older.txt", "123")
        try createFile("l/folder_1/folder_1_2/match_2_1.m", "1234")
        try createFile("l/folder_1/file.txt", "1")

        try createFile("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "1234")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_matched.txt", "12")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_older.txt", "1")
        try createFile("r/folder_1/folder_1_2/match_2_1.m", "1234")
        try createFile("r/folder_1/file.txt", "1")
        try createFile("r/folder_1/right_orphan.txt", "1234567")

        try setFileTimestamp("l/folder_1/folder_1_1/folder_2_1/file_older.txt", "2001-03-24 10: 45: 32 +0600")
        try setFileTimestamp("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "2001-03-24 10: 45: 32 +0600")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        let l = rootL.children[0]
        assertItem(l, 1, 1, 0, 3, 4, "folder_1", .orphan, 16)
        assertItem(l.linkedItem, 1, 1, 1, 3, 4, "folder_1", .orphan, 19)

        let child1 = l.children[0]
        assertItem(child1, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 11)
        assertItem(child1.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 7)

        let child2 = child1.children[0]
        assertItem(child2, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 11)
        assertItem(child2.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 7)

        let child3 = child2.children[0]
        assertItem(child3, 0, 1, 0, 0, 0, "file_changed.m", .changed, 6)
        assertItem(child3.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 4)

        let child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)

        let child5 = child2.children[2]
        assertItem(child5, 1, 0, 0, 0, 0, "file_older.txt", .old, 3)
        assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 1)

        let child6 = l.children[1]
        assertItem(child6, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 4)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 4)

        let child7 = child6.children[0]
        assertItem(child7, 0, 0, 0, 1, 0, "match_2_1.m", .same, 4)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 4)

        let child8 = l.children[2]
        assertItem(child8, 0, 0, 0, 1, 0, "file.txt", .same, 1)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 1)

        let child9 = l.children[3]
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)

        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 1, 1, 0, 3, 1, "l", .orphan, 16)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 1, 1, 3, 1, "r", .orphan, 19)
            #expect(child1.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 1, 1, 0, 3, 4, "folder_1", .orphan, 16)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 1, 1, 3, 4, "folder_1", .orphan, 19)
            #expect(child2.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 11)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 7)
            #expect(child3.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI4.children, 2)
            let child4 = childVI4.item // folder_1_1 <-> folder_1_1
            assertItem(child4, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 11)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 7)
            #expect(child4.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 1, 0, 0, 0, "file_changed.m", .changed, 6)
            assertItem(child5.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 4)

            let childVI6 = childVI4.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_2_1 <-> folder_2_1
            assertItem(child6, 1, 0, 0, 0, 0, "file_older.txt", .old, 3)
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 1)

            let childVI7 = childVI2.children[1] // folder_1 <--> folder_1
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // folder_1 <-> folder_1
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes

        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)

        fileOperation.delete(
            child1,
            baseDir: appendFolder("l")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 3, 1, "l", .orphan, 7)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 3, 3, 1, "r", .orphan, 19)
            #expect(child1.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 3, 4, "folder_1", .orphan, 7)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 3, 3, 4, "folder_1", .orphan, 19)
            #expect(child2.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // folder_1 <-> folder_1
            assertItem(child3, 0, 0, 0, 1, 1, "folder_1_1", .orphan, 2)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 2, 1, 1, "folder_1_1", .orphan, 7)
            #expect(child3.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // folder_1_1 <-> folder_1_1
            assertItem(child4, 0, 0, 0, 1, 3, "folder_2_1", .orphan, 2)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 2, 1, 3, "folder_2_1", .orphan, 7)
            #expect(child4.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let child5 = child4.children[0] // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 4)

            let child6 = child4.children[1] // folder_2_1 <-> folder_2_1
            assertItem(child6, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)

            let child7 = child4.children[2] // folder_2_1 <-> folder_2_1
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 1)

            let child8 = child2.children[1] // folder_1 <-> folder_1
            assertItem(child8, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 4)
            #expect(child8.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 4)
            #expect(child8.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.linkedItem!.orphanFolders)")

            let child9 = child8.children[0] // folder_1_2 <-> folder_1_2
            assertItem(child9, 0, 0, 0, 1, 0, "match_2_1.m", .same, 4)
            assertItem(child9.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 4)

            let child10 = child2.children[2] // folder_1 <-> folder_1
            assertItem(child10, 0, 0, 0, 1, 0, "file.txt", .same, 1)
            assertItem(child10.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 1)

            let child11 = child2.children[3] // folder_1 <-> folder_1
            assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 3, 1, "l", .orphan, 7)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 3, 3, 1, "r", .orphan, 19)
            #expect(child1.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 3, 4, "folder_1", .orphan, 7)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 3, 3, 4, "folder_1", .orphan, 19)
            #expect(child2.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 0, 0, 0, 1, 1, "folder_1_1", .orphan, 2)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 2, 1, 1, "folder_1_1", .orphan, 7)
            #expect(child3.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI4.children, 2)
            let child4 = childVI4.item // folder_1_1 <-> folder_1_1
            assertItem(child4, 0, 0, 0, 1, 3, "folder_2_1", .orphan, 2)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 2, 1, 3, "folder_2_1", .orphan, 7)
            #expect(child4.linkedItem!.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 4)

            let childVI6 = childVI4.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_2_1 <-> folder_2_1
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 1)

            let childVI7 = childVI2.children[1] // folder_1 <--> folder_1
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // folder_1 <-> folder_1
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        }
    }

    @Test func deleteDontFollowSymLink() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
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
        try createFolder("l/folder1")
        try createFolder("l/folder1/folder2")

        try createFolder("r/folder1")

        // folders out of comparison but used to create symlinks to them
        try createFolder("symlink_test1")
        try createFolder("symlink_test2")

        // create files
        try createSymlink("l/folder1/folder2/folder3", "symlink_test2")
        try createSymlink("l/folder1/folder2/symlink1", "symlink_test1")

        try createFile("symlink_test1/file1.txt", "12345")
        try createFile("symlink_test1/file1_1.txt", "12")
        try createFile("symlink_test2/file2.txt", "123")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        var child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

        let child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 0, 0, 2, "folder2", .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

        let child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        try assertSymlink(child3, "symlink_test2", true)

        let child4 = child2.children[1] // folder2
        assertItem(child4, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        try assertSymlink(child4, "symlink_test1", true)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 0, 0, 2, "folder2", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // folder2 <--> (null)
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder2 <-> (null)
            assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[1] // folder2 <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder2 <-> (null)
            assertItem(child4, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes

        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)

        fileOperation.delete(
            child2,
            baseDir: appendFolder("l")
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 0, 0, 0, "folder1", .orphan, 0)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 0, "folder1", .orphan, 0)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 0)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 0, "folder1", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 0, "folder1", .orphan, 0)
        }
    }

    @Test func deleteFolderCreatingOnlyOrphans() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
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
        try createFolder("l/dir1")
        try createFolder("r/dir1")
        try createFolder("l/dir1/dir2")
        try createFolder("r/dir1/dir2")
        try createFolder("l/dir1/dir2/dir3")
        try createFolder("r/dir1/dir2/dir3")

        // create files
        try createFile("l/dir1/dir2/dir3/file_2.txt", "1234567890")
        try createFile("r/dir1/dir2/dir3/file_2.txt", "1234567890")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        let child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 0, 1, 1, "dir1", .orphan, 10)
        assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "dir1", .orphan, 10)

        let child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 0, 1, 1, "dir2", .orphan, 10)
        assertItem(child2.linkedItem, 0, 0, 0, 1, 1, "dir2", .orphan, 10)

        let child3 = child2.children[0] // dir2
        assertItem(child3, 0, 0, 0, 1, 1, "dir3", .orphan, 10)
        assertItem(child3.linkedItem, 0, 0, 0, 1, 1, "dir3", .orphan, 10)

        let child4 = child3.children[0] // dir3
        assertItem(child4, 0, 0, 0, 1, 0, "file_2.txt", .same, 10)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_2.txt", .same, 10)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)

        fileOperation.delete(
            child2.linkedItem!,
            baseDir: appendFolder("r")
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 10)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let child2 = child1.children[0] // dir1
            assertItem(child2, 0, 0, 1, 0, 1, "dir2", .orphan, 10)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child3 = child2.children[0] // dir2
            assertItem(child3, 0, 0, 1, 0, 1, "dir3", .orphan, 10)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child4 = child3.children[0] // dir3
            assertItem(child4, 0, 0, 1, 0, 0, "file_2.txt", .orphan, 10)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 10)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 1, "dir2", .orphan, 10)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // dir2 <--> (null)
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // dir2 <-> (null)
            assertItem(child3, 0, 0, 1, 0, 1, "dir3", .orphan, 10)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI4 = childVI3.children[0] // dir3 <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // dir3 <-> (null)
            assertItem(child4, 0, 0, 1, 0, 0, "file_2.txt", .orphan, 10)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
