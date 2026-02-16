//
//  TagsMoveTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/12/21.
//  Copyright (c) 2021 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping function_body_length
final class TagsMoveTests: BaseTests {
    @Test func moveFolderWithTags() throws {
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
        try createFile("l/Parent/FolderWithTags/attachment_one.txt", "123456")
        try createFile("r/Parent/FolderWithTags/attachment_one.txt", "123456")
        try createFile("l/Parent/FolderWithTags/file1.txt", "123456")
        try createFile("r/Parent/FolderWithTags/file1.txt", "123456")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("r/Parent/FolderWithTags/file1.txt"))
        try createFile("l/Parent/FolderWithTags/file2.txt", "1234567890")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("l/Parent/FolderWithTags/file2.txt"))
        try createFile("r/Parent/FolderWithTags/file2.txt", "1234567890")
        try add(tags: ["Yellow", "Red"], fullPath: appendFolder("r/Parent/FolderWithTags/file2.txt"))
        try createFile("l/Parent/anotherFile.txt", "123456")
        try add(tags: ["Blue", "Purple"], fullPath: appendFolder("l/Parent/anotherFile.txt"))
        try createFile("r/Parent/anotherFile.txt", "123456")
        try add(tags: ["Blue"], fullPath: appendFolder("r/Parent/anotherFile.txt"))

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
            assertItem(child1, 0, 0, 0, 4, 1, "l", .orphan, 28)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 4, 1, "r", .orphan, 28)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 3, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 4, 2, "Parent", .orphan, 28)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 4, 2, "Parent", .orphan, 28)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 3, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 3, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 1, "FolderWithTags")

            let child4 = child3.children[0] // FolderWithTags <-> FolderWithTags
            assertItem(child4, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
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
            assertMismatchingTags(child6, 0, "file2.txt")

            let child7 = child2.children[1] // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertFolderTags(child7, false, "anotherFile.txt")
            assertMismatchingTags(child7, 1, "anotherFile.txt")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 4, 1, "l", .orphan, 28)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 4, 1, "r", .orphan, 28)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 3, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 4, 2, "Parent", .orphan, 28)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 4, 2, "Parent", .orphan, 28)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 3, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            operationElement = child3
            assertItem(child3, 0, 0, 0, 3, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "FolderWithTags", .mismatchingTags, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, true, "FolderWithTags")
            assertMismatchingTags(child3, 1, "FolderWithTags")

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
            assertMismatchingTags(child5, 1, "file1.txt")

            let childVI6 = childVI3.children[2] // FolderWithTags <--> FolderWithTags
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithTags <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 0, "file2.txt")

            let childVI7 = childVI2.children[1] // Parent <--> Parent
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertFolderTags(child7, false, "anotherFile.txt")
            assertMismatchingTags(child7, 1, "anotherFile.txt")
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

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
            srcRoot: operationElement,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 1, 1, "l", .orphan, 6)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 3, 1, 1, "r", .orphan, 28)
            #expect(child1.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 1, "r")
            assertFolderTags(child1.linkedItem, false, "r")
            assertMismatchingTags(child1.linkedItem, 1, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 1, 2, "Parent", .orphan, 6)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 3, 1, 2, "Parent", .orphan, 28)
            #expect(child2.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 1, "Parent")
            assertFolderTags(child2.linkedItem, false, "Parent")
            assertMismatchingTags(child2.linkedItem, 1, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 0, 3, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 3, 0, 3, "FolderWithTags", .orphan, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, false, "FolderWithTags")
            assertMismatchingTags(child3, 0, "FolderWithTags")
            assertFolderTags(child3.linkedItem, false, "FolderWithTags")
            assertMismatchingTags(child3.linkedItem, 0, "FolderWithTags")

            let child4 = child3.children[0] // (null) <-> FolderWithTags
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "attachment_one.txt", .orphan, 6)
            assertFolderTags(child4, false, "attachment_one.txt")
            assertMismatchingTags(child4, 0, "attachment_one.txt")
            assertFolderTags(child4.linkedItem, false, "attachment_one.txt")
            assertMismatchingTags(child4.linkedItem, 0, "attachment_one.txt")

            let child5 = child3.children[1] // (null) <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file1.txt", .orphan, 6)
            assertFolderTags(child5, false, "file1.txt")
            assertMismatchingTags(child5, 0, "file1.txt")
            assertFolderTags(child5.linkedItem, false, "file1.txt")
            assertMismatchingTags(child5.linkedItem, 0, "file1.txt")

            let child6 = child3.children[2] // (null) <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 0, "file2.txt")
            assertFolderTags(child6.linkedItem, false, "file2.txt")
            assertMismatchingTags(child6.linkedItem, 0, "file2.txt")

            let child7 = child2.children[1] // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertFolderTags(child7, false, "anotherFile.txt")
            assertMismatchingTags(child7, 1, "anotherFile.txt")
            assertFolderTags(child7.linkedItem, false, "anotherFile.txt")
            assertMismatchingTags(child7.linkedItem, 1, "anotherFile.txt")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 1, 1, "l", .orphan, 6)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 3, 1, 1, "r", .orphan, 28)
            #expect(child1.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1, false, "r")
            assertMismatchingTags(child1, 1, "r")
            assertFolderTags(child1.linkedItem, false, "r")
            assertMismatchingTags(child1.linkedItem, 1, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 1, 2, "Parent", .orphan, 6)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 3, 1, 2, "Parent", .orphan, 28)
            #expect(child2.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2, false, "Parent")
            assertMismatchingTags(child2, 1, "Parent")
            assertFolderTags(child2.linkedItem, false, "Parent")
            assertMismatchingTags(child2.linkedItem, 1, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 0, 3, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 3, 0, 3, "FolderWithTags", .orphan, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3, false, "FolderWithTags")
            assertMismatchingTags(child3, 0, "FolderWithTags")
            assertFolderTags(child3.linkedItem, false, "FolderWithTags")
            assertMismatchingTags(child3.linkedItem, 0, "FolderWithTags")

            let childVI4 = childVI3.children[0] // (null) <--> FolderWithTags
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // (null) <-> FolderWithTags
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "attachment_one.txt", .orphan, 6)
            assertFolderTags(child4, false, "attachment_one.txt")
            assertMismatchingTags(child4, 0, "attachment_one.txt")
            assertFolderTags(child4.linkedItem, false, "attachment_one.txt")
            assertMismatchingTags(child4.linkedItem, 0, "attachment_one.txt")

            let childVI5 = childVI3.children[1] // (null) <--> FolderWithTags
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> FolderWithTags
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file1.txt", .orphan, 6)
            assertFolderTags(child5, false, "file1.txt")
            assertMismatchingTags(child5, 0, "file1.txt")
            assertFolderTags(child5.linkedItem, false, "file1.txt")
            assertMismatchingTags(child5.linkedItem, 0, "file1.txt")

            let childVI6 = childVI3.children[2] // (null) <--> FolderWithTags
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // (null) <-> FolderWithTags
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 10)
            assertFolderTags(child6, false, "file2.txt")
            assertMismatchingTags(child6, 0, "file2.txt")
            assertFolderTags(child6.linkedItem, false, "file2.txt")
            assertMismatchingTags(child6.linkedItem, 0, "file2.txt")

            let childVI7 = childVI2.children[1] // Parent <--> Parent
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "anotherFile.txt", .same, 6)
            assertFolderTags(child7, false, "anotherFile.txt")
            assertMismatchingTags(child7, 1, "anotherFile.txt")
            assertFolderTags(child7.linkedItem, false, "anotherFile.txt")
            assertMismatchingTags(child7.linkedItem, 1, "anotherFile.txt")
        }
    }
}

// swiftlint:enable force_unwrapping function_body_length
