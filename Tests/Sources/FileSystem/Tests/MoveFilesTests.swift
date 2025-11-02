//
//  MoveFilesTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class MoveFilesTests: BaseTests {
    @Test func moveFilesPresentOnBothSidesWithFiltered() throws {
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
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_changed.m", "1234567890")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_matched.txt", "1")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_older.txt", "1234567")
        try createFile("l/folder_1/folder_1_2/match_2_1.m", "12")
        try createFile("l/folder_1/file.txt", "123")

        try createFile("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "1")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_matched.txt", "1")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_older.txt", "1234")
        try createFile("r/folder_1/folder_1_2/match_2_1.m", "12")
        try createFile("r/folder_1/file.txt", "123")
        try createFile("r/folder_1/right_orphan.txt", "1234567890")

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

        var l = rootL.children[0]
        assertItem(l, 1, 1, 0, 3, 4, "folder_1", .orphan, 23)
        assertItem(l.linkedItem, 1, 1, 1, 3, 4, "folder_1", .orphan, 21)

        var child1 = l.children[0]
        assertItem(child1, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 18)
        assertItem(child1.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 6)

        var child2 = child1.children[0]
        assertItem(child2, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 18)
        assertItem(child2.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 6)

        var child3 = child2.children[0]
        assertItem(child3, 0, 1, 0, 0, 0, "file_changed.m", .changed, 10)
        assertItem(child3.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 1)

        var child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 1, 0, "file_matched.txt", .same, 1)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 1)

        var child5 = child2.children[2]
        assertItem(child5, 1, 0, 0, 0, 0, "file_older.txt", .old, 7)
        assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 4)

        var child6 = l.children[1]
        assertItem(child6, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)

        var child7 = child6.children[0]
        assertItem(child7, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)

        var child8 = l.children[2]
        assertItem(child8, 0, 0, 0, 1, 0, "file.txt", .same, 3)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 3)

        var child9 = l.children[3]
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 10)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 4)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 1, 0, 3, 4, "folder_1", .orphan, 23)
            assertItem(child1.linkedItem, 1, 1, 1, 3, 4, "folder_1", .orphan, 21)

            let childVI2 = childVI1.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_1 <-> folder_1
            assertItem(child2, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 18)
            assertItem(child2.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 6)

            let childVI3 = childVI2.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // folder_1_1 <-> folder_1_1
            assertItem(child3, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 18)
            assertItem(child3.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 6)

            let childVI4 = childVI3.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder_2_1 <-> folder_2_1
            assertItem(child4, 0, 1, 0, 0, 0, "file_changed.m", .changed, 10)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 1)

            let childVI5 = childVI3.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 0, 0, 1, 0, "file_matched.txt", .same, 1)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 1)

            let childVI6 = childVI3.children[2] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_2_1 <-> folder_2_1
            assertItem(child6, 1, 0, 0, 0, 0, "file_older.txt", .old, 7)
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 4)

            let childVI7 = childVI1.children[1] // folder_1 <--> folder_1
            assertArrayCount(childVI7.children, 1)
            let child7 = childVI7.item // folder_1 <-> folder_1
            assertItem(child7, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)

            let childVI8 = childVI7.children[0] // folder_1_2 <--> folder_1_2
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // folder_1_2 <-> folder_1_2
            assertItem(child8, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)

            let childVI9 = childVI1.children[2] // folder_1 <--> folder_1
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // folder_1 <-> folder_1
            assertItem(child9, 0, 0, 0, 1, 0, "file.txt", .same, 3)
            assertItem(child9.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 3)

            let childVI10 = childVI1.children[3] // folder_1 <--> folder_1
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // folder_1 <-> folder_1
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 10)
        }
        // VD_ASSERT_ONLY_SETUP()

        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child1,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        l = rootL.children[0]
        assertItem(l, 0, 0, 0, 2, 4, "folder_1", .orphan, 5)
        assertItem(l.linkedItem, 0, 0, 4, 2, 4, "folder_1", .orphan, 33)

        child1 = l.children[0]
        assertItem(child1, 0, 0, 0, 0, 1, nil, .orphan, 0)
        assertItem(child1.linkedItem, 0, 0, 3, 0, 1, "folder_1_1", .orphan, 18)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 3, nil, .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 3, 0, 3, "folder_2_1", .orphan, 18)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 10)

        child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file_matched.txt", .orphan, 1)

        child5 = child2.children[2]
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 7)

        child6 = l.children[1]
        assertItem(child6, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)

        child7 = child6.children[0]
        assertItem(child7, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)

        child8 = l.children[2]
        assertItem(child8, 0, 0, 0, 1, 0, "file.txt", .same, 3)
        assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 3)

        child9 = l.children[3]
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 10)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 4)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 2, 4, "folder_1", .orphan, 5)
            assertItem(child1.linkedItem, 0, 0, 4, 2, 4, "folder_1", .orphan, 33)

            let childVI2 = childVI1.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_1 <-> folder_1
            assertItem(child2, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 3, 0, 1, "folder_1_1", .orphan, 18)

            let childVI3 = childVI2.children[0] // (null) <--> folder_1_1
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // (null) <-> folder_1_1
            assertItem(child3, 0, 0, 0, 0, 3, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 3, 0, 3, "folder_2_1", .orphan, 18)

            let childVI4 = childVI3.children[0] // (null) <--> folder_2_1
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // (null) <-> folder_2_1
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 10)

            let childVI5 = childVI3.children[1] // (null) <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> folder_2_1
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_matched.txt", .orphan, 1)

            let childVI6 = childVI3.children[2] // (null) <--> folder_2_1
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // (null) <-> folder_2_1
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 7)

            let childVI7 = childVI1.children[1] // folder_1 <--> folder_1
            assertArrayCount(childVI7.children, 1)
            let child7 = childVI7.item // folder_1 <-> folder_1
            assertItem(child7, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 2)

            let childVI8 = childVI7.children[0] // folder_1_2 <--> folder_1_2
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // folder_1_2 <-> folder_1_2
            assertItem(child8, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 2)

            let childVI9 = childVI1.children[2] // folder_1 <--> folder_1
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // folder_1 <-> folder_1
            assertItem(child9, 0, 0, 0, 1, 0, "file.txt", .same, 3)
            assertItem(child9.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 3)

            let childVI10 = childVI1.children[3] // folder_1 <--> folder_1
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // folder_1 <-> folder_1
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 10)
        }
    }

    @Test func moveFilesPresentOnBothSides() throws {
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

        try createFolder("r/folder_1/folder_1_1/folder_2_1")

        // create files
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_matched.txt", "12")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_older.txt", "12345")

        try createFile("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "1")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_matched.txt", "12")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_older.txt", "1")

        try setFileTimestamp("l/folder_1/folder_1_1/folder_2_1/file_older.txt", "2001-03-24 10: 45: 32 +0600")

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
        assertItem(l, 1, 0, 0, 1, 1, "folder_1", .orphan, 7)
        assertItem(l.linkedItem, 0, 1, 1, 1, 1, "folder_1", .orphan, 4)

        var child1 = l.children[0]
        assertItem(child1, 1, 0, 0, 1, 1, "folder_1_1", .orphan, 7)
        assertItem(child1.linkedItem, 0, 1, 1, 1, 1, "folder_1_1", .orphan, 4)

        var child2 = child1.children[0]
        assertItem(child2, 1, 0, 0, 1, 3, "folder_2_1", .orphan, 7)
        assertItem(child2.linkedItem, 0, 1, 1, 1, 3, "folder_2_1", .orphan, 4)

        var child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 1)

        var child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)

        var child5 = child2.children[2]
        assertItem(child5, 1, 0, 0, 0, 0, "file_older.txt", .old, 5)
        assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 1)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 0, 0, 1, 1, "folder_1", .orphan, 7)
            assertItem(child1.linkedItem, 0, 1, 1, 1, 1, "folder_1", .orphan, 4)

            let childVI2 = childVI1.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_1 <-> folder_1
            assertItem(child2, 1, 0, 0, 1, 1, "folder_1_1", .orphan, 7)
            assertItem(child2.linkedItem, 0, 1, 1, 1, 1, "folder_1_1", .orphan, 4)

            let childVI3 = childVI2.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // folder_1_1 <-> folder_1_1
            assertItem(child3, 1, 0, 0, 1, 3, "folder_2_1", .orphan, 7)
            assertItem(child3.linkedItem, 0, 1, 1, 1, 3, "folder_2_1", .orphan, 4)

            let childVI4 = childVI3.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder_2_1 <-> folder_2_1
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 1)

            let childVI5 = childVI3.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 1, 0, 0, 0, 0, "file_older.txt", .old, 5)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file_older.txt", .changed, 1)
        }
        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child1,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        l = rootL.children[0]
        assertItem(l, 0, 0, 0, 1, 1, "folder_1", .orphan, 2)
        assertItem(l.linkedItem, 0, 0, 2, 1, 1, "folder_1", .orphan, 8)

        child1 = l.children[0]
        assertItem(child1, 0, 0, 0, 1, 1, "folder_1_1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 2, 1, 1, "folder_1_1", .orphan, 8)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 1, 3, "folder_2_1", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 2, 1, 3, "folder_2_1", .orphan, 8)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 1)

        child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)

        child5 = child2.children[2]
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 5)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "folder_1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 2, 1, 1, "folder_1", .orphan, 8)

            let childVI2 = childVI1.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_1 <-> folder_1
            assertItem(child2, 0, 0, 0, 1, 1, "folder_1_1", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 2, 1, 1, "folder_1_1", .orphan, 8)

            let childVI3 = childVI2.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI3.children, 2)
            let child3 = childVI3.item // folder_1_1 <-> folder_1_1
            assertItem(child3, 0, 0, 0, 1, 3, "folder_2_1", .orphan, 2)
            assertItem(child3.linkedItem, 0, 0, 2, 1, 3, "folder_2_1", .orphan, 8)

            let childVI4 = childVI3.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder_2_1 <-> folder_2_1
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 1)

            let childVI5 = childVI3.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 5)
        }
    }

    @Test func moveFilesOrphansNoFiltered() throws {
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
        try createFolder("l/bootstrap")
        try createFolder("r/bootstrap")

        try createFolder("l/bootstrap/data")
        try createFolder("r/bootstrap/data")

        try createFolder("l/bootstrap/data/hypersonic")
        try createFolder("r/bootstrap/data/hypersonic")

        // create files
        try createFile("l/bootstrap/data/hypersonic/dvd.log", "1")

        try createFile("l/bootstrap/data/hypersonic/dvd.properties", "12")

        try createFile("l/bootstrap/data/hypersonic/localDB.lck", "123")
        try createFile("l/bootstrap/data/hypersonic/localDB.log", "1234")

        try createFile("r/bootstrap/data/hypersonic/localDB.log", "1234")

        try createFile("l/bootstrap/data/hypersonic/localDB.properties", "123456")

        try createFile("l/bootstrap/data/hypersonic/localDB.script", "1234567")

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
        assertItem(l, 0, 0, 5, 1, 1, "bootstrap", .orphan, 23)
        assertItem(l.linkedItem, 0, 0, 0, 1, 1, "bootstrap", .orphan, 4)

        let child = l.children[0]
        assertItem(child, 0, 0, 5, 1, 1, "data", .orphan, 23)
        assertItem(child.linkedItem, 0, 0, 0, 1, 1, "data", .orphan, 4)

        var child1 = child.children[0]
        assertItem(child1, 0, 0, 5, 1, 6, "hypersonic", .orphan, 23)
        assertItem(child1.linkedItem, 0, 0, 0, 1, 6, "hypersonic", .orphan, 4)

        var child2 = child1.children[0]
        assertItem(child2, 0, 0, 1, 0, 0, "dvd.log", .orphan, 1)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child3 = child1.children[1]
        assertItem(child3, 0, 0, 1, 0, 0, "dvd.properties", .orphan, 2)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child4 = child1.children[2]
        assertItem(child4, 0, 0, 1, 0, 0, "localDB.lck", .orphan, 3)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child5 = child1.children[3]
        assertItem(child5, 0, 0, 0, 1, 0, "localDB.log", .same, 4)
        assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "localDB.log", .same, 4)

        var child6 = child1.children[4]
        assertItem(child6, 0, 0, 1, 0, 0, "localDB.properties", .orphan, 6)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        var child7 = child1.children[5]
        assertItem(child7, 0, 0, 1, 0, 0, "localDB.script", .orphan, 7)
        assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 5, 1, 1, "bootstrap", .orphan, 23)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "bootstrap", .orphan, 4)

            let childVI2 = childVI1.children[0] // bootstrap <--> bootstrap
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // bootstrap <-> bootstrap
            assertItem(child2, 0, 0, 5, 1, 1, "data", .orphan, 23)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 1, "data", .orphan, 4)

            let childVI3 = childVI2.children[0] // data <--> data
            assertArrayCount(childVI3.children, 5)
            let child3 = childVI3.item // data <-> data
            assertItem(child3, 0, 0, 5, 1, 6, "hypersonic", .orphan, 23)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 6, "hypersonic", .orphan, 4)

            let childVI4 = childVI3.children[0] // hypersonic <--> hypersonic
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // hypersonic <-> hypersonic
            assertItem(child4, 0, 0, 1, 0, 0, "dvd.log", .orphan, 1)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI3.children[1] // hypersonic <--> hypersonic
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // hypersonic <-> hypersonic
            assertItem(child5, 0, 0, 1, 0, 0, "dvd.properties", .orphan, 2)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI3.children[2] // hypersonic <--> hypersonic
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // hypersonic <-> hypersonic
            assertItem(child6, 0, 0, 1, 0, 0, "localDB.lck", .orphan, 3)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI7 = childVI3.children[3] // hypersonic <--> hypersonic
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // hypersonic <-> hypersonic
            assertItem(child7, 0, 0, 1, 0, 0, "localDB.properties", .orphan, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI3.children[4] // hypersonic <--> hypersonic
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // hypersonic <-> hypersonic
            assertItem(child8, 0, 0, 1, 0, 0, "localDB.script", .orphan, 7)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child1,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 1, 1, "bootstrap", .orphan, 4)
        assertItem(child1.linkedItem, 0, 0, 5, 1, 1, "bootstrap", .orphan, 23)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 1, 1, "data", .orphan, 4)
        assertItem(child2.linkedItem, 0, 0, 5, 1, 1, "data", .orphan, 23)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 1, 6, "hypersonic", .orphan, 4)
        assertItem(child3.linkedItem, 0, 0, 5, 1, 6, "hypersonic", .orphan, 23)

        child4 = child3.children[0]
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "dvd.log", .orphan, 1)

        child5 = child3.children[1]
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "dvd.properties", .orphan, 2)

        child6 = child3.children[2]
        assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "localDB.lck", .orphan, 3)

        child7 = child3.children[3]
        assertItem(child7, 0, 0, 0, 1, 0, "localDB.log", .same, 4)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "localDB.log", .same, 4)

        let child8 = child3.children[4]
        assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "localDB.properties", .orphan, 6)

        let child9 = child3.children[5]
        assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "localDB.script", .orphan, 7)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "bootstrap", .orphan, 4)
            assertItem(child1.linkedItem, 0, 0, 5, 1, 1, "bootstrap", .orphan, 23)

            let childVI2 = childVI1.children[0] // bootstrap <--> bootstrap
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // bootstrap <-> bootstrap
            assertItem(child2, 0, 0, 0, 1, 1, "data", .orphan, 4)
            assertItem(child2.linkedItem, 0, 0, 5, 1, 1, "data", .orphan, 23)

            let childVI3 = childVI2.children[0] // data <--> data
            assertArrayCount(childVI3.children, 5)
            let child3 = childVI3.item // data <-> data
            assertItem(child3, 0, 0, 0, 1, 6, "hypersonic", .orphan, 4)
            assertItem(child3.linkedItem, 0, 0, 5, 1, 6, "hypersonic", .orphan, 23)

            let childVI4 = childVI3.children[0] // hypersonic <--> hypersonic
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // hypersonic <-> hypersonic
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "dvd.log", .orphan, 1)

            let childVI5 = childVI3.children[1] // hypersonic <--> hypersonic
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // hypersonic <-> hypersonic
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "dvd.properties", .orphan, 2)

            let childVI6 = childVI3.children[2] // hypersonic <--> hypersonic
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // hypersonic <-> hypersonic
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "localDB.lck", .orphan, 3)

            let childVI7 = childVI3.children[3] // hypersonic <--> hypersonic
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // hypersonic <-> hypersonic
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "localDB.properties", .orphan, 6)

            let childVI8 = childVI3.children[4] // hypersonic <--> hypersonic
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // hypersonic <-> hypersonic
            assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "localDB.script", .orphan, 7)
        }
    }

    @Test func moveFilesAllFilesFiltered() throws {
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
        try createFolder("l/src/it/unipa/cuc/codicefiscale")
        try createFolder("r/src/it/unipa/cuc/codicefiscale")

        // create files
        try createFile("l/src/it/unipa/cuc/codicefiscale/CodiceFiscale.java", "12345")
        try createFile("r/src/it/unipa/cuc/codicefiscale/CodiceFiscale.java", "12345")
        try createFile("l/src/it/unipa/cuc/codicefiscale/CodiceFiscaleChecker.java", "123")
        try createFile("r/src/it/unipa/cuc/codicefiscale/CodiceFiscaleChecker.java", "123")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        var child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 2, 1, "src", .orphan, 8)
        assertItem(child1.linkedItem, 0, 0, 0, 2, 1, "src", .orphan, 8)

        var child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 2, 1, "it", .orphan, 8)
        assertItem(child2.linkedItem, 0, 0, 0, 2, 1, "it", .orphan, 8)

        var child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 2, 1, "unipa", .orphan, 8)
        assertItem(child3.linkedItem, 0, 0, 0, 2, 1, "unipa", .orphan, 8)

        var child4 = child3.children[0]
        assertItem(child4, 0, 0, 0, 2, 1, "cuc", .orphan, 8)
        assertItem(child4.linkedItem, 0, 0, 0, 2, 1, "cuc", .orphan, 8)

        var child5 = child4.children[0]
        assertItem(child5, 0, 0, 0, 2, 2, "codicefiscale", .orphan, 8)
        assertItem(child5.linkedItem, 0, 0, 0, 2, 2, "codicefiscale", .orphan, 8)

        var child6 = child5.children[0]
        assertItem(child6, 0, 0, 0, 1, 0, "CodiceFiscale.java", .same, 5)
        assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "CodiceFiscale.java", .same, 5)

        var child7 = child5.children[1]
        assertItem(child7, 0, 0, 0, 1, 0, "CodiceFiscaleChecker.java", .same, 3)
        assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "CodiceFiscaleChecker.java", .same, 3)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 2, 1, "src", .orphan, 8)
            assertItem(child1.linkedItem, 0, 0, 0, 2, 1, "src", .orphan, 8)

            let childVI2 = childVI1.children[0] // src <--> src
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // src <-> src
            assertItem(child2, 0, 0, 0, 2, 1, "it", .orphan, 8)
            assertItem(child2.linkedItem, 0, 0, 0, 2, 1, "it", .orphan, 8)

            let childVI3 = childVI2.children[0] // it <--> it
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // it <-> it
            assertItem(child3, 0, 0, 0, 2, 1, "unipa", .orphan, 8)
            assertItem(child3.linkedItem, 0, 0, 0, 2, 1, "unipa", .orphan, 8)

            let childVI4 = childVI3.children[0] // unipa <--> unipa
            assertArrayCount(childVI4.children, 1)
            let child4 = childVI4.item // unipa <-> unipa
            assertItem(child4, 0, 0, 0, 2, 1, "cuc", .orphan, 8)
            assertItem(child4.linkedItem, 0, 0, 0, 2, 1, "cuc", .orphan, 8)

            let childVI5 = childVI4.children[0] // cuc <--> cuc
            assertArrayCount(childVI5.children, 2)
            let child5 = childVI5.item // cuc <-> cuc
            assertItem(child5, 0, 0, 0, 2, 2, "codicefiscale", .orphan, 8)
            assertItem(child5.linkedItem, 0, 0, 0, 2, 2, "codicefiscale", .orphan, 8)

            let childVI6 = childVI5.children[0] // codicefiscale <--> codicefiscale
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // codicefiscale <-> codicefiscale
            assertItem(child6, 0, 0, 0, 1, 0, "CodiceFiscale.java", .same, 5)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "CodiceFiscale.java", .same, 5)

            let childVI7 = childVI5.children[1] // codicefiscale <--> codicefiscale
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // codicefiscale <-> codicefiscale
            assertItem(child7, 0, 0, 0, 1, 0, "CodiceFiscaleChecker.java", .same, 3)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "CodiceFiscaleChecker.java", .same, 3)
        }

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes

        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child2,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 0, 1, "src", .orphan, 0)
        assertItem(child1.linkedItem, 0, 0, 2, 0, 1, "src", .orphan, 8)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 1, nil, .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 2, 0, 1, "it", .orphan, 8)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 2, 0, 1, "unipa", .orphan, 8)

        child4 = child3.children[0]
        assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 2, 0, 1, "cuc", .orphan, 8)

        child5 = child4.children[0]
        assertItem(child5, 0, 0, 0, 0, 2, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 2, 0, 2, "codicefiscale", .orphan, 8)

        child6 = child5.children[0]
        assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "CodiceFiscale.java", .orphan, 5)

        child7 = child5.children[1]
        assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "CodiceFiscaleChecker.java", .orphan, 3)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "src", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 0, 1, "src", .orphan, 8)

            let childVI2 = childVI1.children[0] // src <--> src
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // src <-> src
            assertItem(child2, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 2, 0, 1, "it", .orphan, 8)

            let childVI3 = childVI2.children[0] // (null) <--> it
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // (null) <-> it
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 2, 0, 1, "unipa", .orphan, 8)

            let childVI4 = childVI3.children[0] // (null) <--> unipa
            assertArrayCount(childVI4.children, 1)
            let child4 = childVI4.item // (null) <-> unipa
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 2, 0, 1, "cuc", .orphan, 8)

            let childVI5 = childVI4.children[0] // (null) <--> cuc
            assertArrayCount(childVI5.children, 2)
            let child5 = childVI5.item // (null) <-> cuc
            assertItem(child5, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 2, 0, 2, "codicefiscale", .orphan, 8)

            let childVI6 = childVI5.children[0] // (null) <--> codicefiscale
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // (null) <-> codicefiscale
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "CodiceFiscale.java", .orphan, 5)

            let childVI7 = childVI5.children[1] // (null) <--> codicefiscale
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // (null) <-> codicefiscale
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "CodiceFiscaleChecker.java", .orphan, 3)
        }
    }

    @Test func moveFilesOnlyMatches() throws {
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
        try createFolder("l/folder_1")
        try createFolder("r/folder_1")
        try createFolder("l/folder_1/folder_1_1")
        try createFolder("r/folder_1/folder_1_1")
        try createFolder("l/folder_1/folder_1_1/folder_2_1")
        try createFolder("r/folder_1/folder_1_1/folder_2_1")

        // create files
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_changed.m", "123")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "1234567890")
        try setFileTimestamp("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "2001-03-24 10: 45: 32 +0600")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_matched.m", "12345")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_matched.m", "12345")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_older.m", "1234")
        try setFileTimestamp("l/folder_1/folder_1_1/folder_2_1/file_older.m", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_older.m", "123456")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        var child1 = rootL.children[0]
        assertItem(child1, 1, 1, 0, 1, 1, "folder_1", .orphan, 12)
        assertItem(child1.linkedItem, 1, 1, 0, 1, 1, "folder_1", .orphan, 21)

        var child2 = child1.children[0]
        assertItem(child2, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 12)
        assertItem(child2.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 21)

        var child3 = child2.children[0]
        assertItem(child3, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 12)
        assertItem(child3.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 21)

        var child4 = child3.children[0]
        assertItem(child4, 0, 1, 0, 0, 0, "file_changed.m", .changed, 3)
        assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 10)

        var child5 = child3.children[1]
        assertItem(child5, 0, 0, 0, 1, 0, "file_matched.m", .same, 5)
        assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file_matched.m", .same, 5)

        var child6 = child3.children[2]
        assertItem(child6, 1, 0, 0, 0, 0, "file_older.m", .old, 4)
        assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file_older.m", .changed, 6)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 1, 0, 1, 1, "folder_1", .orphan, 12)
            assertItem(child1.linkedItem, 1, 1, 0, 1, 1, "folder_1", .orphan, 21)

            let childVI2 = childVI1.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_1 <-> folder_1
            assertItem(child2, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 12)
            assertItem(child2.linkedItem, 1, 1, 0, 1, 1, "folder_1_1", .orphan, 21)

            let childVI3 = childVI2.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder_1_1 <-> folder_1_1
            assertItem(child3, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 12)
            assertItem(child3.linkedItem, 1, 1, 0, 1, 3, "folder_2_1", .orphan, 21)

            let childVI4 = childVI3.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // folder_2_1 <-> folder_2_1
            assertItem(child4, 0, 0, 0, 1, 0, "file_matched.m", .same, 5)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file_matched.m", .same, 5)
        }

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child5,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0]
        assertItem(child1, 1, 1, 0, 0, 1, "folder_1", .orphan, 7)
        assertItem(child1.linkedItem, 1, 1, 1, 0, 1, "folder_1", .orphan, 21)

        child2 = child1.children[0]
        assertItem(child2, 1, 1, 0, 0, 1, "folder_1_1", .orphan, 7)
        assertItem(child2.linkedItem, 1, 1, 1, 0, 1, "folder_1_1", .orphan, 21)

        child3 = child2.children[0]
        assertItem(child3, 1, 1, 0, 0, 3, "folder_2_1", .orphan, 7)
        assertItem(child3.linkedItem, 1, 1, 1, 0, 3, "folder_2_1", .orphan, 21)

        child4 = child3.children[0]
        assertItem(child4, 0, 1, 0, 0, 0, "file_changed.m", .changed, 3)
        assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "file_changed.m", .old, 10)

        child5 = child3.children[1]
        assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_matched.m", .orphan, 5)

        child6 = child3.children[2]
        assertItem(child6, 1, 0, 0, 0, 0, "file_older.m", .old, 4)
        assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file_older.m", .changed, 6)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 1, 0, 0, 1, "folder_1", .orphan, 7)
            assertItem(child1.linkedItem, 1, 1, 1, 0, 1, "folder_1", .orphan, 21)

            let childVI2 = childVI1.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder_1 <-> folder_1
            assertItem(child2, 1, 1, 0, 0, 1, "folder_1_1", .orphan, 7)
            assertItem(child2.linkedItem, 1, 1, 1, 0, 1, "folder_1_1", .orphan, 21)

            let childVI3 = childVI2.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder_1_1 <-> folder_1_1
            assertItem(child3, 1, 1, 0, 0, 3, "folder_2_1", .orphan, 7)
            assertItem(child3.linkedItem, 1, 1, 1, 0, 3, "folder_2_1", .orphan, 21)
        }
    }

    @Test func moveOrphan() throws {
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
        try createFile("l/only_on_left/symlinks.zip", "12345678")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        var child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 13)
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
        assertItem(child6, 0, 0, 0, 0, 0, "symlinks.zip", .orphan, 8)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 13)
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

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child2,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        child1 = rootL.children[0]
        assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 13)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 2, "only_on_left", .orphan, 0)

        child2 = child1.children[0]
        assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "second_folder", .orphan, 0)

        child3 = child2.children[0]
        assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)

        child4 = child2.children[1]
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)

        child5 = child2.children[2]
        assertItem(child5, 0, 0, 0, 0, 0, "symlinks copia.zip", .orphan, 5)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child6 = child1.children[1]
        assertItem(child6, 0, 0, 0, 0, 0, "symlinks.zip", .orphan, 8)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 2, "only_on_left", .orphan, 13)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 2, "only_on_left", .orphan, 0)

            let childVI2 = childVI1.children[0] // only_on_left <--> only_on_left
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // only_on_left <-> only_on_left
            assertItem(child2, 0, 0, 0, 0, 3, "second_folder", .orphan, 5)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "second_folder", .orphan, 0)

            let childVI3 = childVI2.children[0] // second_folder <--> second_folder
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // second_folder <-> second_folder
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo", .orphan, 0)

            let childVI4 = childVI2.children[1] // second_folder <--> second_folder
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // second_folder <-> second_folder
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "cartella senza titolo 2", .orphan, 0)
        }
    }

    @Test func moveDontFollowSymLink() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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
            assertArrayCount(childVI2.children, 5)
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

            let childVI7 = childVI2.children[4] // folder2 <--> folder2
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // folder2 <-> folder2
            assertItem(child7, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
        }

        // VD_ASSERT_ONLY_SETUP()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child2.linkedItem!,
            srcBaseDir: appendFolder("r"),
            destBaseDir: appendFolder("l")
        )

        child1 = rootL.children[0] // l
        assertItem(child1, 0, 0, 1, 0, 1, "folder1", .orphan, 2)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

        child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 1, 0, 5, "folder2", .orphan, 2)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 5, "folder2", .orphan, 0)

        child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child4 = child2.children[1] // folder2
        assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        try assertSymlink(child4.linkedItem!, "symlink_test1", true)

        child5 = child2.children[2] // folder2
        assertItem(child5, 0, 0, 0, 0, 0, "orphan_symlink", .orphan, 0)
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        try assertSymlink(child5, "symlink_test2", true)

        child6 = child2.children[3] // folder2
        assertItem(child6, 0, 0, 1, 0, 0, "sample.txt", .orphan, 2)
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        child7 = child2.children[4] // folder2
        assertItem(child7, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
        assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        try assertSymlink(child7, "symlink_test2", true)

        let errors = fileOperationDelegate.errors
        #expect(errors.count == 1, "Errors must contain an object")
        assertError(errors[0], FileError.createSymLink(path: child3.path!))

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 1, 0, 1, "folder1", .orphan, 2)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 5)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 1, 0, 5, "folder2", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 5, "folder2", .orphan, 0)

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
            assertItem(child5, 0, 0, 0, 0, 0, "orphan_symlink", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI2.children[3] // folder2 <--> folder2
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder2 <-> folder2
            assertItem(child6, 0, 0, 1, 0, 0, "sample.txt", .orphan, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI7 = childVI2.children[4] // folder2 <--> folder2
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // folder2 <-> folder2
            assertItem(child7, 0, 0, 0, 0, 0, "symlink1", .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test func moveFailure() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: true,
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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
            try fm.removeItem(atPath: child4.path!)
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

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
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

    @Test func movePreserveFolderTimestamp() throws {
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

        try createFolder("l/folder1/folder2/folder3")
        try createFolder("r/folder1")

        try setFileCreationTime("l/folder1", "2010-01-01 00: 00: 00 +0000")
        try setFileTimestamp("l/folder1", "2010-02-02 02: 02: 00 +0000")

        try setFileCreationTime("l/folder1/folder2", "2010-04-04 04: 04: 00 +0000")
        try setFileTimestamp("l/folder1/folder2", "2010-05-05 05: 05: 00 +0000")

        try setFileCreationTime("l/folder1/folder2/folder3", "2011-05-05 05: 00: 30 +0000")
        try setFileTimestamp("l/folder1/folder2/folder3", "2011-06-06 06: 00: 30 +0000")

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
        assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
        assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

        let child2 = child1.children[0] // folder1
        assertItem(child2, 0, 0, 0, 0, 1, "folder2", .orphan, 0)
        assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

        let child3 = child2.children[0] // folder2
        assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 0, 0, 1, "folder2", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI3 = childVI2.children[0] // folder2 <--> (null)
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // folder2 <-> (null)
            assertItem(child3, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: child2,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        do {
            let child1 = rootL.children[0] // l
            assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

            let child2 = child1.children[0] // folder1
            assertItem(child2, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "folder2", .orphan, 0)
            try assertTimestamps(child2.linkedItem, "2010-04-04 04: 04: 00 +0000", "2010-05-05 05: 05: 00 +0000")

            let child3 = child2.children[0] // (null)
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
            try assertTimestamps(child3.linkedItem, "2011-05-05 05: 00: 30 +0000", "2011-06-06 06: 00: 30 +0000")
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "folder1", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "folder1", .orphan, 0)

            let childVI2 = childVI1.children[0] // folder1 <--> folder1
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // folder1 <-> folder1
            assertItem(child2, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "folder2", .orphan, 0)

            let childVI3 = childVI2.children[0] // (null) <--> folder2
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // (null) <-> folder2
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, "folder3", .orphan, 0)
        }
    }

    @Test(.disabled("BUG 0000230: Orphan file not colored correctly after move: Not yet fixed, this test fails")) func moveMatchFileBecomeFiltered() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: true,
            hideEmptyFolders: true,
            followSymLinks: false,
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
        try createFolder("l")
        try createFolder("r")

        // create files
        try createFile("l/file1.html", "12345678901")
        try createFile("r/file1.html", "12345678901")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

        let moveItem: CompareItem

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "l", .orphan, 11)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "r", .orphan, 11)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 1, 0, "file1.html", .same, 11)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "file1.html", .same, 11)

            moveItem = child2
        }

        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 1, 1, "l", .orphan, 11)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 1, "r", .orphan, 11)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 1, 0, "file1.html", .same, 11)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "file1.html", .same, 11)
        }

        // VD_ASSERT_ONLY_SETUP()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: false)
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )
        let fileOperation = MoveCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.move(
            srcRoot: moveItem,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 1, 0, 1, "r", .orphan, 11)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "file1.html", .orphan, 11)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 1, 0, 1, "r", .orphan, 11)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "file1.html", .orphan, 11)
            #expect(child2.isFiltered == true, "\(child2.fileName!) must be filtered")
            #expect(child2.linkedItem!.isFiltered == true, "\(child2.linkedItem!.fileName!) must be filtered")
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
