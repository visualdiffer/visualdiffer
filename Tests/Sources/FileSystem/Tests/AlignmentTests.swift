//
//  AlignmentTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/07/13.
//  Copyright (c) 2013 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class AlignmentTests: CaseSensitiveBaseTest {
    @Test func leftMatchCaseRightIgnoreCase() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func leftMatchCaseRightIgnoreCase2() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func leftMatchCaseRightIgnoreCase3() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func bothIgnoreCase() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func onlyOneOnLeft() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func createLeftOrphans() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func folders() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func closestMatch() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func copyFolder() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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
            destBaseDir: appendFolder("r")
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

    @Test func regExpr() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func regNoMatchButIgnoreCaseMatch() throws {
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

        let rootL = folderReader.leftRoot!
        // let rootR = folderReader.rightRoot!
        let vi = rootL.visibleItem!

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

    @Test func bigFolderLeftIgnoreRightMatch() throws {
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
}

// swiftlint:enable file_length force_unwrapping function_body_length
