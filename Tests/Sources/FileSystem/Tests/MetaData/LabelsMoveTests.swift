//
//  LabelsMoveTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/12/21.
//  Copyright (c) 2021 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class LabelsMoveTests: BaseTests {
    @Test func moveFolderWithLabels() throws {
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
        try createFolder("l/Parent/Level2")
        try createFolder("r/Parent/Level2")
        try createFolder("l/Parent/Level2/FolderWithLabels")
        try createFolder("r/Parent/Level2/FolderWithLabels")

        // create files
        try add(labelNumber: 3, fullPath: appendFolder("r/Parent/Level2/FolderWithLabels"))
        try createFile("l/Parent/Level2/FolderWithLabels/file1.txt", "123456")
        try createFile("r/Parent/Level2/FolderWithLabels/file1.txt", "123456")
        try add(labelNumber: 7, fullPath: appendFolder("r/Parent/Level2/FolderWithLabels/file1.txt"))
        try createFile("l/Parent/Level2/FolderWithLabels/file2.txt", "1234567890")
        try createFile("r/Parent/Level2/FolderWithLabels/file2.txt", "1234567890")
        try createFile("l/Parent/line2.txt", "12345")
        try createFile("r/Parent/line2.txt", "12345")
        try add(labelNumber: 2, fullPath: appendFolder("r/Parent/line2.txt"))
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
            assertItem(child1, 0, 0, 0, 2, 2, "l", .orphan, 26)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertFolderLabels(child1, false, "l")
            assertMismatchingLabels(child1, 3, "l")
            assertResourceFileLabels(child1, 0, appendFolder("l"))
            assertItem(child1.linkedItem, 0, 0, 0, 2, 2, "r", .orphan, 26)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderLabels(child1.linkedItem, false, "r")
            assertMismatchingLabels(child1.linkedItem, 3, "r")
            assertResourceFileLabels(child1.linkedItem, 0, appendFolder("r"))

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 1, 2, "Parent", .orphan, 21)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertFolderLabels(child2, false, "Parent")
            assertMismatchingLabels(child2, 3, "Parent")
            assertResourceFileLabels(child2, 0, appendFolder("l/Parent"))
            assertItem(child2.linkedItem, 0, 0, 0, 1, 2, "Parent", .orphan, 21)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderLabels(child2.linkedItem, false, "Parent")
            assertMismatchingLabels(child2.linkedItem, 3, "Parent")
            assertResourceFileLabels(child2.linkedItem, 0, appendFolder("r/Parent"))

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 1, 1, "Level2", .orphan, 16)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertFolderLabels(child3, false, "Level2")
            assertMismatchingLabels(child3, 2, "Level2")
            assertResourceFileLabels(child3, 0, appendFolder("l/Parent/Level2"))
            assertItem(child3.linkedItem, 0, 0, 0, 1, 1, "Level2", .orphan, 16)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderLabels(child3.linkedItem, false, "Level2")
            assertMismatchingLabels(child3.linkedItem, 2, "Level2")
            assertResourceFileLabels(child3.linkedItem, 0, appendFolder("r/Parent/Level2"))

            let child4 = child3.children[0] // Level2 <-> Level2
            assertItem(child4, 0, 0, 0, 1, 2, "FolderWithLabels", .mismatchingLabels, 16)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertFolderLabels(child4, true, "FolderWithLabels")
            assertMismatchingLabels(child4, 1, "FolderWithLabels")
            assertResourceFileLabels(child4, 0, appendFolder("l/Parent/Level2/FolderWithLabels"))
            assertItem(child4.linkedItem, 0, 0, 0, 1, 2, "FolderWithLabels", .mismatchingLabels, 16)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
            assertFolderLabels(child4.linkedItem, true, "FolderWithLabels")
            assertMismatchingLabels(child4.linkedItem, 1, "FolderWithLabels")
            assertResourceFileLabels(child4.linkedItem, 3, appendFolder("r/Parent/Level2/FolderWithLabels"))

            let child5 = child4.children[0] // FolderWithLabels <-> FolderWithLabels
            assertItem(child5, 0, 0, 0, 0, 0, "file1.txt", .same, 6)
            assertFolderLabels(child5, false, "file1.txt")
            assertMismatchingLabels(child5, 1, "file1.txt")
            assertResourceFileLabels(child5, 0, appendFolder("l/Parent/Level2/FolderWithLabels/file1.txt"))
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "file1.txt", .same, 6)
            assertFolderLabels(child5.linkedItem, false, "file1.txt")
            assertMismatchingLabels(child5.linkedItem, 1, "file1.txt")
            assertResourceFileLabels(child5.linkedItem, 7, appendFolder("r/Parent/Level2/FolderWithLabels/file1.txt"))

            let child6 = child4.children[1] // FolderWithLabels <-> FolderWithLabels
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderLabels(child6, false, "file2.txt")
            assertMismatchingLabels(child6, 0, "file2.txt")
            assertResourceFileLabels(child6, 0, appendFolder("l/Parent/Level2/FolderWithLabels/file2.txt"))
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderLabels(child6.linkedItem, false, "file2.txt")
            assertMismatchingLabels(child6.linkedItem, 0, "file2.txt")
            assertResourceFileLabels(child6.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels/file2.txt"))

            let child7 = child2.children[1] // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7, false, "line2.txt")
            assertMismatchingLabels(child7, 1, "line2.txt")
            assertResourceFileLabels(child7, 0, appendFolder("l/Parent/line2.txt"))
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7.linkedItem, false, "line2.txt")
            assertMismatchingLabels(child7.linkedItem, 1, "line2.txt")
            assertResourceFileLabels(child7.linkedItem, 2, appendFolder("r/Parent/line2.txt"))

            let child8 = child1.children[1] // l <-> r
            assertItem(child8, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8, false, "line1.txt")
            assertMismatchingLabels(child8, 0, "line1.txt")
            assertResourceFileLabels(child8, 0, appendFolder("l/line1.txt"))
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8.linkedItem, false, "line1.txt")
            assertMismatchingLabels(child8.linkedItem, 0, "line1.txt")
            assertResourceFileLabels(child8.linkedItem, 0, appendFolder("r/line1.txt"))
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 2, 2, "l", .orphan, 26)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertFolderLabels(child1, false, "l")
            assertMismatchingLabels(child1, 3, "l")
            assertResourceFileLabels(child1, 0, appendFolder("l"))
            assertItem(child1.linkedItem, 0, 0, 0, 2, 2, "r", .orphan, 26)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")
            assertFolderLabels(child1.linkedItem, false, "r")
            assertMismatchingLabels(child1.linkedItem, 3, "r")
            assertResourceFileLabels(child1.linkedItem, 0, appendFolder("r"))

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 1, 2, "Parent", .orphan, 21)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertFolderLabels(child2, false, "Parent")
            assertMismatchingLabels(child2, 3, "Parent")
            assertResourceFileLabels(child2, 0, appendFolder("l/Parent"))
            assertItem(child2.linkedItem, 0, 0, 0, 1, 2, "Parent", .orphan, 21)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")
            assertFolderLabels(child2.linkedItem, false, "Parent")
            assertMismatchingLabels(child2.linkedItem, 3, "Parent")
            assertResourceFileLabels(child2.linkedItem, 0, appendFolder("r/Parent"))

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // Parent <-> Parent
            operationElement = child3
            assertItem(child3, 0, 0, 0, 1, 1, "Level2", .orphan, 16)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertFolderLabels(child3, false, "Level2")
            assertMismatchingLabels(child3, 2, "Level2")
            assertResourceFileLabels(child3, 0, appendFolder("l/Parent/Level2"))
            assertItem(child3.linkedItem, 0, 0, 0, 1, 1, "Level2", .orphan, 16)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")
            assertFolderLabels(child3.linkedItem, false, "Level2")
            assertMismatchingLabels(child3.linkedItem, 2, "Level2")
            assertResourceFileLabels(child3.linkedItem, 0, appendFolder("r/Parent/Level2"))

            let childVI4 = childVI3.children[0] // Level2 <--> Level2
            assertArrayCount(childVI4.children, 2)
            let child4 = childVI4.item // Level2 <-> Level2
            assertItem(child4, 0, 0, 0, 1, 2, "FolderWithLabels", .mismatchingLabels, 16)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertFolderLabels(child4, true, "FolderWithLabels")
            assertMismatchingLabels(child4, 1, "FolderWithLabels")
            assertResourceFileLabels(child4, 0, appendFolder("l/Parent/Level2/FolderWithLabels"))
            assertItem(child4.linkedItem, 0, 0, 0, 1, 2, "FolderWithLabels", .mismatchingLabels, 16)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
            assertFolderLabels(child4.linkedItem, true, "FolderWithLabels")
            assertMismatchingLabels(child4.linkedItem, 1, "FolderWithLabels")
            assertResourceFileLabels(child4.linkedItem, 3, appendFolder("r/Parent/Level2/FolderWithLabels"))

            let childVI5 = childVI4.children[0] // FolderWithLabels <--> FolderWithLabels
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // FolderWithLabels <-> FolderWithLabels
            assertItem(child5, 0, 0, 0, 0, 0, "file1.txt", .same, 6)
            assertFolderLabels(child5, false, "file1.txt")
            assertMismatchingLabels(child5, 1, "file1.txt")
            assertResourceFileLabels(child5, 0, appendFolder("l/Parent/Level2/FolderWithLabels/file1.txt"))
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "file1.txt", .same, 6)
            assertFolderLabels(child5.linkedItem, false, "file1.txt")
            assertMismatchingLabels(child5.linkedItem, 1, "file1.txt")
            assertResourceFileLabels(child5.linkedItem, 7, appendFolder("r/Parent/Level2/FolderWithLabels/file1.txt"))

            let childVI6 = childVI4.children[1] // FolderWithLabels <--> FolderWithLabels
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // FolderWithLabels <-> FolderWithLabels
            assertItem(child6, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderLabels(child6, false, "file2.txt")
            assertMismatchingLabels(child6, 0, "file2.txt")
            assertResourceFileLabels(child6, 0, appendFolder("l/Parent/Level2/FolderWithLabels/file2.txt"))
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file2.txt", .same, 10)
            assertFolderLabels(child6.linkedItem, false, "file2.txt")
            assertMismatchingLabels(child6.linkedItem, 0, "file2.txt")
            assertResourceFileLabels(child6.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels/file2.txt"))

            let childVI7 = childVI2.children[1] // Parent <--> Parent
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7, false, "line2.txt")
            assertMismatchingLabels(child7, 1, "line2.txt")
            assertResourceFileLabels(child7, 0, appendFolder("l/Parent/line2.txt"))
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7.linkedItem, false, "line2.txt")
            assertMismatchingLabels(child7.linkedItem, 1, "line2.txt")
            assertResourceFileLabels(child7.linkedItem, 2, appendFolder("r/Parent/line2.txt"))

            let childVI8 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8, false, "line1.txt")
            assertMismatchingLabels(child8, 0, "line1.txt")
            assertResourceFileLabels(child8, 0, appendFolder("l/line1.txt"))
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8.linkedItem, false, "line1.txt")
            assertMismatchingLabels(child8.linkedItem, 0, "line1.txt")
            assertResourceFileLabels(child8.linkedItem, 0, appendFolder("r/line1.txt"))
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
            assertItem(child1, 0, 0, 0, 1, 2, "l", .orphan, 10)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertFolderLabels(child1, false, "l")
            assertMismatchingLabels(child1, 1, "l")
            assertResourceFileLabels(child1, 0, appendFolder("l"))
            assertItem(child1.linkedItem, 0, 0, 2, 1, 2, "r", .orphan, 26)
            #expect(child1.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.linkedItem!.orphanFolders)")
            assertFolderLabels(child1.linkedItem, false, "r")
            assertMismatchingLabels(child1.linkedItem, 1, "r")
            assertResourceFileLabels(child1.linkedItem, 0, appendFolder("r"))

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 2, "Parent", .orphan, 5)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertFolderLabels(child2, false, "Parent")
            assertMismatchingLabels(child2, 1, "Parent")
            assertResourceFileLabels(child2, 0, appendFolder("l/Parent"))
            assertItem(child2.linkedItem, 0, 0, 2, 0, 2, "Parent", .orphan, 21)
            #expect(child2.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child2.linkedItem!.orphanFolders)")
            assertFolderLabels(child2.linkedItem, false, "Parent")
            assertMismatchingLabels(child2.linkedItem, 1, "Parent")
            assertResourceFileLabels(child2.linkedItem, 0, appendFolder("r/Parent"))

            let child3 = child2.children[0] // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertFolderLabels(child3, false, nil)
            assertMismatchingLabels(child3, 0, nil)
            assertItem(child3.linkedItem, 0, 0, 2, 0, 1, "Level2", .orphan, 16)
            #expect(child3.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child3.linkedItem!.orphanFolders)")
            assertFolderLabels(child3.linkedItem, false, "Level2")
            assertMismatchingLabels(child3.linkedItem, 0, "Level2")
            assertResourceFileLabels(child3.linkedItem, 0, appendFolder("r/Parent/Level2"))

            let child4 = child3.children[0] // (null) <-> Level2
            assertItem(child4, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertFolderLabels(child4, false, nil)
            assertMismatchingLabels(child4, 0, nil)
            assertItem(child4.linkedItem, 0, 0, 2, 0, 2, "FolderWithLabels", .orphan, 16)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
            assertFolderLabels(child4.linkedItem, false, "FolderWithLabels")
            assertMismatchingLabels(child4.linkedItem, 0, "FolderWithLabels")
            assertResourceFileLabels(child4.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels"))

            let child5 = child4.children[0] // (null) <-> FolderWithLabels
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertFolderLabels(child5, false, nil)
            assertMismatchingLabels(child5, 0, nil)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file1.txt", .orphan, 6)
            assertFolderLabels(child5.linkedItem, false, "file1.txt")
            assertMismatchingLabels(child5.linkedItem, 0, "file1.txt")
            assertResourceFileLabels(child5.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels/file1.txt"))

            let child6 = child4.children[1] // (null) <-> FolderWithLabels
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertFolderLabels(child6, false, nil)
            assertMismatchingLabels(child6, 0, nil)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 10)
            assertFolderLabels(child6.linkedItem, false, "file2.txt")
            assertMismatchingLabels(child6.linkedItem, 0, "file2.txt")
            assertResourceFileLabels(child6.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels/file2.txt"))

            let child7 = child2.children[1] // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7, false, "line2.txt")
            assertMismatchingLabels(child7, 1, "line2.txt")
            assertResourceFileLabels(child7, 0, appendFolder("l/Parent/line2.txt"))
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7.linkedItem, false, "line2.txt")
            assertMismatchingLabels(child7.linkedItem, 1, "line2.txt")
            assertResourceFileLabels(child7.linkedItem, 2, appendFolder("r/Parent/line2.txt"))

            let child8 = child1.children[1] // l <-> r
            assertItem(child8, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8, false, "line1.txt")
            assertMismatchingLabels(child8, 0, "line1.txt")
            assertResourceFileLabels(child8, 0, appendFolder("l/line1.txt"))
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8.linkedItem, false, "line1.txt")
            assertMismatchingLabels(child8.linkedItem, 0, "line1.txt")
            assertResourceFileLabels(child8.linkedItem, 0, appendFolder("r/line1.txt"))
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 1, 2, "l", .orphan, 10)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertFolderLabels(child1, false, "l")
            assertMismatchingLabels(child1, 1, "l")
            assertResourceFileLabels(child1, 0, appendFolder("l"))
            assertItem(child1.linkedItem, 0, 0, 2, 1, 2, "r", .orphan, 26)
            #expect(child1.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.linkedItem!.orphanFolders)")
            assertFolderLabels(child1.linkedItem, false, "r")
            assertMismatchingLabels(child1.linkedItem, 1, "r")
            assertResourceFileLabels(child1.linkedItem, 0, appendFolder("r"))

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 2, "Parent", .orphan, 5)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertFolderLabels(child2, false, "Parent")
            assertMismatchingLabels(child2, 1, "Parent")
            assertResourceFileLabels(child2, 0, appendFolder("l/Parent"))
            assertItem(child2.linkedItem, 0, 0, 2, 0, 2, "Parent", .orphan, 21)
            #expect(child2.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child2.linkedItem!.orphanFolders)")
            assertFolderLabels(child2.linkedItem, false, "Parent")
            assertMismatchingLabels(child2.linkedItem, 1, "Parent")
            assertResourceFileLabels(child2.linkedItem, 0, appendFolder("r/Parent"))

            let childVI3 = childVI2.children[0] // Parent <--> Parent
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // Parent <-> Parent
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertFolderLabels(child3, false, nil)
            assertMismatchingLabels(child3, 0, nil)
            assertItem(child3.linkedItem, 0, 0, 2, 0, 1, "Level2", .orphan, 16)
            #expect(child3.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child3.linkedItem!.orphanFolders)")
            assertFolderLabels(child3.linkedItem, false, "Level2")
            assertMismatchingLabels(child3.linkedItem, 0, "Level2")
            assertResourceFileLabels(child3.linkedItem, 0, appendFolder("r/Parent/Level2"))

            let childVI4 = childVI3.children[0] // (null) <--> Level2
            assertArrayCount(childVI4.children, 2)
            let child4 = childVI4.item // (null) <-> Level2
            assertItem(child4, 0, 0, 0, 0, 2, nil, .orphan, 0)
            assertFolderLabels(child4, false, nil)
            assertMismatchingLabels(child4, 0, nil)
            assertItem(child4.linkedItem, 0, 0, 2, 0, 2, "FolderWithLabels", .orphan, 16)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
            assertFolderLabels(child4.linkedItem, false, "FolderWithLabels")
            assertMismatchingLabels(child4.linkedItem, 0, "FolderWithLabels")
            assertResourceFileLabels(child4.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels"))

            let childVI5 = childVI4.children[0] // (null) <--> FolderWithLabels
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> FolderWithLabels
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertFolderLabels(child5, false, nil)
            assertMismatchingLabels(child5, 0, nil)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file1.txt", .orphan, 6)
            assertFolderLabels(child5.linkedItem, false, "file1.txt")
            assertMismatchingLabels(child5.linkedItem, 0, "file1.txt")
            assertResourceFileLabels(child5.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels/file1.txt"))

            let childVI6 = childVI4.children[1] // (null) <--> FolderWithLabels
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // (null) <-> FolderWithLabels
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertFolderLabels(child6, false, nil)
            assertMismatchingLabels(child6, 0, nil)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file2.txt", .orphan, 10)
            assertFolderLabels(child6.linkedItem, false, "file2.txt")
            assertMismatchingLabels(child6.linkedItem, 0, "file2.txt")
            assertResourceFileLabels(child6.linkedItem, 0, appendFolder("r/Parent/Level2/FolderWithLabels/file2.txt"))

            let childVI7 = childVI2.children[1] // Parent <--> Parent
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // Parent <-> Parent
            assertItem(child7, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7, false, "line2.txt")
            assertMismatchingLabels(child7, 1, "line2.txt")
            assertResourceFileLabels(child7, 0, appendFolder("l/Parent/line2.txt"))
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "line2.txt", .same, 5)
            assertFolderLabels(child7.linkedItem, false, "line2.txt")
            assertMismatchingLabels(child7.linkedItem, 1, "line2.txt")
            assertResourceFileLabels(child7.linkedItem, 2, appendFolder("r/Parent/line2.txt"))

            let childVI8 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8, false, "line1.txt")
            assertMismatchingLabels(child8, 0, "line1.txt")
            assertResourceFileLabels(child8, 0, appendFolder("l/line1.txt"))
            assertItem(child8.linkedItem, 0, 0, 0, 1, 0, "line1.txt", .same, 5)
            assertFolderLabels(child8.linkedItem, false, "line1.txt")
            assertMismatchingLabels(child8.linkedItem, 0, "line1.txt")
            assertResourceFileLabels(child8.linkedItem, 0, appendFolder("r/line1.txt"))
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
