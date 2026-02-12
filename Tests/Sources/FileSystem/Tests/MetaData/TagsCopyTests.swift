//
//  TagsCopyTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/12/21.
//  Copyright (c) 2021 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class TagsCopyTests: BaseTests {
    @Test func copyFileWithTags() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .finderTags, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 9100,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/Parent")
        try createFolder("r/Parent")
        try createFolder("l/Parent/FolderWithTags")
        try createFolder("r/Parent/FolderWithTags")

        // create files
        try add(tags: ["Red"], fullPath: appendFolder("l/Parent/FolderWithTags"))
        try createFile("l/Parent/FolderWithTags/attachment_one.txt", "1234567")
        try createFile("r/Parent/FolderWithTags/attachment_one.txt", "123456")
        try setFileTimestamp("r/Parent/FolderWithTags/attachment_one.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("l/Parent/FolderWithTags/file1.txt", "123456")
        try add(tags: ["Yellow"], fullPath: appendFolder("l/Parent/FolderWithTags/file1.txt"))
        try createFile("r/Parent/FolderWithTags/file1.txt", "123456")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("r/Parent/FolderWithTags/file1.txt"))
        try createFile("l/Parent/FolderWithTags/file2.txt", "1234567890")
        try add(tags: ["Yellow"], fullPath: appendFolder("l/Parent/FolderWithTags/file2.txt"))
        try createFile("r/Parent/FolderWithTags/file2.txt", "1234567890")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("r/Parent/FolderWithTags/file2.txt"))
        try createFile("l/line1.txt", "12345")
        try createFile("r/line1.txt", "12345")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)

        var operationElement: CompareItem
        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 1, 0, 3, 2, "l", .orphan, 28)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 0, 3, 2, "r", .orphan, 27)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertMismatchingTags(child1, 3, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 1, 0, 2, 1, "Parent", .orphan, 23)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 0, 0, 2, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertMismatchingTags(child2, 3, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 1, 0, 2, 3, "FolderWithTags", .mismatchingTags, 23)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 0, 0, 2, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 2, "FolderWithTags")

            let child4 = child3.children[0] // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 1, 0, 0, 0, "attachment_one.txt", .changed, 7)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "attachment_one.txt", .old, 6)

            let child5 = child3.children[1] // FolderWithTags <-> FolderWithTags
            operationElement = child5
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertMismatchingTags(child5, 1, "file1.txt")

            let child6 = child3.children[2] // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertMismatchingTags(child6, 1, "file2.txt")

            let child7 = child1.children[1] // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 1, 0, 3, 2, "l", .orphan, 28)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 0, 3, 2, "r", .orphan, 27)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertMismatchingTags(child1, 3, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 1, 0, 2, 1, "Parent", .orphan, 23)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 0, 0, 2, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertMismatchingTags(child2, 3, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 1, 0, 2, 3, "FolderWithTags", .mismatchingTags, 23)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 0, 0, 2, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 2, "FolderWithTags")

            let childVI4 = childVI3.children[0] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 1, 0, 0, 0, "attachment_one.txt", .changed, 7)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "attachment_one.txt", .old, 6)

            let childVI5 = childVI3.children[1] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertMismatchingTags(child5, 1, "file1.txt")

            let childVI6 = childVI3.children[2] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertMismatchingTags(child6, 1, "file2.txt")

            let childVI7 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
        }

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
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: operationElement,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 1, 0, 3, 2, "l", .orphan, 28)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 0, 3, 2, "r", .orphan, 27)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertMismatchingTags(child1, 2, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 1, 0, 2, 1, "Parent", .orphan, 23)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 0, 0, 2, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertMismatchingTags(child2, 2, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 1, 0, 2, 3, "FolderWithTags", .mismatchingTags, 23)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 0, 0, 2, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 1, "FolderWithTags")

            let child4 = child3.children[0] // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 1, 0, 0, 0, "attachment_one.txt", .changed, 7)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "attachment_one.txt", .old, 6)

            let child5 = child3.children[1] // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertMismatchingTags(child5, 0, "file1.txt")
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)

            let child6 = child3.children[2] // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertMismatchingTags(child6, 1, "file2.txt")

            let child7 = child1.children[1] // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 1, 0, 3, 2, "l", .orphan, 28)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 0, 3, 2, "r", .orphan, 27)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertMismatchingTags(child1, 2, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 1, 0, 2, 1, "Parent", .orphan, 23)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 0, 0, 2, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertMismatchingTags(child2, 2, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 1, 0, 2, 3, "FolderWithTags", .mismatchingTags, 23)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 0, 0, 2, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 1, "FolderWithTags")

            let childVI4 = childVI3.children[0] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 1, 0, 0, 0, "attachment_one.txt", .changed, 7)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "attachment_one.txt", .old, 6)

            let childVI5 = childVI3.children[1] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)

            let childVI6 = childVI3.children[2] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertMismatchingTags(child6, 1, "file2.txt")

            let childVI7 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
        }
    }

    @Test func copyFolderWithTags() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .finderTags, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 9100,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/Parent")
        try createFolder("r/Parent")
        try createFolder("l/Parent/FolderWithTags")
        try createFolder("r/Parent/FolderWithTags")

        // create files
        try add(tags: ["Red"], fullPath: appendFolder("l/Parent/FolderWithTags"))
        try createFile("l/Parent/FolderWithTags/attachment_one.txt", "1234567")
        try createFile("r/Parent/FolderWithTags/attachment_one.txt", "123456")
        try setFileTimestamp("r/Parent/FolderWithTags/attachment_one.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("l/Parent/FolderWithTags/file1.txt", "123456")
        try add(tags: ["Yellow"], fullPath: appendFolder("l/Parent/FolderWithTags/file1.txt"))
        try createFile("r/Parent/FolderWithTags/file1.txt", "123456")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("r/Parent/FolderWithTags/file1.txt"))
        try createFile("l/Parent/FolderWithTags/file2.txt", "1234567890")
        try add(tags: ["Yellow"], fullPath: appendFolder("l/Parent/FolderWithTags/file2.txt"))
        try createFile("r/Parent/FolderWithTags/file2.txt", "1234567890")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("r/Parent/FolderWithTags/file2.txt"))

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!
        let vi = try #require(rootL.visibleItem)
        var operationElement: CompareItem

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 1, 0, 2, 1, "l", .orphan, 23)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 0, 2, 1, "r", .orphan, 22)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 3, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 1, 0, 2, 1, "Parent", .orphan, 23)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 0, 0, 2, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 3, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            operationElement = try #require(child3.linkedItem)
            assertItem(child3, 0, 1, 0, 2, 3, "FolderWithTags", .mismatchingTags, 23)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 0, 0, 2, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 2, "FolderWithTags")

            let child4 = child3.children[0] // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 1, 0, 0, 0, "attachment_one.txt", .changed, 7)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "attachment_one.txt", .old, 6)
            assertFolderTags(child4, false, "attachment_one.txt")
            assertMismatchingTags(child4, 0, "attachment_one.txt")

            let child5 = child3.children[1] // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertFolderTags(child5, false, "file1.txt")
            assertMismatchingTags(child5, 1, "file1.txt")

            let child6 = child3.children[2] // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 1, "file2.txt")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 1, 0, 2, 1, "l", .orphan, 23)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 0, 2, 1, "r", .orphan, 22)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 3, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 1, 0, 2, 1, "Parent", .orphan, 23)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 1, 0, 0, 2, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 3, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 1, 0, 2, 3, "FolderWithTags", .mismatchingTags, 23)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 1, 0, 0, 2, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 2, "FolderWithTags")

            let childVI4 = childVI3.children[0] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 1, 0, 0, 0, "attachment_one.txt", .changed, 7)
            assertItem(child4.linkedItem, 1, 0, 0, 0, 0, "attachment_one.txt", .old, 6)
            assertFolderTags(child4, false, "attachment_one.txt")
            assertMismatchingTags(child4, 0, "attachment_one.txt")

            let childVI5 = childVI3.children[1] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertFolderTags(child5, false, "file1.txt")
            assertMismatchingTags(child5, 1, "file1.txt")

            let childVI6 = childVI3.children[2] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 1, "file2.txt")
        }

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
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )
        fileOperation.copy(
            srcRoot: operationElement,
            srcBaseDir: appendFolder("r"),
            destBaseDir: appendFolder("l")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 3, 1, "l", .orphan, 22)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 3, 1, "r", .orphan, 22)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 0, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 0, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 3, 3, "FolderWithTags", .orphan, 22)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "FolderWithTags", .orphan, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, false, "FolderWithTags")
            assertMismatchingTags(child3, 0, "FolderWithTags")

            let child4 = child3.children[0] // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertFolderTags(child4, false, "attachment_one.txt")
            assertMismatchingTags(child4, 0, "attachment_one.txt")

            let child5 = child3.children[1] // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertFolderTags(child5, false, "file1.txt")
            assertMismatchingTags(child5, 0, "file1.txt")

            let child6 = child3.children[2] // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 0, "file2.txt")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 3, 1, "l", .orphan, 22)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 3, 1, "r", .orphan, 22)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 0, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 0, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 3, 3, "FolderWithTags", .orphan, 22)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "FolderWithTags", .orphan, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, false, "FolderWithTags")
            assertMismatchingTags(child3, 0, "FolderWithTags")

            let childVI4 = childVI3.children[0] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertFolderTags(child4, false, "attachment_one.txt")
            assertMismatchingTags(child4, 0, "attachment_one.txt")

            let childVI5 = childVI3.children[1] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // FolderWithTags <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertFolderTags(child5, false, "file1.txt")
            assertMismatchingTags(child5, 0, "file1.txt")

            let childVI6 = childVI3.children[2] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 0, "file2.txt")
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
