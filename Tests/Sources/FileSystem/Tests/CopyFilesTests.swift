//
//  CopyFilesTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class CopyFilesTests: BaseTests {
    @Test
    func copyFilesOnlyMatches() throws {
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

        try createFile("r/a/bb/ccc/file.txt", "123456789012")
        try createFile("r/a/bb/ccc/second.txt", "123456789")

        try setFileTimestamp("l/a/bb/ccc/second.txt", "2001-03-24 10: 45: 32 +0600")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var child1 = rootL.children[0]
        assertItem(child1, 1, 0, 0, 0, 1, "a", .orphan, 12)
        assertItem(child1.linkedItem, 0, 1, 1, 0, 1, "a", .orphan, 21)

        var child2 = child1.children[0]
        assertItem(child2, 1, 0, 0, 0, 1, "bb", .orphan, 12)
        assertItem(child2.linkedItem, 0, 1, 1, 0, 1, "bb", .orphan, 21)

        var child3 = child2.children[0]
        assertItem(child3, 1, 0, 0, 0, 2, "ccc", .orphan, 12)
        assertItem(child3.linkedItem, 0, 1, 1, 0, 2, "ccc", .orphan, 21)

        var child4 = child3.children[0]
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file.txt", .orphan, 12)

        var child5 = child3.children[1]
        assertItem(child5, 1, 0, 0, 0, 0, "second.txt", .old, 12)
        assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "second.txt", .changed, 9)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 0, 0, 0, 1, "a", .orphan, 12)
            assertItem(child1.linkedItem, 0, 1, 1, 0, 1, "a", .orphan, 21)

            let childVI2 = childVI1.children[0] // a <--> a
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // a <-> a
            assertItem(child2, 1, 0, 0, 0, 1, "bb", .orphan, 12)
            assertItem(child2.linkedItem, 0, 1, 1, 0, 1, "bb", .orphan, 21)

            let childVI3 = childVI2.children[0] // bb <--> bb
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // bb <-> bb
            assertItem(child3, 1, 0, 0, 0, 2, "ccc", .orphan, 12)
            assertItem(child3.linkedItem, 0, 1, 1, 0, 2, "ccc", .orphan, 21)

            let childVI4 = childVI3.children[0] // ccc <--> ccc
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // ccc <-> ccc
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file.txt", .orphan, 12)

            let childVI5 = childVI3.children[1] // ccc <--> ccc
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // ccc <-> ccc
            assertItem(child5, 1, 0, 0, 0, 0, "second.txt", .old, 12)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "second.txt", .changed, 9)
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
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: child2,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 1, 1, "a", .orphan, 12)
        assertItem(child1.linkedItem, 0, 0, 1, 1, 1, "a", .orphan, 24)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 1, 1, "bb", .orphan, 12)
        assertItem(child2.linkedItem, 0, 0, 1, 1, 1, "bb", .orphan, 24)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 1, 2, "ccc", .orphan, 12)
        assertItem(child3.linkedItem, 0, 0, 1, 1, 2, "ccc", .orphan, 24)

        child4 = child3.children[0]
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file.txt", .orphan, 12)

        child5 = child3.children[1]
        assertItem(child5, 0, 0, 0, 1, 0, "second.txt", .same, 12)
        assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "second.txt", .same, 12)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "a", .orphan, 12)
            assertItem(child1.linkedItem, 0, 0, 1, 1, 1, "a", .orphan, 24)

            let childVI2 = childVI1.children[0] // a <--> a
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // a <-> a
            assertItem(child2, 0, 0, 0, 1, 1, "bb", .orphan, 12)
            assertItem(child2.linkedItem, 0, 0, 1, 1, 1, "bb", .orphan, 24)

            let childVI3 = childVI2.children[0] // bb <--> bb
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // bb <-> bb
            assertItem(child3, 0, 0, 0, 1, 2, "ccc", .orphan, 12)
            assertItem(child3.linkedItem, 0, 0, 1, 1, 2, "ccc", .orphan, 24)

            let childVI4 = childVI3.children[0] // ccc <--> ccc
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // ccc <-> ccc
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file.txt", .orphan, 12)

            let childVI5 = childVI3.children[1] // ccc <--> ccc
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // ccc <-> ccc
            assertItem(child5, 0, 0, 0, 1, 0, "second.txt", .same, 12)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "second.txt", .same, 12)
        }
    }

    @Test
    func copyFilesReplaceNoToAll() throws {
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
        try createFolder("l/folder_0/folder_1")
        try createFolder("r/folder_0/folder_1")

        // create files
        try createFile("l/folder_0/folder_1/file_1.txt", "1234567890")
        try setFileTimestamp("l/folder_0/folder_1/file_1.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/folder_0/folder_1/file_1.txt", "1234")

        try createFile("l/folder_0/file_2.txt", "1234567890")
        try createFile("r/folder_0/file_2.txt", "1234567")
        try setFileTimestamp("r/folder_0/file_2.txt", "2001-03-24 10: 45: 32 +0600")

        try createFile("r/folder_0/file_3.h", "123")
        try createFile("r/folder_0/file_3.m", "12")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var child1 = rootL.children[0]
        assertItem(child1, 1, 1, 0, 0, 4, "folder_0", .orphan, 20)
        assertItem(child1.linkedItem, 1, 1, 2, 0, 4, "folder_0", .orphan, 16)

        var child2 = child1.children[0]
        assertItem(child2, 1, 0, 0, 0, 1, "folder_1", .orphan, 10)
        assertItem(child2.linkedItem, 0, 1, 0, 0, 1, "folder_1", .orphan, 4)

        var child3 = child2.children[0]
        assertItem(child3, 1, 0, 0, 0, 0, "file_1.txt", .old, 10)
        assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "file_1.txt", .changed, 4)

        var child4 = child1.children[1]
        assertItem(child4, 0, 1, 0, 0, 0, "file_2.txt", .changed, 10)
        assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_2.txt", .old, 7)

        var child5 = child1.children[2]
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_3.h", .orphan, 3)

        var child6 = child1.children[3]
        assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file_3.m", .orphan, 2)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 4)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 1, 0, 0, 4, "folder_0", .orphan, 20)
            assertItem(child1.linkedItem, 1, 1, 2, 0, 4, "folder_0", .orphan, 16)

            let childVI2 = childVI1.children[0] // folder_0 <--> folder_0
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_0 <-> folder_0
            assertItem(child2, 1, 0, 0, 0, 1, "folder_1", .orphan, 10)
            assertItem(child2.linkedItem, 0, 1, 0, 0, 1, "folder_1", .orphan, 4)

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 1, 0, 0, 0, 0, "file_1.txt", .old, 10)
            assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "file_1.txt", .changed, 4)

            let childVI4 = childVI1.children[1] // folder_0 <--> folder_0
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder_0 <-> folder_0
            assertItem(child4, 0, 1, 0, 0, 0, "file_2.txt", .changed, 10)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_2.txt", .old, 7)

            let childVI5 = childVI1.children[2] // folder_0 <--> folder_0
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_0 <-> folder_0
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_3.h", .orphan, 3)

            let childVI6 = childVI1.children[3] // folder_0 <--> folder_0
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_0 <-> folder_0
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file_3.m", .orphan, 2)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        // src is on right so folders are inverted

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        try fileOperation.copy(
            srcRoot: #require(child1.linkedItem),
            srcBaseDir: appendFolder("r"),
            destBaseDir: appendFolder("l")
        )

        child1 = rootL.children[0]
        assertItem(child1, 0, 1, 0, 3, 4, "folder_0", .orphan, 19)
        assertItem(child1.linkedItem, 1, 0, 0, 3, 4, "folder_0", .orphan, 16)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 1, 1, "folder_1", .orphan, 4)
        assertItem(child2.linkedItem, 0, 0, 0, 1, 1, "folder_1", .orphan, 4)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 1, 0, "file_1.txt", .same, 4)
        assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "file_1.txt", .same, 4)

        child4 = child1.children[1]
        assertItem(child4, 0, 1, 0, 0, 0, "file_2.txt", .changed, 10)
        assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_2.txt", .old, 7)

        child5 = child1.children[2]
        assertItem(child5, 0, 0, 0, 1, 0, "file_3.h", .same, 3)
        assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file_3.h", .same, 3)

        child6 = child1.children[3]
        assertItem(child6, 0, 0, 0, 1, 0, "file_3.m", .same, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file_3.m", .same, 2)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 4)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 1, 0, 3, 4, "folder_0", .orphan, 19)
            assertItem(child1.linkedItem, 1, 0, 0, 3, 4, "folder_0", .orphan, 16)

            let childVI2 = childVI1.children[0] // folder_0 <--> folder_0
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_0 <-> folder_0
            assertItem(child2, 0, 0, 0, 1, 1, "folder_1", .orphan, 4)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 1, "folder_1", .orphan, 4)

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 0, 0, 0, 1, 0, "file_1.txt", .same, 4)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "file_1.txt", .same, 4)

            let childVI4 = childVI1.children[1] // folder_0 <--> folder_0
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder_0 <-> folder_0
            assertItem(child4, 0, 1, 0, 0, 0, "file_2.txt", .changed, 10)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_2.txt", .old, 7)

            let childVI5 = childVI1.children[2] // folder_0 <--> folder_0
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_0 <-> folder_0
            assertItem(child5, 0, 0, 0, 1, 0, "file_3.h", .same, 3)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file_3.h", .same, 3)

            let childVI6 = childVI1.children[3] // folder_0 <--> folder_0
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_0 <-> folder_0
            assertItem(child6, 0, 0, 0, 1, 0, "file_3.m", .same, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file_3.m", .same, 2)
        }
    }

    @Test
    func copyOrphan() throws {
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
        try createFolder("l/only_on_left")
        try createFolder("l/only_on_left/second_folder")
        try createFolder("l/only_on_left/second_folder/cartella senza titolo")
        try createFolder("l/only_on_left/second_folder/cartella senza titolo 2")

        try createFolder("r")

        // create files
        try createFile("l/only_on_left/second_folder/symlinks copia.zip", "12345")
        try createFile("l/only_on_left/symlinks.zip", "12")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

        var child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

        var child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child5 = child2.children[2]
        assertItem(child5, 0, 0, 0, 0, 0, "symlinks copia.zip", .orphan, 5)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child6 = child1.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, "symlinks.zip", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 2, nil, .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> (null)
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // only_on_left <-> (null)
            assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // second_folder <--> (null)
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // second_folder <-> (null)
            assertItem(child3, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[1] // second_folder <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // second_folder <-> (null)
            assertItem(child4, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: child2,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 2, "only_on_left", .orphan, 0)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "second_folder", .orphan, 0)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)

        child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)

        child5 = child2.children[2]
        assertItem(child5, 0, 0, 0, 0, 0, "symlinks copia.zip", .orphan, 5)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child6 = child1.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, "symlinks.zip", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 2, "only_on_left", .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> only_on_left
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // only_on_left <-> only_on_left
            assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "second_folder", .orphan, 0)

            let childVI3 = childVI2.children[0] // second_folder <--> second_folder
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // second_folder <-> second_folder
            assertItem(child3, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)

            let childVI4 = childVI2.children[1] // second_folder <--> second_folder
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // second_folder <-> second_folder
            assertItem(child4, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)
        }
    }

    @Test
    func copyFilesPresentOnBothSidesWithFiltered() throws {
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
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_changed.m", "12345")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_matched.txt", "1234")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_older.txt", "12345")
        try createFile("l/folder_1/folder_1_2/match_2_1.m", "12")
        try createFile("l/folder_1/file.txt", "1")

        try createFile("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "1")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_matched.txt", "1234")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_older.txt", "1")
        try createFile("r/folder_1/folder_1_2/match_2_1.m", "12")
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

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let l = rootL.children[0]
        assertItem(l, 1, 1, 0, 3, 4, "folder_1", .orphan, 17)
        assertItem(l.linkedItem, 1, 1, 1, 3, 4, "folder_1", .orphan, 16)

        var child1 = l.children[0]
        assertItem(child1, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 14)
        assertItem(child1.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 6)

        var child2 = child1.children[0]
        assertItem(child2, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 14)
        assertItem(child2.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 6)

        var child3 = child2.children[0]
        assertItem(child3, 0, 1, 0, 0, 0, "file_changed.m", .changed, 5)
        assertItem(child3.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 1)

        var child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 1, 0, "file_matched.txt", .same, 4)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 4)

        var child5 = child2.children[2]
        assertItem(child5, 1, 0, 0, 0, 0, "file_older.txt", .old, 5)
        assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 1)

        var child6 = l.children[1]
        assertItem(child6, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)

        var child7 = child6.children[0]
        assertItem(child7, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)

        var child8 = l.children[2]
        assertItem(child8, 0, 0, 0, 1, 0, "file.txt", .same, 1)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 1)

        var child9 = l.children[3]
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)

        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 1, 1, 0, 3, 1, "l", .orphan, 17)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 1, 1, 3, 1, "r", .orphan, 16)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 1, 1, 0, 3, 4, "folder_1", .orphan, 17)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 1, 1, 3, 4, "folder_1", .orphan, 16)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 14)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 6)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI4.children, 2)
            let child4 = childVI4.item // folder_1_1 <-> folder_1_1
            assertItem(child4, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 14)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 6)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 1, 0, 0, 0, "file_changed.m", .changed, 5)
            assertItem(child5.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 1)

            let childVI6 = childVI4.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_2_1 <-> folder_2_1
            assertItem(child6, 1, 0, 0, 0, 0, "file_older.txt", .old, 5)
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
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: child1,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 0, 5, 4, "folder_1", .orphan, 17)
        assertItem(child1.linkedItem, 0, 0, 1, 5, 4, "folder_1", .orphan, 24)

        child2 = child1.children[0] // folder_1
        assertItem(child2, 0, 0, 0, 3, 1, "folder_1_1", .orphan, 14)
        assertItem(child2.linkedItem, 0, 0, 0, 3, 1, "folder_1_1", .orphan, 14)

        child3 = child2.children[0] // folder_1_1
        assertItem(child3, 0, 0, 0, 3, 3, "folder_2_1", .orphan, 14)
        assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "folder_2_1", .orphan, 14)

        child4 = child3.children[0] // folder_2_1
        assertItem(child4, 0, 0, 0, 1, 0, "file_changed.m", .same, 5)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_changed.m", .same, 5)

        child5 = child3.children[1] // folder_2_1
        assertItem(child5, 0, 0, 0, 1, 0, "file_matched.txt", .same, 4)
        assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 4)

        child6 = child3.children[2] // folder_2_1
        assertItem(child6, 0, 0, 0, 1, 0, "file_older.txt", .same, 5)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file_older.txt", .same, 5)

        child7 = child1.children[1] // folder_1
        assertItem(child7, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)

        child8 = child7.children[0] // folder_1_2
        assertItem(child8, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)

        child9 = child1.children[2] // folder_1
        assertItem(child9, 0, 0, 0, 1, 0, "file.txt", .same, 1)
        assertItem(child9.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 1)

        let child10 = child1.children[3] // folder_1
        assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 5, 1, "l", .orphan, 17)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 1, 5, 1, "r", .orphan, 24)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 5, 4, "folder_1", .orphan, 17)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 1, 5, 4, "folder_1", .orphan, 24)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        }
    }

    @Test
    func copyDontFollowSymLink() throws {
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
        try createFolder("l/folder1/folder2/folder3")
        try createSymlink("l/folder1/folder2/symlink1", "symlink_test1")

        try createFolder("r/folder1")
        try createFolder("r/folder1/folder2")

        // folders out of comparison but used to create symlinks to them
        try createFolder("symlink_test1")
        try createFolder("symlink_test2")

        // create files
        try createSymlink("r/folder1/folder2/folder3", "symlink_test1")
        try createSymlink("r/folder1/folder2/symlink1", "symlink_test2")
        try createSymlink("r/folder1/folder2/orphan_symlink", "symlink_test2")

        try createFile("symlink_test1/file1.txt", "12345")
        try createFile("symlink_test2/file2.txt", "123")
        try createFile("r/folder1/folder2/sample.txt", "12")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
        assertItem(child1.linkedItem, 0, 0, 1, 0, 1, "folder1", .orphan, 2)

        var child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 0, 0, 5, "folder2", .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 1, 0, 5, "folder2", .orphan, 2)

        var child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child4 = child2.children[1] // folder2
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)

        var child5 = child2.children[2] // folder2
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "orphan_symlink", .orphan, 0)

        var child6 = child2.children[3] // folder2
        assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "sample.txt", .orphan, 2)

        var child7 = child2.children[4] // folder2
        assertItem(child7, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 1, 0, 1, "folder1", .orphan, 2)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 4)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 0, 0, 5, "folder2", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 5, "folder2", .orphan, 2)

            let childVI3 = childVI2.children[0] // folder2 <--> folder2
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder2 <-> folder2
            assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[1] // folder2 <--> folder2
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder2 <-> folder2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)

            let childVI5 = childVI2.children[2] // folder2 <--> folder2
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder2 <-> folder2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "orphan_symlink", .orphan, 0)

            let childVI6 = childVI2.children[3] // folder2 <--> folder2
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder2 <-> folder2
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "sample.txt", .orphan, 2)
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: true
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        try fileOperation.copy(
            srcRoot: #require(child2.linkedItem),
            srcBaseDir: appendFolder("r"),
            destBaseDir: appendFolder("l")
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 0, 1, 1, "folder1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "folder1", .orphan, 2)

        child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 0, 1, 5, "folder2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 1, 5, "folder2", .orphan, 2)

        child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child4 = child2.children[1] // folder2
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        try assertSymlink(#require(child4.linkedItem), "symlink_test1", true)

        child5 = child2.children[2] // folder2
        assertItem(child5, 0, 0, 0, 0, 0, "orphan_symlink", .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "orphan_symlink", .orphan, 0)
        try assertSymlink(child5, "symlink_test2", true)
        try assertSymlink(#require(child5.linkedItem), "symlink_test2", true)

        child6 = child2.children[3] // folder2
        assertItem(child6, 0, 0, 0, 1, 0, "sample.txt", .same, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "sample.txt", .same, 2)

        child7 = child2.children[4] // folder2
        assertItem(child7, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
        try assertSymlink(child7, "symlink_test2", true)
        try assertSymlink(#require(child7.linkedItem), "symlink_test2", true)

        try assertErrors(fileOperationDelegate.errors, [
            FileError.createSymLink(path: #require(child3.path)),
        ])

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "folder1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "folder1", .orphan, 2)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 0, 1, 5, "folder2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 5, "folder2", .orphan, 2)

            let childVI3 = childVI2.children[0] // folder2 <--> folder2
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder2 <-> folder2
            assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[1] // folder2 <--> folder2
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder2 <-> folder2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        }
    }

    @Test
    func copyFollowSymLink() throws {
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
        try createFolder("l/folder1")
        try createFolder("l/folder1/folder2")
        try createFolder("l/folder1/folder2/folder3")
        try createSymlink("l/folder1/folder2/symlink1", "symlink_test1")

        try createFolder("r/folder1")
        try createFolder("r/folder1/folder2")

        // folders out of comparison but used to create symlinks to them
        try createFolder("symlink_test1")
        try createFolder("symlink_test2")

        // create files
        try createSymlink("r/folder1/folder2/folder3", "symlink_test1")
        try createSymlink("r/folder1/folder2/symlink1", "symlink_test2")
        try createSymlink("r/folder1/folder2/orphan_symlink", "symlink_test2")

        try createFile("symlink_test1/file1.txt", "12345")
        try createFile("symlink_test1/file2.txt", "123")
        try createFile("symlink_test2/file2.txt", "123")
        try createFile("r/folder1/folder2/sample.txt", "12")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 1, 1, "folder1", .orphan, 8)
        assertItem(child1.linkedItem, 0, 0, 4, 1, 1, "folder1", .orphan, 16)

        var child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 1, 1, 4, "folder2", .orphan, 8)
        assertItem(child2.linkedItem, 0, 0, 4, 1, 4, "folder2", .orphan, 16)

        var child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 0, 2, "folder3", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 2, 0, 2, "folder3", .orphan, 8)

        var child4 = child3.children[0] // folder3
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file1.txt", .orphan, 5)

        var child5 = child3.children[1] // folder3
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 3)

        var child6 = child2.children[1] // folder2
        assertItem(child6, 0, 0, 0, 0, 1, nil, .orphan, 0)
        assertItem(child6.linkedItem, 0, 0, 1, 0, 1, "orphan_symlink", .orphan, 3)

        var child7 = child6.children[0] // (null)
        assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 3)

        var child8 = child2.children[2] // folder2
        assertItem(child8, 0, 0, 1, 1, 2, "symlink1", .orphan, 8)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 2, "symlink1", .orphan, 3)

        var child9 = child8.children[0] // symlink1
        assertItem(child9, 0, 0, 1, 0, 0, "file1.txt", .orphan, 5)
        assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child10 = child8.children[1] // symlink1
        assertItem(child10, 0, 0, 0, 1, 0, "file2.txt", .same, 3)
        assertItem(child10.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 3)

        var child11 = child2.children[3] // folder2
        assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "sample.txt", .orphan, 2)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 1, 1, "folder1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 4, 1, 1, "folder1", .orphan, 16)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 4)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 1, 1, 4, "folder2", .orphan, 8)
            assertItem(child2.linkedItem, 0, 0, 4, 1, 4, "folder2", .orphan, 16)

            let childVI3 = childVI2.children[0] // folder2 <--> folder2
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // folder2 <-> folder2
            assertItem(child3, 0, 0, 0, 0, 2, "folder3", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 2, 0, 2, "folder3", .orphan, 8)

            let childVI4 = childVI3.children[0] // folder3 <--> folder3
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder3 <-> folder3
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file1.txt", .orphan, 5)

            let childVI5 = childVI3.children[1] // folder3 <--> folder3
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder3 <-> folder3
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 3)

            let childVI6 = childVI2.children[1] // folder2 <--> folder2
            assertArrayCount(childVI6.children, 1)
            let child6 = childVI6.item // folder2 <-> folder2
            assertItem(child6, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 1, "orphan_symlink", .orphan, 3)

            let childVI7 = childVI6.children[0] // (null) <--> orphan_symlink
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // (null) <-> orphan_symlink
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 3)

            let childVI8 = childVI2.children[2] // folder2 <--> folder2
            assertArrayCount(childVI8.children, 1)
            let child8 = childVI8.item // folder2 <-> folder2
            assertItem(child8, 0, 0, 1, 1, 2, "symlink1", .orphan, 8)
            assertItem(child8.linkedItem, 0, 0, 0, 1, 2, "symlink1", .orphan, 3)

            let childVI9 = childVI8.children[0] // symlink1 <--> symlink1
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // symlink1 <-> symlink1
            assertItem(child9, 0, 0, 1, 0, 0, "file1.txt", .orphan, 5)
            assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI10 = childVI2.children[3] // folder2 <--> folder2
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // folder2 <-> folder2
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "sample.txt", .orphan, 2)
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        try fileOperation.copy(
            srcRoot: #require(child2.linkedItem),
            srcBaseDir: appendFolder("r"),
            destBaseDir: appendFolder("l")
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 5, 1, "folder1", .orphan, 21)
        assertItem(child1.linkedItem, 0, 0, 0, 5, 1, "folder1", .orphan, 16)

        child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 1, 5, 4, "folder2", .orphan, 21)
        assertItem(child2.linkedItem, 0, 0, 0, 5, 4, "folder2", .orphan, 16)

        child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 2, 2, "folder3", .orphan, 8)
        assertItem(child3.linkedItem, 0, 0, 0, 2, 2, "folder3", .orphan, 8)

        child4 = child3.children[0] // folder3
        assertItem(child4, 0, 0, 0, 1, 0, "file1.txt", .same, 5)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 5)

        child5 = child3.children[1] // folder3
        assertItem(child5, 0, 0, 0, 1, 0, "file2.txt", .same, 3)
        assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 3)

        child6 = child2.children[1] // folder2
        assertItem(child6, 0, 0, 0, 1, 1, "orphan_symlink", .orphan, 3)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 1, "orphan_symlink", .orphan, 3)

        child7 = child6.children[0] // orphan_symlink
        assertItem(child7, 0, 0, 0, 1, 0, "file2.txt", .same, 3)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 3)

        child8 = child2.children[2] // folder2
        assertItem(child8, 0, 0, 1, 1, 2, "symlink1", .orphan, 8)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 2, "symlink1", .orphan, 3)

        child9 = child8.children[0] // symlink1
        assertItem(child9, 0, 0, 1, 0, 0, "file1.txt", .orphan, 5)
        assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child10 = child8.children[1] // symlink1
        assertItem(child10, 0, 0, 0, 1, 0, "file2.txt", .same, 3)
        assertItem(child10.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 3)

        child11 = child2.children[3] // folder2
        assertItem(child11, 0, 0, 0, 1, 0, "sample.txt", .same, 2)
        assertItem(child11.linkedItem, 0, 0, 0, 1, 0, "sample.txt", .same, 2)
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 1, 5, 1, "l", .orphan, 21)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 5, 1, "r", .orphan, 16)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 1, 5, 1, "folder1", .orphan, 21)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 5, 1, "folder1", .orphan, 16)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // folder1 <--> folder1
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder1 <-> folder1
            assertItem(child3, 0, 0, 1, 5, 4, "folder2", .orphan, 21)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 5, 4, "folder2", .orphan, 16)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // folder2 <--> folder2
            assertArrayCount(childVI4.children, 1)
            let child4 = childVI4.item // folder2 <-> folder2
            assertItem(child4, 0, 0, 1, 1, 2, "symlink1", .orphan, 8)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 0, 1, 2, "symlink1", .orphan, 3)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // symlink1 <--> symlink1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // symlink1 <-> symlink1
            assertItem(child5, 0, 0, 1, 0, 0, "file1.txt", .orphan, 5)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test
    func copyFailure() throws {
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
        try createFolder("l/dir1")
        try createFolder("r/dir1")
        try createFolder("l/dir1/dir2")
        try createFolder("l/dir1/dir2/dir3")

        // create files
        try createFile("l/dir1/dir2/dir3/file1.txt", "1234567")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 7)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

        let child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 1, 0, 1, "dir2", .orphan, 7)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        let child3 = child2.children[0] // dir2
        assertItem(child3, 0, 0, 1, 0, 1, "dir3", .orphan, 7)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        let child4 = child3.children[0] // dir3
        assertItem(child4, 0, 0, 1, 0, 0, "file1.txt", .orphan, 7)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        // simulate a copy error deleting the file to copy
        do {
            try fm.removeItem(atPath: #require(child4.path))
        } catch {
            Issue.record("Found error \(error)")
        }

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 1, "dir2", .orphan, 7)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // dir2 <--> (null)
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // dir2 <-> (null)
            assertItem(child3, 0, 0, 1, 0, 1, "dir3", .orphan, 7)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI4 = childVI3.children[0] // dir3 <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // dir3 <-> (null)
            assertItem(child4, 0, 0, 1, 0, 0, "file1.txt", .orphan, 7)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: child4,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0] // l
        do {
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let child2 = child1.children[0] // dir1
            assertItem(child2, 0, 0, 1, 0, 1, "dir2", .orphan, 7)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child3 = child2.children[0] // dir2
            assertItem(child3, 0, 0, 1, 0, 1, "dir3", .orphan, 7)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child4 = child3.children[0] // dir3
            assertItem(child4, 0, 0, 1, 0, 0, "file1.txt", .orphan, 7)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 7)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 1, "dir2", .orphan, 7)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // dir2 <--> (null)
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // dir2 <-> (null)
            assertItem(child3, 0, 0, 1, 0, 1, "dir3", .orphan, 7)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI4 = childVI3.children[0] // dir3 <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // dir3 <-> (null)
            assertItem(child4, 0, 0, 1, 0, 0, "file1.txt", .orphan, 7)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test
    func copyPreserveFolderTimestamp() throws {
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

        try createFolder("l/folder1/folder2/folder3")
        try createFolder("r/folder1")

        try createFile("l/folder1/folder2/folder3/file1.txt", "12")

        try setFileCreationTime("l/folder1", "2010-01-01 00: 00: 00 +0000")
        try setFileTimestamp("l/folder1", "2010-02-02 02: 02: 00 +0000")

        try setFileCreationTime("l/folder1/folder2", "2010-04-04 04: 04: 00 +0000")
        try setFileTimestamp("l/folder1/folder2", "2010-05-05 05: 05: 00 +0000")

        try setFileCreationTime("l/folder1/folder2/folder3", "2011-05-05 05: 00: 30 +0000")
        try setFileTimestamp("l/folder1/folder2/folder3", "2011-06-06 06: 00: 30 +0000")

        try setFileCreationTime("l/folder1/folder2/folder3/file1.txt", "2012-07-07 09: 09: 00 +0000")
        try setFileTimestamp("l/folder1/folder2/folder3/file1.txt", "2012-08-08 10: 10: 10 +0000")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 0, 1, "folder1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

        let child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 1, 0, 1, "folder2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        let child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 1, 0, 1, "folder3", .orphan, 2)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        let child4 = child3.children[0] // folder3
        assertItem(child4, 0, 0, 1, 0, 0, "file1.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "folder1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 1, 0, 1, "folder2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // folder2 <--> (null)
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder2 <-> (null)
            assertItem(child3, 0, 0, 1, 0, 1, "folder3", .orphan, 2)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI4 = childVI3.children[0] // folder3 <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder3 <-> (null)
            assertItem(child4, 0, 0, 1, 0, 0, "file1.txt", .orphan, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: child1,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 0, 1, 1, "folder1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "folder1", .orphan, 2)
            try assertTimestamps(child1.linkedItem, "2010-01-01 00: 00: 00 +0000", "2010-02-02 02: 02: 00 +0000")

            let child2 = child1.children[0] // folder1
            assertItem(child2, 0, 0, 0, 1, 1, "folder2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 1, "folder2", .orphan, 2)
            try assertTimestamps(child2.linkedItem, "2010-04-04 04: 04: 00 +0000", "2010-05-05 05: 05: 00 +0000")

            let child3 = child2.children[0] // folder2
            assertItem(child3, 0, 0, 0, 1, 1, "folder3", .orphan, 2)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 1, "folder3", .orphan, 2)
            try assertTimestamps(child3.linkedItem, "2011-05-05 05: 00: 30 +0000", "2011-06-06 06: 00: 30 +0000")

            let child4 = child3.children[0] // folder3
            assertItem(child4, 0, 0, 0, 1, 0, "file1.txt", .same, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 2)
            try assertTimestamps(child4.linkedItem, "2012-07-07 09: 09: 00 +0000", "2012-08-08 10: 10: 10 +0000")
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "folder1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "folder1", .orphan, 2)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 0, 1, 1, "folder2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 1, "folder2", .orphan, 2)

            let childVI3 = childVI2.children[0] // folder2 <--> folder2
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder2 <-> folder2
            assertItem(child3, 0, 0, 0, 1, 1, "folder3", .orphan, 2)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 1, "folder3", .orphan, 2)

            let childVI4 = childVI3.children[0] // folder3 <--> folder3
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder3 <-> folder3
            assertItem(child4, 0, 0, 0, 1, 0, "file1.txt", .same, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 2)
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
