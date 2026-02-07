//
//  TouchFilesTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping function_body_length
final class TouchFilesTests: BaseTests {
    @Test func touchOlderFiles() throws {
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

        try createFolder("l/a/bb/cc")
        try createFolder("r/a/bb/cc")

        try createFile("l/a/bb/cc/cc_file.txt", "12")
        try createFile("l/a/bb/bb_file.txt", "12")

        try createFile("r/a/bb/cc/cc_file.txt", "123")
        try createFile("r/a/bb/bb_file.txt", "123")

        try setFileTimestamp("l/a/bb/cc/cc_file.txt", "2001-03-24 10: 45: 32 +0600")
        try setFileTimestamp("r/a/bb/cc/cc_file.txt", "2002-03-24 10: 45: 32 +0600")

        try setFileTimestamp("l/a/bb/bb_file.txt", "2002-03-24 10: 45: 32 +0600")
        try setFileTimestamp("r/a/bb/bb_file.txt", "2001-03-24 10: 45: 32 +0600")

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
        assertItem(child1, 1, 1, 0, 0, 1, "a", .orphan, 4)
        assertItem(child1.linkedItem, 1, 1, 0, 0, 1, "a", .orphan, 6)

        var child2 = child1.children[0] // a
        assertItem(child2, 1, 1, 0, 0, 2, "bb", .orphan, 4)
        assertItem(child2.linkedItem, 1, 1, 0, 0, 2, "bb", .orphan, 6)

        var child3 = child2.children[0] // bb
        assertItem(child3, 1, 0, 0, 0, 1, "cc", .orphan, 2)
        assertItem(child3.linkedItem, 0, 1, 0, 0, 1, "cc", .orphan, 3)

        var child4 = child3.children[0] // cc
        assertItem(child4, 1, 0, 0, 0, 0, "cc_file.txt", .old, 2)
        assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "cc_file.txt", .changed, 3)

        var child5 = child2.children[1] // bb
        assertItem(child5, 0, 1, 0, 0, 0, "bb_file.txt", .changed, 2)
        assertItem(child5.linkedItem, 1, 0, 0, 0, 0, "bb_file.txt", .old, 3)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 1, 0, 0, 1, "a", .orphan, 4)
            assertItem(child1.linkedItem, 1, 1, 0, 0, 1, "a", .orphan, 6)

            let childVI2 = childVI1.children[0] // a <--> a
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // a <-> a
            assertItem(child2, 1, 1, 0, 0, 2, "bb", .orphan, 4)
            assertItem(child2.linkedItem, 1, 1, 0, 0, 2, "bb", .orphan, 6)

            let childVI3 = childVI2.children[0] // bb <--> bb
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // bb <-> bb
            assertItem(child3, 1, 0, 0, 0, 1, "cc", .orphan, 2)
            assertItem(child3.linkedItem, 0, 1, 0, 0, 1, "cc", .orphan, 3)

            let childVI4 = childVI3.children[0] // cc <--> cc
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // cc <-> cc
            assertItem(child4, 1, 0, 0, 0, 0, "cc_file.txt", .old, 2)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "cc_file.txt", .changed, 3)

            let childVI5 = childVI2.children[1] // bb <--> bb
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // bb <-> bb
            assertItem(child5, 0, 1, 0, 0, 0, "bb_file.txt", .changed, 2)
            assertItem(child5.linkedItem, 1, 0, 0, 0, 0, "bb_file.txt", .old, 3)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let touchDate = try buildDate("2012-05-05 11: 00: 11 +0000")

        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = TouchCompareItem(operationManager: fileOperationManager)

        fileOperation.touch(
            srcRoot: child1,
            includeSubfolders: true,
            touchDate: touchDate
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 2, 0, 0, 1, "a", .orphan, 4)
        assertItem(child1.linkedItem, 2, 0, 0, 0, 1, "a", .orphan, 6)
        try assertTimestamps(child1, nil, "2012-05-05 11: 00: 11 +0000")

        child2 = child1.children[0] // a
        assertItem(child2, 0, 2, 0, 0, 2, "bb", .orphan, 4)
        assertItem(child2.linkedItem, 2, 0, 0, 0, 2, "bb", .orphan, 6)
        try assertTimestamps(child2, nil, "2012-05-05 11: 00: 11 +0000")

        child3 = child2.children[0] // bb
        assertItem(child3, 0, 1, 0, 0, 1, "cc", .orphan, 2)
        assertItem(child3.linkedItem, 1, 0, 0, 0, 1, "cc", .orphan, 3)
        try assertTimestamps(child3, nil, "2012-05-05 11: 00: 11 +0000")

        child4 = child3.children[0] // cc
        assertItem(child4, 0, 1, 0, 0, 0, "cc_file.txt", .changed, 2)
        assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "cc_file.txt", .old, 3)
        try assertTimestamps(child4, nil, "2012-05-05 11: 00: 11 +0000")

        child5 = child2.children[1] // bb
        assertItem(child5, 0, 1, 0, 0, 0, "bb_file.txt", .changed, 2)
        assertItem(child5.linkedItem, 1, 0, 0, 0, 0, "bb_file.txt", .old, 3)
        try assertTimestamps(child5, nil, "2012-05-05 11: 00: 11 +0000")
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 2, 0, 0, 1, "a", .orphan, 4)
            assertItem(child1.linkedItem, 2, 0, 0, 0, 1, "a", .orphan, 6)

            let childVI2 = childVI1.children[0] // a <--> a
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // a <-> a
            assertItem(child2, 0, 2, 0, 0, 2, "bb", .orphan, 4)
            assertItem(child2.linkedItem, 2, 0, 0, 0, 2, "bb", .orphan, 6)

            let childVI3 = childVI2.children[0] // bb <--> bb
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // bb <-> bb
            assertItem(child3, 0, 1, 0, 0, 1, "cc", .orphan, 2)
            assertItem(child3.linkedItem, 1, 0, 0, 0, 1, "cc", .orphan, 3)

            let childVI4 = childVI3.children[0] // cc <--> cc
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // cc <-> cc
            assertItem(child4, 0, 1, 0, 0, 0, "cc_file.txt", .changed, 2)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "cc_file.txt", .old, 3)

            let childVI5 = childVI2.children[1] // bb <--> bb
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // bb <-> bb
            assertItem(child5, 0, 1, 0, 0, 0, "bb_file.txt", .changed, 2)
            assertItem(child5.linkedItem, 1, 0, 0, 0, 0, "bb_file.txt", .old, 3)
        }
    }

    @Test func touchOrphanFile() throws {
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

        try createFolder("l/dir1")
        try createFolder("r/dir1")

        try createFile("l/dir1/file1.txt", "12")

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
        assertItem(child2, 0, 0, 1, 0, 0, "file1.txt", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 0, "file1.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let touchDate = try buildDate("2012-05-05 11: 00: 11 +0000")

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = TouchCompareItem(operationManager: fileOperationManager)
        fileOperation.touch(
            srcRoot: child2,
            includeSubfolders: false,
            touchDate: touchDate
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

        child2 = child1.children[0] // dir1
        assertItem(child2, 0, 0, 1, 0, 0, "file1.txt", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        try assertTimestamps(child2, nil, "2012-05-05 11: 00: 11 +0000")
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "dir1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "dir1", .orphan, 0)

            let childVI2 = childVI1.children[0] // dir1 <--> dir1
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // dir1 <-> dir1
            assertItem(child2, 0, 0, 1, 0, 0, "file1.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }
}

// swiftlint:enable force_unwrapping function_body_length
