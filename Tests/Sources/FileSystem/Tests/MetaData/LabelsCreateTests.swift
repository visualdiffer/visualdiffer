//
//  LabelsCreateTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/12/21.
//  Copyright (c) 2021 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping function_body_length
final class LabelsCreateTests: BaseTests {
    @Test
    func createLabels() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase, .finderLabel],
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
        try createFolder("l/Parent/FolderWithLabels")
        try createFolder("r/Parent/FolderWithLabels")

        // create files
        try add(labelNumber: 3, fullPath: appendFolder("r/Parent/FolderWithLabels"))
        try createFile("l/Parent/FolderWithLabels/attachment_one.txt", "123456")
        try createFile("r/Parent/FolderWithLabels/attachment_one.txt", "123456")
        try createFile("l/Parent/FolderWithLabels/file1.txt", "123456")
        try createFile("r/Parent/FolderWithLabels/file1.txt", "123456")
        try add(labelNumber: 7, fullPath: appendFolder("r/Parent/FolderWithLabels/file1.txt"))
        try createFile("l/Parent/FolderWithLabels/file2.txt", "1234567890")
        try createFile("r/Parent/FolderWithLabels/file2.txt", "1234567890")
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

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 4, 2, "l", .orphan, 27)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 4, 2, "r", .orphan, 27)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderLabels(child1, false, "r")
            assertMismatchingLabels(child1, 2, "r")
            assertFolderLabels(child1.linkedItem, false, "r")
            assertMismatchingLabels(child1.linkedItem, 2, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderLabels(child2, false, "Parent")
            assertMismatchingLabels(child2, 2, "Parent")
            assertFolderLabels(child2.linkedItem, false, "Parent")
            assertMismatchingLabels(child2.linkedItem, 2, "Parent")

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 3, 3, "FolderWithLabels", .mismatchingLabels, 22)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "FolderWithLabels", .mismatchingLabels, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderLabels(child3, true, "FolderWithLabels")
            assertMismatchingLabels(child3, 1, "FolderWithLabels")
            assertFolderLabels(child3.linkedItem, true, "FolderWithLabels")
            assertMismatchingLabels(child3.linkedItem, 1, "FolderWithLabels")

            let child4 = child3.children[0] // FolderWithLabels <-> FolderWithLabels
            assertItem(child4, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertFolderLabels(child4, false, "attachment_one.txt")
            assertMismatchingLabels(child4, 0, "attachment_one.txt")
            assertFolderLabels(child4.linkedItem, false, "attachment_one.txt")
            assertMismatchingLabels(child4.linkedItem, 0, "attachment_one.txt")

            let child5 = child3.children[1] // FolderWithLabels <-> FolderWithLabels
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertFolderLabels(child5, false, "file1.txt")
            assertMismatchingLabels(child5, 1, "file1.txt")
            assertFolderLabels(child5.linkedItem, false, "file1.txt")
            assertMismatchingLabels(child5.linkedItem, 1, "file1.txt")

            let child6 = child3.children[2] // FolderWithLabels <-> FolderWithLabels
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderLabels(child6, false, "file2.txt")
            assertMismatchingLabels(child6, 0, "file2.txt")
            assertFolderLabels(child6.linkedItem, false, "file2.txt")
            assertMismatchingLabels(child6.linkedItem, 0, "file2.txt")

            let child7 = child1.children[1] // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child7, false, "line1.txt")
            assertMismatchingLabels(child7, 0, "line1.txt")
            assertFolderLabels(child7.linkedItem, false, "line1.txt")
            assertMismatchingLabels(child7.linkedItem, 0, "line1.txt")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 4, 2, "l", .orphan, 27)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 4, 2, "r", .orphan, 27)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderLabels(child1, false, "r")
            assertMismatchingLabels(child1, 2, "r")
            assertFolderLabels(child1.linkedItem, false, "r")
            assertMismatchingLabels(child1.linkedItem, 2, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 3, 1, "Parent", .orphan, 22)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderLabels(child2, false, "Parent")
            assertMismatchingLabels(child2, 2, "Parent")
            assertFolderLabels(child2.linkedItem, false, "Parent")
            assertMismatchingLabels(child2.linkedItem, 2, "Parent")

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 3, 3, "FolderWithLabels", .mismatchingLabels, 22)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 3, 3, "FolderWithLabels", .mismatchingLabels, 22)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderLabels(child3, true, "FolderWithLabels")
            assertMismatchingLabels(child3, 1, "FolderWithLabels")
            assertFolderLabels(child3.linkedItem, true, "FolderWithLabels")
            assertMismatchingLabels(child3.linkedItem, 1, "FolderWithLabels")

            let childVI4 = childVI3.children[0] // FolderWithLabels <--> FolderWithLabels
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // FolderWithLabels <-> FolderWithLabels
            assertItem(child4, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "attachment_one.txt", .same, 6)
            assertFolderLabels(child4, false, "attachment_one.txt")
            assertMismatchingLabels(child4, 0, "attachment_one.txt")
            assertFolderLabels(child4.linkedItem, false, "attachment_one.txt")
            assertMismatchingLabels(child4.linkedItem, 0, "attachment_one.txt")

            let childVI5 = childVI3.children[1] // FolderWithLabels <--> FolderWithLabels
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // FolderWithLabels <-> FolderWithLabels
            assertItem(child5, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "file1.txt", .same, 6)
            assertFolderLabels(child5, false, "file1.txt")
            assertMismatchingLabels(child5, 1, "file1.txt")
            assertFolderLabels(child5.linkedItem, false, "file1.txt")
            assertMismatchingLabels(child5.linkedItem, 1, "file1.txt")

            let childVI6 = childVI3.children[2] // FolderWithLabels <--> FolderWithLabels
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithLabels <-> FolderWithLabels
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderLabels(child6, false, "file2.txt")
            assertMismatchingLabels(child6, 0, "file2.txt")
            assertFolderLabels(child6.linkedItem, false, "file2.txt")
            assertMismatchingLabels(child6.linkedItem, 0, "file2.txt")

            let childVI7 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child7, false, "line1.txt")
            assertMismatchingLabels(child7, 0, "line1.txt")
            assertFolderLabels(child7.linkedItem, false, "line1.txt")
            assertMismatchingLabels(child7.linkedItem, 0, "line1.txt")
        }
    }
}

// swiftlint:enable force_unwrapping function_body_length
