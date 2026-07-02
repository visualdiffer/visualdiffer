//
//  AlignmentTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/07/13.
//  Copyright (c) 2013 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length function_body_length
final class AlignmentTests: CaseSensitiveBaseTest {
    @Test
    func leftMatchCaseRightIgnoreCase() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .timestamp],
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

        // create files
        try createFile("l/1.txt", "")
        try createFile("l/d.TXT", "")
        try createFile("r/m.txt", "")
        try createFile("l/m.tXt", "")
        try createFile("r/m.tXt", "")
        try createFile("r/m.Txt", "")
        try createFile("l/m.TXT", "")
        try createFile("r/m.TXT", "")

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
            assertItem(child1, 0, 0, 2, 2, 6, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 2, 6, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 0, 1, 0, "m.tXt", .same, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "m.Txt", .orphan, 0)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
        }

        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 6)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 2, 2, 6, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 2, 6, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 0, 1, 0, "m.tXt", .same, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "m.Txt", .orphan, 0)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
        }
    }

    @Test
    func leftMatchCaseRightIgnoreCase2() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: false
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("l/0.txt", "")
        try createFile("r/1.txt", "")
        try createFile("r/d.TXT", "")
        try createFile("l/m.txt", "")
        try createFile("l/m.tXt", "")
        try createFile("r/m.tXt", "")
        try createFile("l/m.Txt", "")
        try createFile("r/m.TXT", "")

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
            assertItem(child1, 0, 0, 2, 2, 6, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 2, 6, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "0.txt", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "m.tXt", .same, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 6)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 2, 2, 6, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 2, 6, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "0.txt", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "m.tXt", .same, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
        }
    }

    @Test
    func leftMatchCaseRightIgnoreCase3() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: false
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("r/1.txt", "")
        try createFile("r/d.TXT", "")
        try createFile("l/m.txt", "")
        try createFile("l/m.tXt", "")
        try createFile("l/m.Txt", "")
        try createFile("l/m.TXT", "")
        try createFile("r/m.TXT", "")
        try createFile("r/n.tXt", "")

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
            assertItem(child1, 0, 0, 3, 1, 7, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 3, 1, 7, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 1, 0, 0, "m.tXt", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 0, 1, 0, 0, "m.Txt", .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)

            let child8 = child1.children[6] // l <-> r
            assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "n.tXt", .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 7)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 3, 1, 7, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 3, 1, 7, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 1, 0, 0, "m.tXt", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 0, 1, 0, 0, "m.Txt", .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)

            let childVI8 = childVI1.children[6] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 1, 0, 0, "n.tXt", .orphan, 0)
        }
    }

    @Test
    func bothIgnoreCase() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("l/10.jpg", "")
        try createFile("r/10.Jpg", "")
        try createFile("l/20.jpg", "")
        try createFile("r/20.JPG", "")
        try createFile("l/debug.jpg", "")
        try createFile("l/Help.jpg", "")
        try createFile("r/help.jpg", "")
        try createFile("l/sea.txt", "")
        try createFile("r/sea.TXT", "")

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
            assertItem(child1, 0, 0, 1, 4, 5, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 4, 5, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 1, 0, "10.jpg", .same, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "10.Jpg", .same, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 1, 0, "20.jpg", .same, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "20.JPG", .same, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "debug.jpg", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 0, 1, 0, "Help.jpg", .same, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "help.jpg", .same, 0)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "sea.txt", .same, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "sea.TXT", .same, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 5)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 1, 4, 5, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 4, 5, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 1, 0, "10.jpg", .same, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "10.Jpg", .same, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 1, 0, "20.jpg", .same, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "20.JPG", .same, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "debug.jpg", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 0, 1, 0, "Help.jpg", .same, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "help.jpg", .same, 0)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "sea.txt", .same, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "sea.TXT", .same, 0)
        }
    }

    @Test
    func onlyOneOnLeft() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: true
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("r/m.txt", "")
        try createFile("l/m.txT", "")
        try createFile("r/m.tXt", "")
        try createFile("r/m.Txt", "")
        try createFile("r/m.TXT", "")

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
            assertItem(child1, 0, 0, 0, 1, 4, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 3, 1, 4, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 1, 0, "m.txT", .same, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "m.Txt", .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "m.TXT", .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 4)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 1, 4, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 3, 1, 4, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 1, 0, "m.txT", .same, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "m.Txt", .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "m.TXT", .orphan, 0)
        }
    }

    @Test
    func createLeftOrphans() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: true
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("l/1.txt", "")
        try createFile("l/d.TXT", "")
        try createFile("l/m.txt", "")
        try createFile("l/m.tXt", "")
        try createFile("l/m.Txt", "")
        try createFile("r/m.Txt", "")
        try createFile("l/m.TXT", "")

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
            assertItem(child1, 0, 0, 5, 1, 6, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 6, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 1, 0, 0, "m.tXt", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "m.Txt", .same, 0)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 1, 0, 0, "m.TXT", .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 6)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 5, 1, 6, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 0, 1, 6, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 1, 0, 0, "m.tXt", .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "m.Txt", .same, 0)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 1, 0, 0, "m.TXT", .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
        }
    }

    @Test
    func folders() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: true
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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
        try createFolder("l/m.TxT")
        try createFolder("r/m.TxT")
        try createFolder("l/M.TxT")
        try createFolder("r/M.TxT")

        // create files
        try createFile("l/m.TxT/hello.txt", "")
        try setFileTimestamp("l/m.TxT/hello.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/m.TxT/hello.txt", "1")
        try createFile("r/m.TxT/Hello.txt", "12")
        try createFile("l/M.TxT/hello.txt", "")
        try createFile("l/M.TxT/Hello.txt", "123")
        try setFileTimestamp("l/M.TxT/Hello.txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/M.TxT/Hello.txt", "1234")
        try createFile("l/0.txt", "")
        try createFile("r/1.txt", "")
        try createFile("r/d.TXT", "")
        try createFile("l/m.txt", "")
        try createFile("l/m.tXt", "")
        try createFile("r/m.tXt", "")
        try createFile("l/m.Txt", "")
        try createFile("r/m.TXT", "")

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
            assertItem(child1, 2, 0, 3, 2, 8, "l", .orphan, 3)
            assertItem(child1.linkedItem, 0, 2, 3, 2, 8, "r", .orphan, 7)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 1, 0, 0, 0, 2, "m.TxT", .orphan, 0)
            assertItem(child2.linkedItem, 0, 1, 1, 0, 2, "m.TxT", .orphan, 3)

            let child3 = child2.children[0] // m.TxT <-> m.TxT
            assertItem(child3, 1, 0, 0, 0, 0, "hello.txt", .old, 0)
            assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "hello.txt", .changed, 1)

            let child4 = child2.children[1] // m.TxT <-> m.TxT
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "Hello.txt", .orphan, 2)

            let child5 = child1.children[1] // l <-> r
            assertItem(child5, 1, 0, 1, 0, 2, "M.TxT", .orphan, 3)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 2, "M.TxT", .orphan, 4)

            let child6 = child5.children[0] // M.TxT <-> M.TxT
            assertItem(child6, 0, 0, 1, 0, 0, "hello.txt", .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child7 = child5.children[1] // M.TxT <-> M.TxT
            assertItem(child7, 1, 0, 0, 0, 0, "Hello.txt", .old, 3)
            assertItem(child7.linkedItem, 0, 1, 0, 0, 0, "Hello.txt", .changed, 4)

            let child8 = child1.children[2] // l <-> r
            assertItem(child8, 0, 0, 1, 0, 0, "0.txt", .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child9 = child1.children[3] // l <-> r
            assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let child10 = child1.children[4] // l <-> r
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let child11 = child1.children[5] // l <-> r
            assertItem(child11, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child12 = child1.children[6] // l <-> r
            assertItem(child12, 0, 0, 0, 1, 0, "m.tXt", .same, 0)
            assertItem(child12.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let child13 = child1.children[7] // l <-> r
            assertItem(child13, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child13.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 8)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 2, 0, 3, 2, 8, "l", .orphan, 3)
            assertItem(child1.linkedItem, 0, 2, 3, 2, 8, "r", .orphan, 7)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 1, 0, 0, 0, 2, "m.TxT", .orphan, 0)
            assertItem(child2.linkedItem, 0, 1, 1, 0, 2, "m.TxT", .orphan, 3)

            let childVI3 = childVI2.children[0] // m.TxT <--> m.TxT
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // m.TxT <-> m.TxT
            assertItem(child3, 1, 0, 0, 0, 0, "hello.txt", .old, 0)
            assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "hello.txt", .changed, 1)

            let childVI4 = childVI2.children[1] // m.TxT <--> m.TxT
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // m.TxT <-> m.TxT
            assertItem(child4, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child4.linkedItem, 0, 0, 1, 0, 0, "Hello.txt", .orphan, 2)

            let childVI5 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI5.children, 2)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 1, 0, 1, 0, 2, "M.TxT", .orphan, 3)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 2, "M.TxT", .orphan, 4)

            let childVI6 = childVI5.children[0] // M.TxT <--> M.TxT
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // M.TxT <-> M.TxT
            assertItem(child6, 0, 0, 1, 0, 0, "hello.txt", .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI7 = childVI5.children[1] // M.TxT <--> M.TxT
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // M.TxT <-> M.TxT
            assertItem(child7, 1, 0, 0, 0, 0, "Hello.txt", .old, 3)
            assertItem(child7.linkedItem, 0, 1, 0, 0, 0, "Hello.txt", .changed, 4)

            let childVI8 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 0, 1, 0, 0, "0.txt", .orphan, 0)
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI9 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // l <-> r
            assertItem(child9, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child9.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let childVI10 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI10.children, 0)
            let child10 = childVI10.item // l <-> r
            assertItem(child10, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child10.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let childVI11 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI11.children, 0)
            let child11 = childVI11.item // l <-> r
            assertItem(child11, 0, 0, 1, 0, 0, "m.txt", .orphan, 0)
            assertItem(child11.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI12 = childVI1.children[6] // l <--> r
            assertArrayCount(childVI12.children, 0)
            let child12 = childVI12.item // l <-> r
            assertItem(child12, 0, 0, 0, 1, 0, "m.tXt", .same, 0)
            assertItem(child12.linkedItem, 0, 0, 0, 1, 0, "m.tXt", .same, 0)

            let childVI13 = childVI1.children[7] // l <--> r
            assertArrayCount(childVI13.children, 0)
            let child13 = childVI13.item // l <-> r
            assertItem(child13, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child13.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 0)
        }
    }

    @Test
    func closestMatch() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: true
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("r/1.txt", "")
        try createFile("r/d.TXT", "")
        try createFile("l/m.Txt", "")
        try createFile("r/m.txt", "")

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
            assertItem(child1, 0, 0, 0, 1, 3, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 1, 3, "r", .orphan, 0)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "m.txt", .same, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 1, 3, "l", .orphan, 0)
            assertItem(child1.linkedItem, 0, 0, 2, 1, 3, "r", .orphan, 0)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child2.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "d.TXT", .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 0, 1, 0, "m.Txt", .same, 0)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "m.txt", .same, 0)
        }
    }

    @Test
    func copyFolder() throws {
        try assertVolumeMounted()

        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: true
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("l/0.txt", "12")
        try createFile("r/1.txt", "")
        try createFile("l/m.txt", "123")
        try createFile("l/m.tXt", "")
        try setFileTimestamp("l/m.tXt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/m.tXt", "1234")
        try createFile("l/m.Txt", "12345678901234")
        try setFileTimestamp("l/m.Txt", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/m.TXT", "12345")
        try createFile("r/next.txt", "")

        let copyRoot: CompareItem

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
            assertItem(child1, 2, 0, 2, 0, 6, "l", .orphan, 19)
            assertItem(child1.linkedItem, 0, 2, 2, 0, 6, "r", .orphan, 9)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "0.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 3)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 1, 0, 0, 0, 0, "m.tXt", .old, 0)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "m.tXt", .changed, 4)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 1, 0, 0, 0, 0, "m.Txt", .old, 14)
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "m.TXT", .changed, 5)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "next.txt", .orphan, 0)

            copyRoot = child6
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 6)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 2, 0, 2, 0, 6, "l", .orphan, 19)
            assertItem(child1.linkedItem, 0, 2, 2, 0, 6, "r", .orphan, 9)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "0.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 3)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 1, 0, 0, 0, 0, "m.tXt", .old, 0)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "m.tXt", .changed, 4)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 1, 0, 0, 0, 0, "m.Txt", .old, 14)
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "m.TXT", .changed, 5)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "next.txt", .orphan, 0)
        }

        let fileOperaionDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperaionDelegate
        )
        let copyCompareItem = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        copyCompareItem.copy(
            srcRoot: copyRoot,
            srcBaseDir: appendFolder("l"),
            destination: .linkedSide(baseDir: appendFolder("r"))
        )
        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 1, 0, 2, 1, 6, "l", .orphan, 19)
            assertItem(child1.linkedItem, 0, 1, 2, 1, 6, "r", .orphan, 18)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "0.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 3)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 1, 0, 0, 0, 0, "m.tXt", .old, 0)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "m.tXt", .changed, 4)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "m.Txt", .same, 14)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 14)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "next.txt", .orphan, 0)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 6)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 1, 0, 2, 1, 6, "l", .orphan, 19)
            assertItem(child1.linkedItem, 0, 1, 2, 1, 6, "r", .orphan, 18)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 1, 0, 0, "0.txt", .orphan, 2)
            assertItem(child2.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child3.linkedItem, 0, 0, 1, 0, 0, "1.txt", .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 0, 1, 0, 0, "m.txt", .orphan, 3)
            assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 1, 0, 0, 0, 0, "m.tXt", .old, 0)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "m.tXt", .changed, 4)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 0, 0, 1, 0, "m.Txt", .same, 14)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "m.TXT", .same, 14)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "next.txt", .orphan, 0)
        }
    }

    @Test
    func regExpr() throws {
        try assertVolumeMounted()

        // align both .raw and .png to .jpg
        let fileNameAlignments: [AlignRule] = [
            AlignRule(
                regExp: AlignRegExp(pattern: "(.*)\\.", options: []),
                template: AlignTemplate(pattern: "$1", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.size, .contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("l/001.jpg", "1")
        try setFileTimestamp("l/001.jpg", "2001-03-24 10: 45: 32 +0600")
        try createFile("r/001.raw", "12")
        try createFile("l/002.jpg", "123")
        try createFile("l/003.jpg", "12345")
        try createFile("r/003.raw", "1234")
        try createFile("l/004.jpg", "1234567")
        try createFile("r/004.raw", "1234567")
        try createFile("l/005.jpg", "123456789")
        try createFile("r/005.raw", "12345678")
        try setFileTimestamp("r/005.raw", "2001-03-24 10: 45: 32 +0600")
        try createFile("l/006.jpg", "12345678901")
        try createFile("l/007.jpg", "1234567890123")
        try createFile("r/007.png", "1234")
        try setFileTimestamp("r/007.png", "2001-03-24 10: 45: 32 +0600")
        try createFile("l/008.jpg", "123456789012345")
        try createFile("r/008.raw", "1234567890")

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
            assertItem(child1, 1, 4, 2, 1, 8, "l", .orphan, 64)
            assertItem(child1.linkedItem, 2, 3, 0, 1, 8, "r", .orphan, 35)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 1, 0, 0, 0, 0, "001.jpg", .old, 1)
            assertItem(child2.linkedItem, 0, 1, 0, 0, 0, "001.raw", .changed, 2)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 1, 0, 0, "002.jpg", .orphan, 3)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 1, 0, 0, 0, "003.jpg", .changed, 5)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "003.raw", .changed, 4)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 0, 0, 1, 0, "004.jpg", .same, 7)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "004.raw", .same, 7)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 1, 0, 0, 0, "005.jpg", .changed, 9)
            assertItem(child6.linkedItem, 1, 0, 0, 0, 0, "005.raw", .old, 8)

            let child7 = child1.children[5] // l <-> r
            assertItem(child7, 0, 0, 1, 0, 0, "006.jpg", .orphan, 11)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child8 = child1.children[6] // l <-> r
            assertItem(child8, 0, 1, 0, 0, 0, "007.jpg", .changed, 13)
            assertItem(child8.linkedItem, 1, 0, 0, 0, 0, "007.png", .old, 4)

            let child9 = child1.children[7] // l <-> r
            assertItem(child9, 0, 1, 0, 0, 0, "008.jpg", .changed, 15)
            assertItem(child9.linkedItem, 0, 1, 0, 0, 0, "008.raw", .changed, 10)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 8)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 1, 4, 2, 1, 8, "l", .orphan, 64)
            assertItem(child1.linkedItem, 2, 3, 0, 1, 8, "r", .orphan, 35)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 1, 0, 0, 0, 0, "001.jpg", .old, 1)
            assertItem(child2.linkedItem, 0, 1, 0, 0, 0, "001.raw", .changed, 2)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 1, 0, 0, "002.jpg", .orphan, 3)
            assertItem(child3.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 1, 0, 0, 0, "003.jpg", .changed, 5)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "003.raw", .changed, 4)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 0, 0, 1, 0, "004.jpg", .same, 7)
            assertItem(child5.linkedItem, 0, 0, 0, 1, 0, "004.raw", .same, 7)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 1, 0, 0, 0, "005.jpg", .changed, 9)
            assertItem(child6.linkedItem, 1, 0, 0, 0, 0, "005.raw", .old, 8)

            let childVI7 = childVI1.children[5] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 1, 0, 0, "006.jpg", .orphan, 11)
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI1.children[6] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 1, 0, 0, 0, "007.jpg", .changed, 13)
            assertItem(child8.linkedItem, 1, 0, 0, 0, 0, "007.png", .old, 4)

            let childVI9 = childVI1.children[7] // l <--> r
            assertArrayCount(childVI9.children, 0)
            let child9 = childVI9.item // l <-> r
            assertItem(child9, 0, 1, 0, 0, 0, "008.jpg", .changed, 15)
            assertItem(child9.linkedItem, 0, 1, 0, 0, 0, "008.raw", .changed, 10)
        }
    }

    @Test
    func regularExpressionAlignsCrossedRules() throws {
        try assertVolumeMounted()

        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: "a_left", options: []),
                template: AlignTemplate(pattern: "z_right", options: [])
            ),
            AlignRule(
                regExp: AlignRegExp(pattern: "b_left", options: []),
                template: AlignTemplate(pattern: "a_right", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/a_left")
        try createFile("l/a_left/file.txt", "a")
        try createFolder("l/b_left")
        try createFile("l/b_left/file.txt", "b")

        try createFolder("r/a_right")
        try createFile("r/a_right/file.txt", "a")
        try createFolder("r/z_right")
        try createFile("r/z_right/file.txt", "z")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let leftA = try #require(leftRoot.children.first { $0.fileName == "a_left" })
        let leftB = try #require(leftRoot.children.first { $0.fileName == "b_left" })

        #expect(leftA.linkedItem?.fileName == "z_right")
        #expect(leftB.linkedItem?.fileName == "a_right")

        let rightRoot = try #require(folderReader.rightRoot)
        let rightA = try #require(rightRoot.children.first { $0.fileName == "a_right" })
        let rightZ = try #require(rightRoot.children.first { $0.fileName == "z_right" })

        #expect(rightA.linkedItem?.fileName == "b_left")
        #expect(rightZ.linkedItem?.fileName == "a_left")
    }

    @Test
    func regularExpressionSkipsFileNameMatchReservedForLaterLeft() throws {
        try assertVolumeMounted()

        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: "n_later", options: []),
                template: AlignTemplate(pattern: "m_current", options: [])
            ),
            AlignRule(
                regExp: AlignRegExp(pattern: "z_later", options: []),
                template: AlignTemplate(pattern: "a_reserved", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/m_current")
        try createFile("l/m_current/file.txt", "m")
        try createFolder("l/n_later")
        try createFile("l/n_later/file.txt", "n")
        try createFolder("l/z_later")
        try createFile("l/z_later/file.txt", "z")

        try createFolder("r/a_reserved")
        try createFile("r/a_reserved/file.txt", "a")
        try createFolder("r/m_current")
        try createFile("r/m_current/file.txt", "m")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let leftCurrent = try #require(leftRoot.children.first { $0.fileName == "m_current" })
        let leftNameRule = try #require(leftRoot.children.first { $0.fileName == "n_later" })
        let leftReserved = try #require(leftRoot.children.first { $0.fileName == "z_later" })

        #expect(leftCurrent.linkedItem?.path == nil)
        #expect(leftNameRule.linkedItem?.fileName == "m_current")
        #expect(leftReserved.linkedItem?.fileName == "a_reserved")

        let rightRoot = try #require(folderReader.rightRoot)
        let rightNameRule = try #require(rightRoot.children.first { $0.fileName == "m_current" })
        let rightReserved = try #require(rightRoot.children.first { $0.fileName == "a_reserved" })

        #expect(rightNameRule.linkedItem?.fileName == "n_later")
        #expect(rightReserved.linkedItem?.fileName == "z_later")
    }

    @Test
    func regularExpressionUsesClosestRightMatchAcrossRules() throws {
        try assertVolumeMounted()

        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: "m_left", options: []),
                template: AlignTemplate(pattern: "z_far", options: [])
            ),
            AlignRule(
                regExp: AlignRegExp(pattern: "m_left", options: []),
                template: AlignTemplate(pattern: "b_near", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/m_left")
        try createFile("l/m_left/file.txt", "m")

        try createFolder("r/a_orphan")
        try createFile("r/a_orphan/file.txt", "a")
        try createFolder("r/b_near")
        try createFile("r/b_near/file.txt", "b")
        try createFolder("r/z_far")
        try createFile("r/z_far/file.txt", "z")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let leftItem = try #require(leftRoot.children.first { $0.fileName == "m_left" })

        #expect(leftItem.linkedItem?.fileName == "b_near")

        let rightRoot = try #require(folderReader.rightRoot)
        let rightOrphan = try #require(rightRoot.children.first { $0.fileName == "a_orphan" })
        let rightNear = try #require(rightRoot.children.first { $0.fileName == "b_near" })
        let rightFar = try #require(rightRoot.children.first { $0.fileName == "z_far" })

        #expect(rightOrphan.linkedItem?.path == nil)
        #expect(rightNear.linkedItem?.fileName == "m_left")
        #expect(rightFar.linkedItem?.path == nil)
    }

    @Test
    func regularExpressionAlignsLaterRightDirectory() throws {
        try assertVolumeMounted()

        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: ".template-docker", options: []),
                template: AlignTemplate(pattern: "docker", options: [])
            ),
            AlignRule(
                regExp: AlignRegExp(pattern: "img_bad", options: []),
                template: AlignTemplate(pattern: "a_img_good", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFile("l/file1.txt", "123456")
        try createFolder("l/img_bad")
        try createFile("l/img_bad/img01.txt", "123456")
        try createFile("l/img_bad/img02.txt", "123456")
        try createFolder("l/.template-docker/docker")
        try createFile("l/.template-docker/docker/file1.txt", "1234")

        try createFile("r/file1.txt", "1236")
        try createFolder("r/a_img_good")
        try createFile("r/a_img_good/img01.txt", "1234")
        try createFile("r/a_img_good/img02.txt", "12346")
        try createFolder("r/docker")
        try createFile("r/docker/file2.txt", "12346")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let templateItem = try #require(leftRoot.children.first { $0.fileName == ".template-docker" })
        let imageItem = try #require(leftRoot.children.first { $0.fileName == "img_bad" })
        let fileItem = try #require(leftRoot.children.first { $0.fileName == "file1.txt" })

        #expect(templateItem.linkedItem?.fileName == "docker")
        #expect(imageItem.linkedItem?.fileName == "a_img_good")
        #expect(fileItem.linkedItem?.fileName == "file1.txt")

        let rightRoot = try #require(folderReader.rightRoot)
        let goodImageItem = try #require(rightRoot.children.first { $0.fileName == "a_img_good" })
        let dockerItem = try #require(rightRoot.children.first { $0.fileName == "docker" })

        #expect(goodImageItem.linkedItem?.fileName == "img_bad")
        #expect(dockerItem.linkedItem?.fileName == ".template-docker")
    }

    @Test
    func regularExpressionYieldsRuleMatchToLaterExactFileName() throws {
        try assertVolumeMounted()

        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: "a_dup", options: []),
                template: AlignTemplate(pattern: "m_target", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/a_dup")
        try createFile("l/a_dup/file.txt", "a")
        try createFolder("l/m_target")
        try createFile("l/m_target/file.txt", "m")

        try createFolder("r/a_other")
        try createFile("r/a_other/file.txt", "o")
        try createFolder("r/m_target")
        try createFile("r/m_target/file.txt", "m")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let leftDup = try #require(leftRoot.children.first { $0.fileName == "a_dup" })
        let leftTarget = try #require(leftRoot.children.first { $0.fileName == "m_target" })

        // the exact file-name match wins over the rule-derived prefix match
        #expect(leftTarget.linkedItem?.fileName == "m_target")
        #expect(leftDup.linkedItem?.path == nil)

        let rightRoot = try #require(folderReader.rightRoot)
        let rightTarget = try #require(rightRoot.children.first { $0.fileName == "m_target" })
        let rightOther = try #require(rightRoot.children.first { $0.fileName == "a_other" })

        #expect(rightTarget.linkedItem?.fileName == "m_target")
        #expect(rightOther.linkedItem?.path == nil)
    }

    @Test
    func regNoMatchButIgnoreCaseMatch() throws {
        try assertVolumeMounted()

        // No file matches this rule but they must be aligned by case
        let fileNameAlignments: [AlignRule] = [
            AlignRule(
                regExp: AlignRegExp(pattern: "(.*)\\.jpg", options: []),
                template: AlignTemplate(pattern: "$1.raw", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.alignIgnoreCase, .contentTimestamp, .size],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        // create files
        try createFile("l/New York.jpg", "123")
        try createFile("r/New York.jpg", "123")
        try createFile("l/SanDiego.jpg", "1")
        try createFile("r/sandiego.jpg", "1")

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
            assertItem(child1, 0, 0, 0, 2, 2, "l", .orphan, 4)
            assertItem(child1.linkedItem, 0, 0, 0, 2, 2, "r", .orphan, 4)

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 1, 0, "New York.jpg", .same, 3)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "New York.jpg", .same, 3)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 0, 0, 1, 0, "SanDiego.jpg", .same, 1)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "sandiego.jpg", .same, 1)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 2)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 2, 2, "l", .orphan, 4)
            assertItem(child1.linkedItem, 0, 0, 0, 2, 2, "r", .orphan, 4)

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 1, 0, "New York.jpg", .same, 3)
            assertItem(child2.linkedItem, 0, 0, 0, 1, 0, "New York.jpg", .same, 3)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 0, 0, 1, 0, "SanDiego.jpg", .same, 1)
            assertItem(child3.linkedItem, 0, 0, 0, 1, 0, "sandiego.jpg", .same, 1)
        }
    }

    @Test
    func bigFolderLeftIgnoreRightMatch() throws {
        try removeItem("l")
        try removeItem("r")

        // create folders
        try createFolder("l")
        try createFolder("r")

        srandom(1000)
        for _ in 0 ..< 10 {
            let len = Int.random(in: 0 ..< 34) + 6
            var str = String(repeating: " ", count: Int(len))
            for l in 0 ..< len {
                let index = str.index(str.startIndex, offsetBy: l)
                str.replaceSubrange(index ... index, with: String(generateAsciiChar()))
            }
            for _ in 0 ..< 10 {
                let index = Int.random(in: 0 ..< len)
                invertCase(&str, index: index)
                let direction = Bool.random() ? "l" : "r"
                let path = "\(direction)/\(str).txt"

                try createFile(path, "12")
            }
        }
    }

    @Test
    func alignFilenameWithUnicode() throws {
        let fileNameAlignments: [AlignRule] = [
            AlignRule(
                regExp: AlignRegExp(pattern: "(.*)\\.txt", options: []),
                template: AlignTemplate(pattern: "$1.doc", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.timestamp, .size, .content, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
            followSymLinks: false,
            skipPackages: true,
            traverseFilteredFolders: true,
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

        // create files
        try createFile("l/a.txt", "l-a")
        try createFile("r/a.doc", "r-a")
        try createFile("l/b.txt", "l-b")
        try createFile("r/b.doc", "r-b")
        try createFile("l/c.txt", "l-c")
        try createFile("r/c.doc", "r-c")
        try createFile("l/photo𝄞_thumb.txt", "l-astral-plane-chr")
        try createFile("r/photo𝄞_thumb.doc", "r-astral-plane-chr")
        try createFile("l/photo𝄞.txt", "l-astral-plane-chr")
        try createFile("r/photo𝄞.doc", "r-astral-plane-chr")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        let vi = try #require(rootL.visibleItem)

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 5, 0, 0, 5, "l", .orphan, 45)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 5, 0, 0, 5, "r", .orphan, 45)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.linkedItem?.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 1, 0, 0, 0, "a.txt", .changed, 3)
            assertItem(child2.linkedItem, 0, 1, 0, 0, 0, "a.doc", .changed, 3)

            let child3 = child1.children[1] // l <-> r
            assertItem(child3, 0, 1, 0, 0, 0, "b.txt", .changed, 3)
            assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "b.doc", .changed, 3)

            let child4 = child1.children[2] // l <-> r
            assertItem(child4, 0, 1, 0, 0, 0, "c.txt", .changed, 3)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "c.doc", .changed, 3)

            let child5 = child1.children[3] // l <-> r
            assertItem(child5, 0, 1, 0, 0, 0, "photo𝄞_thumb.txt", .changed, 18)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "photo𝄞_thumb.doc", .changed, 18)

            let child6 = child1.children[4] // l <-> r
            assertItem(child6, 0, 1, 0, 0, 0, "photo𝄞.txt", .changed, 18)
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "photo𝄞.doc", .changed, 18)
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 5)
            let child1 = childVI1.item // nil <-> nil
            assertItem(child1, 0, 5, 0, 0, 5, "l", .orphan, 45)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 5, 0, 0, 5, "r", .orphan, 45)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.linkedItem?.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 0)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 1, 0, 0, 0, "a.txt", .changed, 3)
            assertItem(child2.linkedItem, 0, 1, 0, 0, 0, "a.doc", .changed, 3)

            let childVI3 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI3.children, 0)
            let child3 = childVI3.item // l <-> r
            assertItem(child3, 0, 1, 0, 0, 0, "b.txt", .changed, 3)
            assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "b.doc", .changed, 3)

            let childVI4 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // l <-> r
            assertItem(child4, 0, 1, 0, 0, 0, "c.txt", .changed, 3)
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "c.doc", .changed, 3)

            let childVI5 = childVI1.children[3] // l <--> r
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // l <-> r
            assertItem(child5, 0, 1, 0, 0, 0, "photo𝄞_thumb.txt", .changed, 18)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "photo𝄞_thumb.doc", .changed, 18)

            let childVI6 = childVI1.children[4] // l <--> r
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // l <-> r
            assertItem(child6, 0, 1, 0, 0, 0, "photo𝄞.txt", .changed, 18)
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "photo𝄞.doc", .changed, 18)
        }
    }

    @Test
    func regularExpressionAdjacentRuleYieldsToExactFileName() throws {
        try assertVolumeMounted()

        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: "a_dup", options: []),
                template: AlignTemplate(pattern: "m_target", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: true,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        try createFolder("l/a_dup")
        try createFile("l/a_dup/file.txt", "a")
        try createFolder("l/m_target")
        try createFile("l/m_target/file.txt", "m")

        // no right item sorts before m_target, so a_dup meets m_target at the
        // current position and must still yield it to the exact-name left
        try createFolder("r/m_target")
        try createFile("r/m_target/file.txt", "m")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let leftDup = try #require(leftRoot.children.first { $0.fileName == "a_dup" })
        let leftTarget = try #require(leftRoot.children.first { $0.fileName == "m_target" })

        let rightRoot = try #require(folderReader.rightRoot)
        let rightTarget = try #require(rightRoot.children.first { $0.fileName == "m_target" })

        // the exact file-name match wins even when the rule match is adjacent
        #expect(leftTarget.linkedItem === rightTarget)
        #expect(rightTarget.linkedItem === leftTarget)
        #expect(leftDup.linkedItem?.path == nil)
    }

    @Test
    func emptyTemplateProducesNoRuleMatch() {
        // a template expanding to nothing (e.g. a backreference to a missing
        // capture group) must not prefix-match every right name
        let emptyRule = AlignRule(
            regExp: AlignRegExp(pattern: "a_dup", options: []),
            template: AlignTemplate(pattern: "$1", options: [])
        )
        #expect(emptyRule.match(leftName: "a_dup") == nil)

        let validRule = AlignRule(
            regExp: AlignRegExp(pattern: "a_dup", options: []),
            template: AlignTemplate(pattern: "m_target", options: [])
        )
        #expect(validRule.match(leftName: "a_dup")?.replacedName == "m_target")
    }

    @Test
    func regularExpressionMixedCasePrefersExactSibling() throws {
        try assertVolumeMounted()

        // a rule that does not match any of the items below
        let fileNameAlignments = [
            AlignRule(
                regExp: AlignRegExp(pattern: "no_match", options: []),
                template: AlignTemplate(pattern: "no_match", options: [])
            ),
        ]
        let comparatorDelegate = MockItemComparatorDelegate()
        // mixed case sensitivity: left case-sensitive, right case-insensitive
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignFileSystemCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: true,
            isRightCaseSensitive: false,
            fileNameAlignments: fileNameAlignments
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: true,
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

        try createFolder("l")
        try createFolder("r")

        // the case-sensitive left keeps both siblings, the right has only the
        // exact-case one; the case-variant left must stay an orphan
        try createFile("l/foo.txt", "a")
        try createFile("l/Foo.txt", "b")
        try createFile("r/Foo.txt", "b")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let leftRoot = try #require(folderReader.leftRoot)
        let leftLower = try #require(leftRoot.children.first { $0.fileName == "foo.txt" })
        let leftExact = try #require(leftRoot.children.first { $0.fileName == "Foo.txt" })

        let rightRoot = try #require(folderReader.rightRoot)
        let rightExact = try #require(rightRoot.children.first { $0.fileName == "Foo.txt" })

        // the exact-case sibling matches; the case-variant left stays an orphan
        #expect(leftExact.linkedItem === rightExact)
        #expect(rightExact.linkedItem === leftExact)
        #expect(leftLower.linkedItem?.path == nil)
    }
}

// swiftlint:enable file_length function_body_length
