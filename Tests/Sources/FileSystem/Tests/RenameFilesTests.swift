//
//  RenameFilesTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/04/13.
//  Copyright (c) 2013 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class RenameFilesTests: BaseTests {
    @Test func renameFileOrphan() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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

        try createFolder("l/dir1")
        try createFolder("r/dir1")

        try createFile("l/dir1/100.txt", "12")

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
        assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

        var child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 1, 0, 0, "100.txt", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child2,
            toName: "110.txt"
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

        child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func renameFileOrphanToOrphan() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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

        // create folders
        try createFolder("l/dir1")
        try createFolder("r/dir1")
        try createFolder("l/dir1/dir2")
        try createFolder("r/dir1/dir2")

        // create files
        try createFile("r/dir1/dir2/010.txt", "123")
        try createFile("l/dir1/dir2/100.txt", "12")
        try createFile("r/dir1/dir2/109.txt", "1234")
        try createFile("l/dir1/011.txt", "123456")

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
        assertItem(child1, 0, 0, 2, 0, 2, "dir1", .orphan, 8)
        assertItem(child1.linkedItem, 0, 0, 2, 0, 2, "dir1", .orphan, 7)

        let child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 1, 0, 3, "dir2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 2, 0, 3, "dir2", .orphan, 7)

        let child3 = child2.children[0] // dir2
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

        let child4 = child2.children[1] // dir2
        assertItem(child4, 0, 0, 1, 0, 0, "100.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child5 = child2.children[2] // dir2
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "109.txt", .orphan, 4)

        let child6 = child1.children[1] // dir1
        assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)
        fileOperation.rename(
            srcRoot: child4,
            toName: "110.txt"
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 2, 0, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 2, 0, 2, "dir1", .orphan, 7)

            let child2 = child1.children[0] // dir1
            assertItem(child2, 0, 0, 1, 0, 3, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 2, 0, 3, "dir2", .orphan, 7)

            let child3 = child2.children[0] // dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let child4 = child2.children[1] // dir2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "109.txt", .orphan, 4)

            let child5 = child2.children[2] // dir2
            assertItem(child5, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child6 = child1.children[1] // dir1
            assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        // must be recreated
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 2, 0, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 2, 0, 2, "dir1", .orphan, 7)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 3, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 2, 0, 3, "dir2", .orphan, 7)

            let childVI3 = childVI2.children[0] // dir2 <--> dir2
            let child3 = childVI3.item // dir2 <-> dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let childVI4 = childVI2.children[1] // dir2 <--> dir2
            let child4 = childVI4.item // dir2 <-> dir2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "109.txt", .orphan, 4)

            let childVI5 = childVI2.children[2] // dir2 <--> dir2
            let child5 = childVI5.item // dir2 <-> dir2
            assertItem(child5, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI1.children[1] // dir1 <--> dir1
            let child6 = childVI6.item // dir1 <-> dir1
            assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func renameFileOrphanToMatching() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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

        // create folders
        try createFolder("l/dir1")
        try createFolder("r/dir1")
        try createFolder("l/dir1/dir2")
        try createFolder("r/dir1/dir2")

        // create files
        try createFile("r/dir1/dir2/010.txt", "123")
        try createFile("l/dir1/dir2/100.txt", "12")
        try createFile("r/dir1/dir2/109.txt", "1234")
        try createFile("l/dir1/011.txt", "123456")

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
        assertItem(child1, 0, 0, 2, 0, 2, "dir1", .orphan, 8)
        assertItem(child1.linkedItem, 0, 0, 2, 0, 2, "dir1", .orphan, 7)

        let child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 1, 0, 3, "dir2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 2, 0, 3, "dir2", .orphan, 7)

        let child3 = child2.children[0] // dir2
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

        let child4 = child2.children[1] // dir2
        assertItem(child4, 0, 0, 1, 0, 0, "100.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child5 = child2.children[2] // dir2
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "109.txt", .orphan, 4)

        let child6 = child1.children[1] // dir1
        assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child4,
            toName: "109.txt"
        )

        do {
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 0, 1, 1, 0, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 1, 1, 0, 2, "dir1", .orphan, 7)

            let child2 = child1.children[0] // dir1 <-> dir1
            assertItem(child2, 0, 1, 0, 0, 2, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 1, 1, 0, 2, "dir2", .orphan, 7)

            let child3 = child2.children[0] // dir2 <-> dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let child4 = child2.children[1] // dir2 <-> dir2
            assertItem(child4, 0, 1, 0, 0, 0, "109.txt", .changed, 2)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "109.txt", .changed, 4)

            let child5 = child1.children[1] // dir1 <-> dir1
            assertItem(child5, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 1, 1, 0, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 1, 1, 0, 2, "dir1", .orphan, 7)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 1, 0, 0, 2, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 1, 1, 0, 2, "dir2", .orphan, 7)

            let childVI3 = childVI2.children[0] // dir2 <--> dir2
            let child3 = childVI3.item // dir2 <-> dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let childVI4 = childVI2.children[1] // dir2 <--> dir2
            let child4 = childVI4.item // dir2 <-> dir2
            assertItem(child4, 0, 1, 0, 0, 0, "109.txt", .changed, 2)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "109.txt", .changed, 4)

            let childVI5 = childVI1.children[1] // dir1 <--> dir1
            let child5 = childVI5.item // dir1 <-> dir1
            assertItem(child5, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func renameFileMismatch() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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

        try createFolder("l/dir1")
        try createFolder("r/dir1")
        try createFolder("l/dir1/dir2")
        try createFolder("r/dir1/dir2")

        // create files
        try createFile("r/dir1/dir2/010.txt", "123")
        try createFile("r/dir1/dir2/50.txt", "1234")
        try createFile("l/dir1/dir2/100.txt", "12")
        try createFile("r/dir1/dir2/100.txt", "1234")
        try createFile("l/dir1/011.txt", "123456")

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
        assertItem(child1, 0, 1, 1, 0, 2, "dir1", .orphan, 8)
        assertItem(child1.linkedItem, 0, 1, 2, 0, 2, "dir1", .orphan, 11)

        let child2 = child1.children[0] // dir1
        assertItem(child2, 0, 1, 0, 0, 3, "dir2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 1, 2, 0, 3, "dir2", .orphan, 11)

        let child3 = child2.children[0] // dir2
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

        let child5 = child2.children[1] // dir2
        assertItem(child5, 0, 1, 0, 0, 0, "100.txt", .changed, 2)
        assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "100.txt", .changed, 4)

        let child4 = child2.children[2] // dir2
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "50.txt", .orphan, 4)

        let child6 = child1.children[1] // dir1
        assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child5,
            toName: "110.txt"
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 2, 0, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 3, 0, 2, "dir1", .orphan, 11)

            let child2 = child1.children[0] // dir1
            assertItem(child2, 0, 0, 1, 0, 4, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 3, 0, 4, "dir2", .orphan, 11)

            let child3 = child2.children[0] // dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let child5 = child2.children[1] // dir2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "100.txt", .orphan, 4)

            let child6 = child2.children[2] // dir2
            assertItem(child6, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child4 = child2.children[3] // dir2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "50.txt", .orphan, 4)

            let child7 = child1.children[1] // dir1
            assertItem(child7, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 2, 0, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 3, 0, 2, "dir1", .orphan, 11)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 4, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 3, 0, 4, "dir2", .orphan, 11)

            let childVI3 = childVI2.children[0] // dir2 <--> dir2
            let child3 = childVI3.item // dir2 <-> dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let childVI5 = childVI2.children[1] // dir2 <--> dir2
            let child5 = childVI5.item // dir2 <-> dir2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "100.txt", .orphan, 4)

            let childVI6 = childVI2.children[2] // dir2 <--> dir2
            let child6 = childVI6.item // dir2 <-> dir2
            assertItem(child6, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI2.children[3] // dir2 <--> dir2
            let child4 = childVI4.item // dir2 <-> dir2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "50.txt", .orphan, 4)

            let childVI7 = childVI1.children[1] // dir1 <--> dir1
            let child7 = childVI7.item // dir1 <-> dir1
            assertItem(child7, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func renameFileMatchingToMatching() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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
        try createFolder("r/dir1/dir2")

        // create files
        try createFile("r/dir1/dir2/010.txt", "123")
        try createFile("l/dir1/dir2/100.txt", "12")
        try createFile("r/dir1/dir2/100.txt", "1234")
        try createFile("r/dir1/dir2/110.txt", "12")
        try createFile("l/dir1/011.txt", "123456")

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
        assertItem(child1, 0, 1, 1, 0, 2, "dir1", .orphan, 8)
        assertItem(child1.linkedItem, 0, 1, 2, 0, 2, "dir1", .orphan, 9)

        let child2 = child1.children[0] // dir1
        assertItem(child2, 0, 1, 0, 0, 3, "dir2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 1, 2, 0, 3, "dir2", .orphan, 9)

        let child3 = child2.children[0] // dir2
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

        let child4 = child2.children[1] // dir2
        assertItem(child4, 0, 1, 0, 0, 0, "100.txt", .changed, 2)
        assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "100.txt", .changed, 4)

        let child5 = child2.children[2] // dir2
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)

        let child6 = child1.children[1] // dir1
        assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child4,
            toName: "110.txt"
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 1, 1, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 2, 1, 2, "dir1", .orphan, 9)

            let child2 = child1.children[0] // dir1
            assertItem(child2, 0, 0, 0, 1, 3, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 2, 1, 3, "dir2", .orphan, 9)

            let child3 = child2.children[0] // dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let child4 = child2.children[1] // dir2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "100.txt", .orphan, 4)

            let child5 = child2.children[2] // dir2
            assertItem(child5, 0, 0, 0, 1, 0, "110.txt", .same, 2)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "110.txt", .same, 2)

            let child6 = child1.children[1] // dir1
            assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 1, 2, "dir1", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 2, 1, 2, "dir1", .orphan, 9)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 0, 1, 3, "dir2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 2, 1, 3, "dir2", .orphan, 9)

            let childVI3 = childVI2.children[0] // dir2 <--> dir2
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // dir2 <-> dir2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

            let childVI4 = childVI2.children[1] // dir2 <--> dir2
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // dir2 <-> dir2
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "100.txt", .orphan, 4)

            let childVI5 = childVI1.children[1] // dir1 <--> dir1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // dir1 <-> dir1
            assertItem(child5, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func renameFileOrphanToOrphan_OnlyOrphan_Right() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
            followSymLinks: true,
            skipPackages: false,
            traverseFilteredFolders: false,
            predicate: defaultPredicate,
            fileExtraOptions: [],
            displayOptions: .onlyOrphans
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

        // create files
        try createFile("r/dir1/dir2/010.txt", "123")
        try createFile("l/dir1/dir2/100.txt", "12345")
        try createFile("r/dir1/dir2/100.txt", "1234")
        try setFileTimestamp("r/dir1/dir2/100.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("l/dir1/dir2/110.txt", "12")
        try createFile("l/dir1/011.txt", "123456")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL.children[0] // l <-> r
        assertItem(child1, 0, 1, 2, 0, 2, "dir1", .orphan, 13)
        assertItem(child1.linkedItem, 1, 0, 1, 0, 2, "dir1", .orphan, 7)

        let child2 = child1.children[0] // dir1 <-> dir1
        assertItem(child2, 0, 1, 1, 0, 3, "dir2", .orphan, 7)
        assertItem(child2.linkedItem, 1, 0, 1, 0, 3, "dir2", .orphan, 7)

        let child3 = child2.children[0] // dir2 <-> dir2
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "010.txt", .orphan, 3)

        let child4 = child2.children[1] // dir2 <-> dir2
        assertItem(child4, 0, 1, 0, 0, 0, "100.txt", .changed, 5)
        assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "100.txt", .old, 4)

        let child5 = child2.children[2] // dir2 <-> dir2
        assertItem(child5, 0, 0, 1, 0, 0, "110.txt", .orphan, 2)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child6 = child1.children[1] // dir1 <-> dir1
        assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        try fileOperation.rename(
            srcRoot: #require(child3.linkedItem),
            toName: "110.txt"
        )

        do {
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 0, 2, 1, 0, 2, "dir1", .orphan, 13)
            assertItem(child1.linkedItem, 1, 1, 0, 0, 2, "dir1", .orphan, 7)

            let child2 = child1.children[0] // dir1 <-> dir1
            assertItem(child2, 0, 2, 0, 0, 2, "dir2", .orphan, 7)
            assertItem(child2.linkedItem, 1, 1, 0, 0, 2, "dir2", .orphan, 7)

            let child3 = child2.children[0] // dir2 <-> dir2
            assertItem(child3, 0, 1, 0, 0, 0, "100.txt", .changed, 5)
            assertItem(child3.linkedItem, 1, 0, 0, 0, 0, "100.txt", .old, 4)

            let child4 = child2.children[1] // dir2 <-> dir2
            assertItem(child4, 0, 1, 0, 0, 0, "110.txt", .changed, 2)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "110.txt", .changed, 3)

            let child5 = child1.children[1] // dir1 <-> dir1
            assertItem(child5, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 2, 1, 0, 2, "dir1", .orphan, 13)
            assertItem(child1.linkedItem, 1, 1, 0, 0, 2, "dir1", .orphan, 7)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    // MARK: -

    // MARK: Folders rename tests

    @Test func renameFolderFromBothSidesToOrphan() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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
        try createFolder("l/dir100")
        try createFolder("r/dir100")
        try createFolder("l/dir100/dir110")
        try createFolder("r/dir100/dir110")

        // create files
        try createFile("l/dir100/dir110/file001.txt", "12")
        try createFile("r/dir100/dir110/file001.txt", "123")
        try createFile("l/dir100/dir110/file002.txt", "123456")
        try createFile("r/dir100/dir110/file002.txt", "123456")
        try createFile("l/dir100/dir110/file003.txt", "12")
        try createFile("l/dir100/011.txt", "123456")

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
        assertItem(child1, 0, 1, 2, 1, 2, "dir100", .orphan, 16)
        assertItem(child1.linkedItem, 0, 1, 0, 1, 2, "dir100", .orphan, 9)

        let child2 = child1.children[0] // dir100
        assertItem(child2, 0, 1, 1, 1, 3, "dir110", .orphan, 10)
        assertItem(child2.linkedItem, 0, 1, 0, 1, 3, "dir110", .orphan, 9)

        let child3 = child2.children[0] // dir110
        assertItem(child3, 0, 1, 0, 0, 0, "file001.txt", .changed, 2)
        assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "file001.txt", .changed, 3)

        let child4 = child2.children[1] // dir110
        assertItem(child4, 0, 0, 0, 1, 0, "file002.txt", .same, 6)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file002.txt", .same, 6)

        let child5 = child2.children[2] // dir110
        assertItem(child5, 0, 0, 1, 0, 0, "file003.txt", .orphan, 2)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child6 = child1.children[1] // dir100
        assertItem(child6, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child2,
            toName: "dir120"
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 4, 0, 3, "dir100", .orphan, 16)
            assertItem(child1.linkedItem, 0, 0, 2, 0, 3, "dir100", .orphan, 9)

            let child2 = child1.children[0] // dir100
            assertItem(child2, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 9)

            let child3 = child2.children[0] // (null)
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file001.txt", .orphan, 3)

            let child4 = child2.children[1] // (null)
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file002.txt", .orphan, 6)

            let child5 = child1.children[1] // dir100
            assertItem(child5, 0, 0, 3, 0, 3, "dir120", .orphan, 10)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let child6 = child5.children[0] // dir120
            assertItem(child6, 0, 0, 1, 0, 0, "file001.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child7 = child5.children[1] // dir120
            assertItem(child7, 0, 0, 1, 0, 0, "file002.txt", .orphan, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child8 = child5.children[2] // dir120
            assertItem(child8, 0, 0, 1, 0, 0, "file003.txt", .orphan, 2)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child9 = child1.children[2] // dir100
            assertItem(child9, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 4, 0, 3, "dir100", .orphan, 16)
            assertItem(child1.linkedItem, 0, 0, 2, 0, 3, "dir100", .orphan, 9)

            let childVI2 = childVI1.children[0] // dir100 <--> dir100
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // dir100 <-> dir100
            assertItem(child2, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 9)

            let childVI3 = childVI2.children[0] // (null) <--> dir110
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // (null) <-> dir110
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file001.txt", .orphan, 3)

            let childVI4 = childVI2.children[1] // (null) <--> dir110
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // (null) <-> dir110
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file002.txt", .orphan, 6)

            let childVI5 = childVI1.children[1] // dir100 <--> dir100
            assertArrayCount(childVI5.children, 3)
            let child5 = childVI5.item // dir100 <-> dir100
            assertItem(child5, 0, 0, 3, 0, 3, "dir120", .orphan, 10)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let childVI6 = childVI5.children[0] // dir120 <--> (null)
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // dir120 <-> (null)
            assertItem(child6, 0, 0, 1, 0, 0, "file001.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI7 = childVI5.children[1] // dir120 <--> (null)
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // dir120 <-> (null)
            assertItem(child7, 0, 0, 1, 0, 0, "file002.txt", .orphan, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI5.children[2] // dir120 <--> (null)
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // dir120 <-> (null)
            assertItem(child8, 0, 0, 1, 0, 0, "file003.txt", .orphan, 2)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI9 = childVI1.children[2] // dir100 <--> dir100
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // dir100 <-> dir100
            assertItem(child9, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func renameFolderOrphanToOrphan() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
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
        try createFolder("l/dir050")
        try createFolder("r/dir050")
        try createFolder("l/dir050/dir100")
        try createFolder("r/dir050/dir100")
        try createFolder("l/dir050/dir100/dir105")
        try createFolder("r/dir050/dir100/dir110")

        // create files
        try createFile("l/dir050/dir100/dir105/file101.txt", "12")
        try createFile("l/dir050/dir100/dir105/file102.txt", "123456")
        try createFile("l/dir050/dir100/dir105/file103.txt", "12")
        try createFile("r/dir050/dir100/dir110/file401.txt", "12")
        try createFile("r/dir050/dir100/dir110/file403.txt", "123")
        try createFile("l/dir050/dir100/011.txt", "123456")
        try createFile("r/dir050/dir100/file301.txt", "123")
        try createFile("r/dir050/dir100/file302.txt", "123456")
        try createFile("l/dir050/020.txt", "123456")
        try createFile("l/dir050/040.txt", "123456")
        try createFile("r/dir050/file201.txt", "123")
        try createFile("r/dir050/file202.txt", "123")

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
        assertItem(child1, 0, 0, 6, 0, 5, "dir050", .orphan, 28)
        assertItem(child1.linkedItem, 0, 0, 6, 0, 5, "dir050", .orphan, 20)

        let child2 = child1.children[0] // dir050
        assertItem(child2, 0, 0, 4, 0, 5, "dir100", .orphan, 16)
        assertItem(child2.linkedItem, 0, 0, 4, 0, 5, "dir100", .orphan, 14)

        let child3 = child2.children[0] // dir100
        assertItem(child3, 0, 0, 3, 0, 3, "dir105", .orphan, 10)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

        let child4 = child3.children[0] // dir105
        assertItem(child4, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child5 = child3.children[1] // dir105
        assertItem(child5, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child6 = child3.children[2] // dir105
        assertItem(child6, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child7 = child2.children[1] // dir100
        assertItem(child7, 0, 0, 0, 0, 2, nil, .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 5)

        let child8 = child7.children[0] // (null)
        assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "file401.txt", .orphan, 2)

        let child9 = child7.children[1] // (null)
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "file403.txt", .orphan, 3)

        let child10 = child2.children[2] // dir100
        assertItem(child10, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child10.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child11 = child2.children[3] // dir100
        assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

        let child12 = child2.children[4] // dir100
        assertItem(child12, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child12.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

        let child13 = child1.children[1] // dir050
        assertItem(child13, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
        assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child14 = child1.children[2] // dir050
        assertItem(child14, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
        assertItem(child14.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child15 = child1.children[3] // dir050
        assertItem(child15, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child15.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

        let child16 = child1.children[4] // dir050
        assertItem(child16, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child16.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child3,
            toName: "dir120"
        )
        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 6, 0, 5, "dir050", .orphan, 28)
            assertItem(child1.linkedItem, 0, 0, 6, 0, 5, "dir050", .orphan, 20)

            let child2 = child1.children[0] // dir050
            assertItem(child2, 0, 0, 4, 0, 5, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 0, 4, 0, 5, "dir100", .orphan, 14)

            let child3 = child2.children[0] // dir100
            assertItem(child3, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 5)

            let child4 = child3.children[0] // (null)
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file401.txt", .orphan, 2)

            let child5 = child3.children[1] // (null)
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file403.txt", .orphan, 3)

            let child6 = child2.children[1] // dir100
            assertItem(child6, 0, 0, 3, 0, 3, "dir120", .orphan, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let child7 = child6.children[0] // dir120
            assertItem(child7, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child8 = child6.children[1] // dir120
            assertItem(child8, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child9 = child6.children[2] // dir120
            assertItem(child9, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
            assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child10 = child2.children[2] // dir100
            assertItem(child10, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child10.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child11 = child2.children[3] // dir100
            assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

            let child12 = child2.children[4] // dir100
            assertItem(child12, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child12.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

            let child13 = child1.children[1] // dir050
            assertItem(child13, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child14 = child1.children[2] // dir050
            assertItem(child14, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
            assertItem(child14.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child15 = child1.children[3] // dir050
            assertItem(child15, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child15.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

            let child16 = child1.children[4] // dir050
            assertItem(child16, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child16.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 5)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 6, 0, 5, "dir050", .orphan, 28)
            assertItem(child1.linkedItem, 0, 0, 6, 0, 5, "dir050", .orphan, 20)

            let childVI2 = childVI1.children[0] // dir050 <--> dir050
            assertArrayCount(childVI2.children, 5)
            let child2 = childVI2.item // dir050 <-> dir050
            assertItem(child2, 0, 0, 4, 0, 5, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 0, 4, 0, 5, "dir100", .orphan, 14)

            let childVI3 = childVI2.children[0] // dir100 <--> dir100
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // dir100 <-> dir100
            assertItem(child3, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 5)

            let childVI4 = childVI3.children[0] // (null) <--> dir110
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // (null) <-> dir110
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file401.txt", .orphan, 2)

            let childVI5 = childVI3.children[1] // (null) <--> dir110
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> dir110
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file403.txt", .orphan, 3)

            let childVI6 = childVI2.children[1] // dir100 <--> dir100
            assertArrayCount(childVI6.children, 3)
            let child6 = childVI6.item // dir100 <-> dir100
            assertItem(child6, 0, 0, 3, 0, 3, "dir120", .orphan, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let childVI7 = childVI6.children[0] // dir120 <--> (null)
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // dir120 <-> (null)
            assertItem(child7, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI6.children[1] // dir120 <--> (null)
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // dir120 <-> (null)
            assertItem(child8, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI9 = childVI6.children[2] // dir120 <--> (null)
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // dir120 <-> (null)
            assertItem(child9, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
            assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI10 = childVI2.children[2] // dir100 <--> dir100
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // dir100 <-> dir100
            assertItem(child10, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child10.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI11 = childVI2.children[3] // dir100 <--> dir100
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // dir100 <-> dir100
            assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

            let childVI12 = childVI2.children[4] // dir100 <--> dir100
            assertArrayCount(childVI12.children, 0)
            let child12 = childVI12.item // dir100 <-> dir100
            assertItem(child12, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child12.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

            let childVI13 = childVI1.children[1] // dir050 <--> dir050
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // dir050 <-> dir050
            assertItem(child13, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI14 = childVI1.children[2] // dir050 <--> dir050
            assertArrayCount(childVI14.children, 0)
            let child14 = childVI14.item // dir050 <-> dir050
            assertItem(child14, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
            assertItem(child14.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI15 = childVI1.children[3] // dir050 <--> dir050
            assertArrayCount(childVI15.children, 0)
            let child15 = childVI15.item // dir050 <-> dir050
            assertItem(child15, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child15.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

            let childVI16 = childVI1.children[4] // dir050 <--> dir050
            assertArrayCount(childVI16.children, 0)
            let child16 = childVI16.item // dir050 <-> dir050
            assertItem(child16, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child16.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)
        }
    }

    @Test func renameFolderMatchingToMatching() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l/dir050")
        try createFolder("r/dir050")
        try createFolder("l/dir050/dir100")
        try createFolder("r/dir050/dir100")
        try createFolder("l/dir050/dir100/dir110")
        try createFolder("r/dir050/dir100/dir110")
        try createFolder("r/dir050/dir100/dir120")

        // create files
        try createFile("l/dir050/dir100/dir110/file101.txt", "12")
        try createFile("r/dir050/dir100/dir110/file101.txt", "12")
        try createFile("l/dir050/dir100/dir110/file102.txt", "123456")
        try createFile("l/dir050/dir100/dir110/file103.txt", "12")
        try setFileTimestamp("l/dir050/dir100/dir110/file103.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/dir050/dir100/dir110/file103.txt", "123")
        try createFile("r/dir050/dir100/dir110/file104.txt", "1234567")
        try createFile("r/dir050/dir100/dir120/file101.txt", "12")
        try createFile("r/dir050/dir100/dir120/file102.txt", "123456")
        try createFile("r/dir050/dir100/dir120/file103.txt", "12")
        try createFile("l/dir050/dir100/011.txt", "123456")
        try createFile("r/dir050/dir100/file301.txt", "123")
        try createFile("r/dir050/dir100/file302.txt", "123456")
        try createFile("l/dir050/020.txt", "123456")
        try createFile("l/dir050/040.txt", "123456")
        try createFile("r/dir050/file201.txt", "123")
        try createFile("r/dir050/file202.txt", "123")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL.children[0] // l <-> r
        assertItem(child1, 1, 0, 4, 1, 5, "dir050", .orphan, 28)
        assertItem(child1.linkedItem, 0, 1, 8, 1, 5, "dir050", .orphan, 37)

        let child2 = child1.children[0] // dir050 <-> dir050
        assertItem(child2, 1, 0, 2, 1, 5, "dir100", .orphan, 16)
        assertItem(child2.linkedItem, 0, 1, 6, 1, 5, "dir100", .orphan, 31)

        let child3 = child2.children[0] // dir100 <-> dir100
        assertItem(child3, 1, 0, 1, 1, 4, "dir110", .orphan, 10)
        assertItem(child3.linkedItem, 0, 1, 1, 1, 4, "dir110", .orphan, 12)

        let child4 = child3.children[0] // dir110 <-> dir110
        assertItem(child4, 0, 0, 0, 1, 0, "file101.txt", .same, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file101.txt", .same, 2)

        let child5 = child3.children[1] // dir110 <-> dir110
        assertItem(child5, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child6 = child3.children[2] // dir110 <-> dir110
        assertItem(child6, 1, 0, 0, 0, 0, "file103.txt", .old, 2)
        assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file103.txt", .changed, 3)

        let child7 = child3.children[3] // dir110 <-> dir110
        assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file104.txt", .orphan, 7)

        let child8 = child2.children[1] // dir100 <-> dir100
        assertItem(child8, 0, 0, 0, 0, 3, nil, .orphan, 0)
        assertItem(child8.linkedItem, 0, 0, 3, 0, 3, "dir120", .orphan, 10)

        let child9 = child8.children[0] // (null) <-> dir120
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)

        let child10 = child8.children[1] // (null) <-> dir120
        assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)

        let child11 = child8.children[2] // (null) <-> dir120
        assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)

        let child12 = child2.children[2] // dir100 <-> dir100
        assertItem(child12, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child12.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child13 = child2.children[3] // dir100 <-> dir100
        assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child13.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

        let child14 = child2.children[4] // dir100 <-> dir100
        assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

        let child15 = child1.children[1] // dir050 <-> dir050
        assertItem(child15, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
        assertItem(child15.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child16 = child1.children[2] // dir050 <-> dir050
        assertItem(child16, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
        assertItem(child16.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child17 = child1.children[3] // dir050 <-> dir050
        assertItem(child17, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child17.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

        let child18 = child1.children[4] // dir050 <-> dir050
        assertItem(child18, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child18.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child3,
            toName: "dir120"
        )
        do {
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 0, 0, 3, 3, 5, "dir050", .orphan, 28)
            assertItem(child1.linkedItem, 0, 0, 7, 3, 5, "dir050", .orphan, 37)

            let child2 = child1.children[0] // dir050 <-> dir050
            assertItem(child2, 0, 0, 1, 3, 5, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 0, 5, 3, 5, "dir100", .orphan, 31)

            let child3 = child2.children[0] // dir100 <-> dir100
            assertItem(child3, 0, 0, 0, 0, 3, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 3, 0, 3, "dir110", .orphan, 12)

            let child4 = child3.children[0] // (null) <-> dir110
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)

            let child5 = child3.children[1] // (null) <-> dir110
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file103.txt", .orphan, 3)

            let child6 = child3.children[2] // (null) <-> dir110
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file104.txt", .orphan, 7)

            let child7 = child2.children[1] // dir100 <-> dir100
            assertItem(child7, 0, 0, 0, 3, 3, "dir120", .orphan, 10)
            assertItem(child7.linkedItem, 0, 0, 0, 3, 3, "dir120", .orphan, 10)

            let child8 = child7.children[0] // dir120 <-> dir120
            assertItem(child8, 0, 0, 0, 1, 0, "file101.txt", .same, 2)
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "file101.txt", .same, 2)

            let child9 = child7.children[1] // dir120 <-> dir120
            assertItem(child9, 0, 0, 0, 1, 0, "file102.txt", .same, 6)
            assertItem(child9.linkedItem, 0, 0, 0, 1, 0, "file102.txt", .same, 6)

            let child10 = child7.children[2] // dir120 <-> dir120
            assertItem(child10, 0, 0, 0, 1, 0, "file103.txt", .same, 2)
            assertItem(child10.linkedItem, 0, 0, 0, 1, 0, "file103.txt", .same, 2)

            let child11 = child2.children[2] // dir100 <-> dir100
            assertItem(child11, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child12 = child2.children[3] // dir100 <-> dir100
            assertItem(child12, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child12.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

            let child13 = child2.children[4] // dir100 <-> dir100
            assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child13.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

            let child14 = child1.children[1] // dir050 <-> dir050
            assertItem(child14, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
            assertItem(child14.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child15 = child1.children[2] // dir050 <-> dir050
            assertItem(child15, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
            assertItem(child15.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child16 = child1.children[3] // dir050 <-> dir050
            assertItem(child16, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child16.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

            let child17 = child1.children[4] // dir050 <-> dir050
            assertItem(child17, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child17.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 5)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 3, 3, 5, "dir050", .orphan, 28)
            assertItem(child1.linkedItem, 0, 0, 7, 3, 5, "dir050", .orphan, 37)

            let childVI2 = childVI1.children[0] // dir050 <--> dir050
            assertArrayCount(childVI2.children, 4)
            let child2 = childVI2.item // dir050 <-> dir050
            assertItem(child2, 0, 0, 1, 3, 5, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 0, 5, 3, 5, "dir100", .orphan, 31)

            let childVI3 = childVI2.children[0] // dir100 <--> dir100
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // dir100 <-> dir100
            assertItem(child3, 0, 0, 0, 0, 3, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 3, 0, 3, "dir110", .orphan, 12)

            let childVI4 = childVI3.children[0] // (null) <--> dir110
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // (null) <-> dir110
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)

            let childVI5 = childVI3.children[1] // (null) <--> dir110
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> dir110
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file103.txt", .orphan, 3)

            let childVI6 = childVI3.children[2] // (null) <--> dir110
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // (null) <-> dir110
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file104.txt", .orphan, 7)

            let childVI7 = childVI2.children[1] // dir100 <--> dir100
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // dir100 <-> dir100
            assertItem(child7, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI2.children[2] // dir100 <--> dir100
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // dir100 <-> dir100
            assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

            let childVI9 = childVI2.children[3] // dir100 <--> dir100
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // dir100 <-> dir100
            assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

            let childVI10 = childVI1.children[1] // dir050 <--> dir050
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // dir050 <-> dir050
            assertItem(child10, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
            assertItem(child10.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI11 = childVI1.children[2] // dir050 <--> dir050
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // dir050 <-> dir050
            assertItem(child11, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI12 = childVI1.children[3] // dir050 <--> dir050
            assertArrayCount(childVI12.children, 0)
            let child12 = childVI12.item // dir050 <-> dir050
            assertItem(child12, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child12.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

            let childVI13 = childVI1.children[4] // dir050 <--> dir050
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // dir050 <-> dir050
            assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child13.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)
        }
    }

    @Test func renameFolder_NoOrphan_Left() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
            followSymLinks: true,
            skipPackages: false,
            traverseFilteredFolders: false,
            predicate: defaultPredicate,
            fileExtraOptions: [],
            displayOptions: .noOrphan
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
        try createFolder("l/dir050")
        try createFolder("r/dir050")
        try createFolder("l/dir050/dir100")
        try createFolder("r/dir050/dir100")
        try createFolder("r/dir050/dir100/dir110")
        try createFolder("l/dir050/dir100/dir120")
        try createFolder("r/dir050/dir100/dir120")

        // create files
        try createFile("r/dir050/dir100/dir110/file101.txt", "12")
        try createFile("l/dir050/dir100/dir120/file101.txt", "12")
        try createFile("r/dir050/dir100/dir120/file101.txt", "12")
        try createFile("l/dir050/dir100/dir120/file102.txt", "123456")
        try setFileTimestamp("l/dir050/dir100/dir120/file102.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/dir050/dir100/dir120/file102.txt", "123")
        try createFile("l/dir050/dir100/dir120/file103.txt", "12")
        try createFile("r/dir050/dir100/dir120/file103.txt", "12")
        try createFile("l/dir050/dir100/011.txt", "123456")
        try createFile("l/dir050/050.txt", "123456")
        try createFile("r/dir050/050.txt", "123456")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL.children[0] // l <-> r
        assertItem(child1, 1, 0, 1, 3, 2, "dir050", .orphan, 22)
        assertItem(child1.linkedItem, 0, 1, 1, 3, 2, "dir050", .orphan, 15)

        let child2 = child1.children[0] // dir050 <-> dir050
        assertItem(child2, 1, 0, 1, 2, 3, "dir100", .orphan, 16)
        assertItem(child2.linkedItem, 0, 1, 1, 2, 3, "dir100", .orphan, 9)

        let child3 = child2.children[0] // dir100 <-> dir100
        assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 1, "dir110", .orphan, 2)

        let child4 = child3.children[0] // (null) <-> dir110
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)

        let child5 = child2.children[1] // dir100 <-> dir100
        assertItem(child5, 1, 0, 0, 2, 3, "dir120", .orphan, 10)
        assertItem(child5.linkedItem, 0, 1, 0, 2, 3, "dir120", .orphan, 7)

        let child6 = child5.children[0] // dir120 <-> dir120
        assertItem(child6, 0, 0, 0, 1, 0, "file101.txt", .same, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file101.txt", .same, 2)

        let child7 = child5.children[1] // dir120 <-> dir120
        assertItem(child7, 1, 0, 0, 0, 0, "file102.txt", .old, 6)
        assertItem(child7.linkedItem, 0, 1, 0, 0, 0, "file102.txt", .changed, 3)

        let child8 = child5.children[2] // dir120 <-> dir120
        assertItem(child8, 0, 0, 0, 1, 0, "file103.txt", .same, 2)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "file103.txt", .same, 2)

        let child9 = child2.children[2] // dir100 <-> dir100
        assertItem(child9, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child9.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child10 = child1.children[1] // dir050 <-> dir050
        assertItem(child10, 0, 0, 0, 1, 0, "050.txt", .same, 6)
        assertItem(child10.linkedItem, 0, 0, 0, 1, 0, "050.txt", .same, 6)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        fileOperation.rename(
            srcRoot: child5,
            toName: "dir150"
        )

        do {
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 0, 0, 4, 1, 2, "dir050", .orphan, 22)
            assertItem(child1.linkedItem, 0, 0, 4, 1, 2, "dir050", .orphan, 15)

            let child2 = child1.children[0] // dir050 <-> dir050
            assertItem(child2, 0, 0, 4, 0, 4, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 0, 4, 0, 4, "dir100", .orphan, 9)

            let child3 = child2.children[0] // dir100 <-> dir100
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 1, "dir110", .orphan, 2)

            let child4 = child3.children[0] // (null) <-> dir110
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)

            let child5 = child2.children[1] // dir100 <-> dir100
            assertItem(child5, 0, 0, 0, 0, 3, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 3, 0, 3, "dir120", .orphan, 7)

            let child6 = child5.children[0] // (null) <-> dir120
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)

            let child7 = child5.children[1] // (null) <-> dir120
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file102.txt", .orphan, 3)

            let child8 = child5.children[2] // (null) <-> dir120
            assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)

            let child9 = child2.children[2] // dir100 <-> dir100
            assertItem(child9, 0, 0, 3, 0, 3, "dir150", .orphan, 10)
            assertItem(child9.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

            let child10 = child9.children[0] // dir150 <-> (null)
            assertItem(child10, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
            assertItem(child10.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child11 = child9.children[1] // dir150 <-> (null)
            assertItem(child11, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child12 = child9.children[2] // dir150 <-> (null)
            assertItem(child12, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
            assertItem(child12.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child13 = child2.children[3] // dir100 <-> dir100
            assertItem(child13, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child14 = child1.children[1] // dir050 <-> dir050
            assertItem(child14, 0, 0, 0, 1, 0, "050.txt", .same, 6)
            assertItem(child14.linkedItem, 0, 0, 0, 1, 0, "050.txt", .same, 6)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 4, 1, 2, "dir050", .orphan, 22)
            assertItem(child1.linkedItem, 0, 0, 4, 1, 2, "dir050", .orphan, 15)

            let childVI2 = childVI1.children[0] // dir050 <--> dir050
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // dir050 <-> dir050
            assertItem(child2, 0, 0, 0, 1, 0, "050.txt", .same, 6)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "050.txt", .same, 6)
        }
    }

    @Test func renameFolderOrphanToOrphan_OnlyMismatches_Right() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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
        try createFolder("l/dir050")
        try createFolder("r/dir050")
        try createFolder("l/dir050/dir100")
        try createFolder("r/dir050/dir100")
        try createFolder("l/dir050/dir100/dir105")
        try createFolder("r/dir050/dir100/dir110")

        // create files
        try createFile("l/dir050/dir100/dir105/file101.txt", "12")
        try createFile("l/dir050/dir100/dir105/file102.txt", "123456")
        try createFile("l/dir050/dir100/dir105/file103.txt", "12")
        try createFile("r/dir050/dir100/dir110/file102.txt", "123")
        try createFile("r/dir050/dir100/dir110/file401.txt", "12")
        try createFile("l/dir050/dir100/011.txt", "123456")
        try createFile("r/dir050/dir100/file301.txt", "123")
        try createFile("r/dir050/dir100/file302.txt", "123456")
        try createFile("l/dir050/020.txt", "123456")
        try createFile("l/dir050/040.txt", "123456")
        try createFile("r/dir050/file201.txt", "123")
        try createFile("r/dir050/file202.txt", "123")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL.children[0] // l <-> r
        assertItem(child1, 0, 0, 6, 0, 5, "dir050", .orphan, 28)
        assertItem(child1.linkedItem, 0, 0, 6, 0, 5, "dir050", .orphan, 20)

        let child2 = child1.children[0] // dir050 <-> dir050
        assertItem(child2, 0, 0, 4, 0, 5, "dir100", .orphan, 16)
        assertItem(child2.linkedItem, 0, 0, 4, 0, 5, "dir100", .orphan, 14)

        let child3 = child2.children[0] // dir100 <-> dir100
        assertItem(child3, 0, 0, 3, 0, 3, "dir105", .orphan, 10)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

        let child4 = child3.children[0] // dir105 <-> (null)
        assertItem(child4, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child5 = child3.children[1] // dir105 <-> (null)
        assertItem(child5, 0, 0, 1, 0, 0, "file102.txt", .orphan, 6)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child6 = child3.children[2] // dir105 <-> (null)
        assertItem(child6, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child7 = child2.children[1] // dir100 <-> dir100
        assertItem(child7, 0, 0, 0, 0, 2, nil, .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 5)

        let child8 = child7.children[0] // (null) <-> dir110
        assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "file102.txt", .orphan, 3)

        let child9 = child7.children[1] // (null) <-> dir110
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "file401.txt", .orphan, 2)

        let child10 = child2.children[2] // dir100 <-> dir100
        assertItem(child10, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
        assertItem(child10.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child11 = child2.children[3] // dir100 <-> dir100
        assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

        let child12 = child2.children[4] // dir100 <-> dir100
        assertItem(child12, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child12.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

        let child13 = child1.children[1] // dir050 <-> dir050
        assertItem(child13, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
        assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child14 = child1.children[2] // dir050 <-> dir050
        assertItem(child14, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
        assertItem(child14.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child15 = child1.children[3] // dir050 <-> dir050
        assertItem(child15, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child15.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

        let child16 = child1.children[4] // dir050 <-> dir050
        assertItem(child16, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child16.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        try fileOperation.rename(
            srcRoot: #require(child7.linkedItem),
            toName: "dir105"
        )

        do {
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 0, 1, 5, 0, 5, "dir050", .orphan, 28)
            assertItem(child1.linkedItem, 0, 1, 5, 0, 5, "dir050", .orphan, 20)

            let child2 = child1.children[0] // dir050 <-> dir050
            assertItem(child2, 0, 1, 3, 0, 4, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 1, 3, 0, 4, "dir100", .orphan, 14)

            let child3 = child2.children[0] // dir100 <-> dir100
            assertItem(child3, 0, 1, 2, 0, 4, "dir105", .orphan, 10)
            assertItem(child3.linkedItem, 0, 1, 1, 0, 4, "dir105", .orphan, 5)

            let child4 = child3.children[0] // dir105 <-> dir105
            assertItem(child4, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child5 = child3.children[1] // dir105 <-> dir105
            assertItem(child5, 0, 1, 0, 0, 0, "file102.txt", .changed, 6)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file102.txt", .changed, 3)

            let child6 = child3.children[2] // dir105 <-> dir105
            assertItem(child6, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child7 = child3.children[3] // dir105 <-> dir105
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file401.txt", .orphan, 2)

            let child8 = child2.children[1] // dir100 <-> dir100
            assertItem(child8, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child9 = child2.children[2] // dir100 <-> dir100
            assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

            let child10 = child2.children[3] // dir100 <-> dir100
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

            let child11 = child1.children[1] // dir050 <-> dir050
            assertItem(child11, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child12 = child1.children[2] // dir050 <-> dir050
            assertItem(child12, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
            assertItem(child12.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child13 = child1.children[3] // dir050 <-> dir050
            assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child13.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

            let child14 = child1.children[4] // dir050 <-> dir050
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 5)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 1, 5, 0, 5, "dir050", .orphan, 28)
            assertItem(child1.linkedItem, 0, 1, 5, 0, 5, "dir050", .orphan, 20)

            let childVI2 = childVI1.children[0] // dir050 <--> dir050
            assertArrayCount(childVI2.children, 4)
            let child2 = childVI2.item // dir050 <-> dir050
            assertItem(child2, 0, 1, 3, 0, 4, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 1, 3, 0, 4, "dir100", .orphan, 14)

            let childVI3 = childVI2.children[0] // dir100 <--> dir100
            assertArrayCount(childVI3.children, 4)
            let child3 = childVI3.item // dir100 <-> dir100
            assertItem(child3, 0, 1, 2, 0, 4, "dir105", .orphan, 10)
            assertItem(child3.linkedItem, 0, 1, 1, 0, 4, "dir105", .orphan, 5)

            let childVI4 = childVI3.children[0] // dir105 <--> dir105
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // dir105 <-> dir105
            assertItem(child4, 0, 0, 1, 0, 0, "file101.txt", .orphan, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI3.children[1] // dir105 <--> dir105
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // dir105 <-> dir105
            assertItem(child5, 0, 1, 0, 0, 0, "file102.txt", .changed, 6)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file102.txt", .changed, 3)

            let childVI6 = childVI3.children[2] // dir105 <--> dir105
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // dir105 <-> dir105
            assertItem(child6, 0, 0, 1, 0, 0, "file103.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI7 = childVI3.children[3] // dir105 <--> dir105
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // dir105 <-> dir105
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file401.txt", .orphan, 2)

            let childVI8 = childVI2.children[1] // dir100 <--> dir100
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // dir100 <-> dir100
            assertItem(child8, 0, 0, 1, 0, 0, "011.txt", .orphan, 6)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI9 = childVI2.children[2] // dir100 <--> dir100
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // dir100 <-> dir100
            assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "file301.txt", .orphan, 3)

            let childVI10 = childVI2.children[3] // dir100 <--> dir100
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // dir100 <-> dir100
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "file302.txt", .orphan, 6)

            let childVI11 = childVI1.children[1] // dir050 <--> dir050
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // dir050 <-> dir050
            assertItem(child11, 0, 0, 1, 0, 0, "020.txt", .orphan, 6)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI12 = childVI1.children[2] // dir050 <--> dir050
            assertArrayCount(childVI12.children, 0)
            let child12 = childVI12.item // dir050 <-> dir050
            assertItem(child12, 0, 0, 1, 0, 0, "040.txt", .orphan, 6)
            assertItem(child12.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI13 = childVI1.children[3] // dir050 <--> dir050
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // dir050 <-> dir050
            assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child13.linkedItem, 0, 0, 1, 0, 0, "file201.txt", .orphan, 3)

            let childVI14 = childVI1.children[4] // dir050 <--> dir050
            assertArrayCount(childVI14.children, 0)
            let child14 = childVI14.item // dir050 <-> dir050
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file202.txt", .orphan, 3)
        }
    }

    @Test func renameFolderOrphanToMatching_OnlyMatches_Right_ShowEmptyFolder() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
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
            displayOptions: .onlyMatches
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
        try createFolder("l/dir100")
        try createFolder("r/dir100")
        try createFolder("r/dir100/dir110")
        try createFolder("l/dir100/dir120")

        // create files
        try createFile("r/dir100/dir110/file001.txt", "12")
        try createFile("r/dir100/dir110/file002.txt", "12345")
        try createFile("l/dir100/dir120/file001.txt", "12")
        try createFile("l/dir100/dir120/file002.txt", "123456")
        try createFile("l/dir100/dir120/file003.txt", "12")

        try setFileTimestamp("l/dir100/dir120/file002.txt", "2001-03-24 10: 45: 32 +0600")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL.children[0] // l <-> r
        assertItem(child1, 0, 0, 3, 0, 2, "dir100", .orphan, 10)
        assertItem(child1.linkedItem, 0, 0, 2, 0, 2, "dir100", .orphan, 7)

        let child2 = child1.children[0] // dir100 <-> dir100
        assertItem(child2, 0, 0, 0, 0, 2, nil, .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 2, 0, 2, "dir110", .orphan, 7)

        let child3 = child2.children[0] // (null) <-> dir110
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file001.txt", .orphan, 2)

        let child4 = child2.children[1] // (null) <-> dir110
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file002.txt", .orphan, 5)

        let child5 = child1.children[1] // dir100 <-> dir100
        assertItem(child5, 0, 0, 3, 0, 3, "dir120", .orphan, 10)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 3, nil, .orphan, 0)

        let child6 = child5.children[0] // dir120 <-> (null)
        assertItem(child6, 0, 0, 1, 0, 0, "file001.txt", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child7 = child5.children[1] // dir120 <-> (null)
        assertItem(child7, 0, 0, 1, 0, 0, "file002.txt", .orphan, 6)
        assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child8 = child5.children[2] // dir120 <-> (null)
        assertItem(child8, 0, 0, 1, 0, 0, "file003.txt", .orphan, 2)
        assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = RenameCompareItem(operationManager: fileOperationManager)

        try fileOperation.rename(
            srcRoot: #require(child2.linkedItem),
            toName: "dir120"
        )

        do {
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 1, 0, 1, 1, 1, "dir100", .orphan, 10)
            assertItem(child1.linkedItem, 0, 1, 0, 1, 1, "dir100", .orphan, 7)

            let child2 = child1.children[0] // dir100 <-> dir100
            assertItem(child2, 1, 0, 1, 1, 3, "dir120", .orphan, 10)
            assertItem(child2.linkedItem, 0, 1, 0, 1, 3, "dir120", .orphan, 7)

            let child3 = child2.children[0] // dir120 <-> dir120
            assertItem(child3, 0, 0, 0, 1, 0, "file001.txt", .same, 2)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "file001.txt", .same, 2)

            let child4 = child2.children[1] // dir120 <-> dir120
            assertItem(child4, 1, 0, 0, 0, 0, "file002.txt", .old, 6)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "file002.txt", .changed, 5)

            let child5 = child2.children[2] // dir120 <-> dir120
            assertItem(child5, 0, 0, 1, 0, 0, "file003.txt", .orphan, 2)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 0, 1, 1, 1, "dir100", .orphan, 10)
            assertItem(child1.linkedItem, 0, 1, 0, 1, 1, "dir100", .orphan, 7)

            let childVI2 = childVI1.children[0] // dir100 <--> dir100
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // dir100 <-> dir100
            assertItem(child2, 1, 0, 1, 1, 3, "dir120", .orphan, 10)
            assertItem(child2.linkedItem, 0, 1, 0, 1, 3, "dir120", .orphan, 7)

            let childVI3 = childVI2.children[0] // dir120 <--> dir120
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // dir120 <-> dir120
            assertItem(child3, 0, 0, 0, 1, 0, "file001.txt", .same, 2)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "file001.txt", .same, 2)
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
