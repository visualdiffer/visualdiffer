//
//  EmptyFolderColorTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/11/21.
//  Copyright (c) 2021 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class EmptyFolderColorTests: BaseTests {
    @Test func initialColors() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 9100,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/empty")
        try createFolder("r/empty")
        try createFolder("r/empty/empty1")
        try createFolder("r/empty/empty1/empty2")
        try createFolder("r/empty/empty1/empty2/empty3")
        try createFolder("r/empty/empty2")
        try createFolder("r/empty/empty3")
        try createFolder("l/utils")
        try createFolder("r/utils")
        try createFolder("l/utils/cell")
        try createFolder("r/utils/cell")
        try createFolder("l/utils/cell/popup")
        try createFolder("r/utils/cell/popup")
        try createFolder("l/utils/view")
        try createFolder("l/utils/view/splitview")

        // create files
        try createFile("l/utils/cell/popup/file", "12345")
        try createFile("r/utils/cell/popup/file", "123456")
        try setFileTimestamp("r/utils/cell/popup/file", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/file", "1234")

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
            assertItem(child1, 0, 1, 0, 0, 3, "l", .orphan, 5)
            #expect(child1.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 1, 0, 3, "r", .orphan, 10)
            #expect(child1.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // empty <-> empty
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "empty1", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // (null) <-> empty1
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 1, "empty2", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child4.linkedItem!.orphanFolders)")

            let child5 = child4.children[0] // (null) <-> empty2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child5.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child5.linkedItem!.orphanFolders)")

            let child6 = child2.children[1] // empty <-> empty
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, "empty2", .orphan, 0)
            #expect(child6.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child6.linkedItem!.orphanFolders)")

            let child7 = child2.children[2] // empty <-> empty
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child7.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child7.linkedItem!.orphanFolders)")

            let child8 = child1.children[1] // l <-> r
            assertItem(child8, 0, 1, 0, 0, 2, "utils", .orphan, 5)
            #expect(child8.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 2, "utils", .orphan, 6)
            #expect(child8.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.linkedItem!.orphanFolders)")

            let child9 = child8.children[0] // utils <-> utils
            assertItem(child9, 0, 1, 0, 0, 1, "cell", .orphan, 5)
            #expect(child9.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.orphanFolders)")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 1, "cell", .orphan, 6)
            #expect(child9.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.linkedItem!.orphanFolders)")

            let child10 = child9.children[0] // cell <-> cell
            assertItem(child10, 0, 1, 0, 0, 1, "popup", .orphan, 5)
            #expect(child10.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.orphanFolders)")
            assertItem(child10.linkedItem, 1, 0, 0, 0, 1, "popup", .orphan, 6)
            #expect(child10.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.linkedItem!.orphanFolders)")

            let child11 = child10.children[0] // popup <-> popup
            assertItem(child11, 0, 1, 0, 0, 0, "file", .changed, 5)
            assertItem(child11.linkedItem, 1, 0, 0, 0, 0, "file", .old, 6)

            let child12 = child8.children[1] // utils <-> utils
            assertItem(child12, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child12.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child12.orphanFolders)")
            assertItem(child12.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child13 = child12.children[0] // view <-> (null)
            assertItem(child13, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child13.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child13.orphanFolders)")
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child14 = child1.children[2] // l <-> r
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file", .orphan, 4)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 1, 0, 0, 3, "l", .orphan, 5)
            #expect(child1.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 1, 0, 3, "r", .orphan, 10)
            #expect(child1.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // empty <--> empty
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // empty <-> empty
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "empty1", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // (null) <--> empty1
            assertArrayCount(childVI4.children, 1)
            let child4 = childVI4.item // (null) <-> empty1
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 1, "empty2", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // (null) <--> empty2
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> empty2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child5.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child5.linkedItem!.orphanFolders)")

            let childVI6 = childVI2.children[1] // empty <--> empty
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // empty <-> empty
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, "empty2", .orphan, 0)
            #expect(child6.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child6.linkedItem!.orphanFolders)")

            let childVI7 = childVI2.children[2] // empty <--> empty
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // empty <-> empty
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child7.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child7.linkedItem!.orphanFolders)")

            let childVI8 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI8.children, 2)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 1, 0, 0, 2, "utils", .orphan, 5)
            #expect(child8.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 2, "utils", .orphan, 6)
            #expect(child8.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.linkedItem!.orphanFolders)")

            let childVI9 = childVI8.children[0] // utils <--> utils
            assertArrayCount(childVI9.children, 1)
            let child9 = childVI9.item // utils <-> utils
            assertItem(child9, 0, 1, 0, 0, 1, "cell", .orphan, 5)
            #expect(child9.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.orphanFolders)")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 1, "cell", .orphan, 6)
            #expect(child9.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.linkedItem!.orphanFolders)")

            let childVI10 = childVI9.children[0] // cell <--> cell
            assertArrayCount(childVI10.children, 1)
            let child10 = childVI10.item // cell <-> cell
            assertItem(child10, 0, 1, 0, 0, 1, "popup", .orphan, 5)
            #expect(child10.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.orphanFolders)")
            assertItem(child10.linkedItem, 1, 0, 0, 0, 1, "popup", .orphan, 6)
            #expect(child10.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.linkedItem!.orphanFolders)")

            let childVI11 = childVI10.children[0] // popup <--> popup
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // popup <-> popup
            assertItem(child11, 0, 1, 0, 0, 0, "file", .changed, 5)
            assertItem(child11.linkedItem, 1, 0, 0, 0, 0, "file", .old, 6)

            let childVI12 = childVI8.children[1] // utils <--> utils
            assertArrayCount(childVI12.children, 1)
            let child12 = childVI12.item // utils <-> utils
            assertItem(child12, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child12.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child12.orphanFolders)")
            assertItem(child12.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI13 = childVI12.children[0] // view <--> (null)
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // view <-> (null)
            assertItem(child13, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child13.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child13.orphanFolders)")
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI14 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI14.children, 0)
            let child14 = childVI14.item // l <-> r
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file", .orphan, 4)
        }
    }

    @Test func moveFolderWithChild() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 9100,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/empty")
        try createFolder("r/empty")
        try createFolder("r/empty/empty1")
        try createFolder("r/empty/empty1/empty2")
        try createFolder("r/empty/empty1/empty2/empty3")
        try createFolder("r/empty/empty2")
        try createFolder("r/empty/empty3")
        try createFolder("l/utils")
        try createFolder("r/utils")
        try createFolder("l/utils/cell")
        try createFolder("r/utils/cell")
        try createFolder("l/utils/cell/popup")
        try createFolder("r/utils/cell/popup")
        try createFolder("l/utils/view")
        try createFolder("l/utils/view/splitview")

        // create files
        try createFile("l/utils/cell/popup/file", "12345")
        try createFile("r/utils/cell/popup/file", "123456")
        try setFileTimestamp("r/utils/cell/popup/file", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/file", "1234")

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
            assertItem(child1, 0, 1, 0, 0, 3, "l", .orphan, 5)
            #expect(child1.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 1, 0, 3, "r", .orphan, 10)
            #expect(child1.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // empty <-> empty
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "empty1", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // (null) <-> empty1
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 1, "empty2", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child4.linkedItem!.orphanFolders)")

            let child5 = child4.children[0] // (null) <-> empty2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child5.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child5.linkedItem!.orphanFolders)")

            let child6 = child2.children[1] // empty <-> empty
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, "empty2", .orphan, 0)
            #expect(child6.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child6.linkedItem!.orphanFolders)")

            let child7 = child2.children[2] // empty <-> empty
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child7.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child7.linkedItem!.orphanFolders)")

            let child8 = child1.children[1] // l <-> r
            assertItem(child8, 0, 1, 0, 0, 2, "utils", .orphan, 5)
            #expect(child8.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 2, "utils", .orphan, 6)
            #expect(child8.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.linkedItem!.orphanFolders)")

            let child9 = child8.children[0] // utils <-> utils
            assertItem(child9, 0, 1, 0, 0, 1, "cell", .orphan, 5)
            #expect(child9.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.orphanFolders)")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 1, "cell", .orphan, 6)
            #expect(child9.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.linkedItem!.orphanFolders)")

            let child10 = child9.children[0] // cell <-> cell
            assertItem(child10, 0, 1, 0, 0, 1, "popup", .orphan, 5)
            #expect(child10.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.orphanFolders)")
            assertItem(child10.linkedItem, 1, 0, 0, 0, 1, "popup", .orphan, 6)
            #expect(child10.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.linkedItem!.orphanFolders)")

            let child11 = child10.children[0] // popup <-> popup
            assertItem(child11, 0, 1, 0, 0, 0, "file", .changed, 5)
            assertItem(child11.linkedItem, 1, 0, 0, 0, 0, "file", .old, 6)

            let child12 = child8.children[1] // utils <-> utils
            operationElement = child12
            assertItem(child12, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child12.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child12.orphanFolders)")
            assertItem(child12.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child13 = child12.children[0] // view <-> (null)
            assertItem(child13, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child13.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child13.orphanFolders)")
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child14 = child1.children[2] // l <-> r
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file", .orphan, 4)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 1, 0, 0, 3, "l", .orphan, 5)
            #expect(child1.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 1, 0, 3, "r", .orphan, 10)
            #expect(child1.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // empty <--> empty
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // empty <-> empty
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "empty1", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // (null) <--> empty1
            assertArrayCount(childVI4.children, 1)
            let child4 = childVI4.item // (null) <-> empty1
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 1, "empty2", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // (null) <--> empty2
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> empty2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child5.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child5.linkedItem!.orphanFolders)")

            let childVI6 = childVI2.children[1] // empty <--> empty
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // empty <-> empty
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, "empty2", .orphan, 0)
            #expect(child6.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child6.linkedItem!.orphanFolders)")

            let childVI7 = childVI2.children[2] // empty <--> empty
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // empty <-> empty
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child7.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child7.linkedItem!.orphanFolders)")

            let childVI8 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI8.children, 2)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 1, 0, 0, 2, "utils", .orphan, 5)
            #expect(child8.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 2, "utils", .orphan, 6)
            #expect(child8.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.linkedItem!.orphanFolders)")

            let childVI9 = childVI8.children[0] // utils <--> utils
            assertArrayCount(childVI9.children, 1)
            let child9 = childVI9.item // utils <-> utils
            assertItem(child9, 0, 1, 0, 0, 1, "cell", .orphan, 5)
            #expect(child9.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.orphanFolders)")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 1, "cell", .orphan, 6)
            #expect(child9.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.linkedItem!.orphanFolders)")

            let childVI10 = childVI9.children[0] // cell <--> cell
            assertArrayCount(childVI10.children, 1)
            let child10 = childVI10.item // cell <-> cell
            assertItem(child10, 0, 1, 0, 0, 1, "popup", .orphan, 5)
            #expect(child10.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.orphanFolders)")
            assertItem(child10.linkedItem, 1, 0, 0, 0, 1, "popup", .orphan, 6)
            #expect(child10.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.linkedItem!.orphanFolders)")

            let childVI11 = childVI10.children[0] // popup <--> popup
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // popup <-> popup
            assertItem(child11, 0, 1, 0, 0, 0, "file", .changed, 5)
            assertItem(child11.linkedItem, 1, 0, 0, 0, 0, "file", .old, 6)

            let childVI12 = childVI8.children[1] // utils <--> utils
            assertArrayCount(childVI12.children, 1)
            let child12 = childVI12.item // utils <-> utils
            assertItem(child12, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child12.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child12.orphanFolders)")
            assertItem(child12.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI13 = childVI12.children[0] // view <--> (null)
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // view <-> (null)
            assertItem(child13, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child13.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child13.orphanFolders)")
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI14 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI14.children, 0)
            let child14 = childVI14.item // l <-> r
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file", .orphan, 4)
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
            assertItem(child1, 0, 1, 0, 0, 3, "l", .orphan, 5)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 1, 0, 3, "r", .orphan, 10)
            #expect(child1.linkedItem?.orphanFolders == 7, "OrphanFolder: Expected count \(7) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // empty <-> empty
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "empty1", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // (null) <-> empty1
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 1, "empty2", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child4.linkedItem!.orphanFolders)")

            let child5 = child4.children[0] // (null) <-> empty2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child5.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child5.linkedItem!.orphanFolders)")

            let child6 = child2.children[1] // empty <-> empty
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, "empty2", .orphan, 0)
            #expect(child6.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child6.linkedItem!.orphanFolders)")

            let child7 = child2.children[2] // empty <-> empty
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child7.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child7.linkedItem!.orphanFolders)")

            let child8 = child1.children[1] // l <-> r
            assertItem(child8, 0, 1, 0, 0, 2, "utils", .orphan, 5)
            #expect(child8.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 2, "utils", .orphan, 6)
            #expect(child8.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child8.linkedItem!.orphanFolders)")

            let child9 = child8.children[0] // utils <-> utils
            assertItem(child9, 0, 1, 0, 0, 1, "cell", .orphan, 5)
            #expect(child9.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.orphanFolders)")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 1, "cell", .orphan, 6)
            #expect(child9.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.linkedItem!.orphanFolders)")

            let child10 = child9.children[0] // cell <-> cell
            assertItem(child10, 0, 1, 0, 0, 1, "popup", .orphan, 5)
            #expect(child10.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.orphanFolders)")
            assertItem(child10.linkedItem, 1, 0, 0, 0, 1, "popup", .orphan, 6)
            #expect(child10.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.linkedItem!.orphanFolders)")

            let child11 = child10.children[0] // popup <-> popup
            assertItem(child11, 0, 1, 0, 0, 0, "file", .changed, 5)
            assertItem(child11.linkedItem, 1, 0, 0, 0, 0, "file", .old, 6)

            let child12 = child8.children[1] // utils <-> utils
            assertItem(child12, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child12.linkedItem, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child12.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child12.linkedItem!.orphanFolders)")

            let child13 = child12.children[0] // (null) <-> view
            assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child13.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child13.linkedItem!.orphanFolders)")

            let child14 = child1.children[2] // l <-> r
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file", .orphan, 4)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 1, 0, 0, 3, "l", .orphan, 5)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 1, 0, 1, 0, 3, "r", .orphan, 10)
            #expect(child1.linkedItem?.orphanFolders == 7, "OrphanFolder: Expected count \(7) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 3, "empty", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 5, "OrphanFolder: Expected count \(5) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // empty <--> empty
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // empty <-> empty
            assertItem(child3, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "empty1", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // (null) <--> empty1
            assertArrayCount(childVI4.children, 1)
            let child4 = childVI4.item // (null) <-> empty1
            assertItem(child4, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 1, "empty2", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // (null) <--> empty2
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // (null) <-> empty2
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child5.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child5.linkedItem!.orphanFolders)")

            let childVI6 = childVI2.children[1] // empty <--> empty
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // empty <-> empty
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, "empty2", .orphan, 0)
            #expect(child6.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child6.linkedItem!.orphanFolders)")

            let childVI7 = childVI2.children[2] // empty <--> empty
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // empty <-> empty
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, "empty3", .orphan, 0)
            #expect(child7.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child7.linkedItem!.orphanFolders)")

            let childVI8 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI8.children, 2)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 1, 0, 0, 2, "utils", .orphan, 5)
            #expect(child8.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 2, "utils", .orphan, 6)
            #expect(child8.linkedItem?.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child8.linkedItem!.orphanFolders)")

            let childVI9 = childVI8.children[0] // utils <--> utils
            assertArrayCount(childVI9.children, 1)
            let child9 = childVI9.item // utils <-> utils
            assertItem(child9, 0, 1, 0, 0, 1, "cell", .orphan, 5)
            #expect(child9.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.orphanFolders)")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 1, "cell", .orphan, 6)
            #expect(child9.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child9.linkedItem!.orphanFolders)")

            let childVI10 = childVI9.children[0] // cell <--> cell
            assertArrayCount(childVI10.children, 1)
            let child10 = childVI10.item // cell <-> cell
            assertItem(child10, 0, 1, 0, 0, 1, "popup", .orphan, 5)
            #expect(child10.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.orphanFolders)")
            assertItem(child10.linkedItem, 1, 0, 0, 0, 1, "popup", .orphan, 6)
            #expect(child10.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child10.linkedItem!.orphanFolders)")

            let childVI11 = childVI10.children[0] // popup <--> popup
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // popup <-> popup
            assertItem(child11, 0, 1, 0, 0, 0, "file", .changed, 5)
            assertItem(child11.linkedItem, 1, 0, 0, 0, 0, "file", .old, 6)

            let childVI12 = childVI8.children[1] // utils <--> utils
            assertArrayCount(childVI12.children, 1)
            let child12 = childVI12.item // utils <-> utils
            assertItem(child12, 0, 0, 0, 0, 1, nil, .orphan, 0)
            assertItem(child12.linkedItem, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child12.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child12.linkedItem!.orphanFolders)")

            let childVI13 = childVI12.children[0] // (null) <--> view
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // (null) <-> view
            assertItem(child13, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child13.linkedItem, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child13.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child13.linkedItem!.orphanFolders)")

            let childVI14 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI14.children, 0)
            let child14 = childVI14.item // l <-> r
            assertItem(child14, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child14.linkedItem, 0, 0, 1, 0, 0, "file", .orphan, 4)
        }
    }

    @Test func copy() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 9100,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/utils")
        try createFolder("r/utils")
        try createFolder("l/utils/view")
        try createFolder("l/utils/view/splitview")

        // create files

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
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let child4 = child3.children[0] // view <-> (null)
            assertItem(child4, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 2, "OrphanFolder: Expected count \(2) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // utils <--> utils
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, nil, .orphan, 0)

            let childVI4 = childVI3.children[0] // view <--> (null)
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // view <-> (null)
            operationElement = child4
            assertItem(child4, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
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
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // view <-> view
            assertItem(child4, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // utils <--> utils
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // view <--> view
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // view <-> view
            assertItem(child4, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "splitview", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
        }
    }

    @Test func deleteFolder() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 9100,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/utils")
        try createFolder("r/utils")
        try createFolder("l/utils/view")
        try createFolder("r/utils/view")
        try createFolder("r/utils/view/splitView")

        // create files

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
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // view <-> view
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "splitView", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // utils <--> utils
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 1, "view", .orphan, 0)
            #expect(child3.linkedItem?.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child3.linkedItem!.orphanFolders)")
            operationElement = try #require(child3.linkedItem)

            let childVI4 = childVI3.children[0] // view <--> view
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // view <-> view
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, "splitView", .orphan, 0)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")
        }

        try assertOnlySetup()

        let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: true)

        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false
        )

        let fileOperation = DeleteCompareItem(operationManager: fileOperationManager)
        fileOperation.delete(
            operationElement,
            baseDir: appendFolder("r")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 0, "view", .orphan, 0)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 0, 1, "l", .orphan, 0)
            #expect(child1.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 0, 0, 1, "r", .orphan, 0)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.orphanFolders == 1, "OrphanFolder: Expected count \(1) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 0, 0, 1, "utils", .orphan, 0)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // utils <--> utils
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // utils <-> utils
            assertItem(child3, 0, 0, 0, 0, 0, "view", .orphan, 0)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
