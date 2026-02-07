//
//  DisplayTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping function_body_length
final class DisplayTests: BaseTests {
    @Test("Bug 0000170: Display filter set to 'No Orphan' hides not matching files") func displayFilterNoOrphan() throws {
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
            let child1 = rootL.children[0] // l <-> r
            assertItem(child1, 1, 0, 1, 2, 1, "dir050", .orphan, 16)
            assertItem(child1.linkedItem, 0, 1, 1, 2, 1, "dir050", .orphan, 9)

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
        }
        do {
            // VisibleItems
            let childVI1 = vi.children[0] // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // l <-> r
            assertItem(child1, 1, 0, 1, 2, 1, "dir050", .orphan, 16)
            assertItem(child1.linkedItem, 0, 1, 1, 2, 1, "dir050", .orphan, 9)

            let childVI2 = childVI1.children[0] // dir050 <--> dir050
            assertArrayCount(childVI2.children, 1)
            let child2 = childVI2.item // dir050 <-> dir050
            assertItem(child2, 1, 0, 1, 2, 3, "dir100", .orphan, 16)
            assertItem(child2.linkedItem, 0, 1, 1, 2, 3, "dir100", .orphan, 9)

            let childVI3 = childVI2.children[0] // dir100 <--> dir100
            assertArrayCount(childVI3.children, 3)
            let child3 = childVI3.item // dir100 <-> dir100
            assertItem(child3, 1, 0, 0, 2, 3, "dir120", .orphan, 10)
            assertItem(child3.linkedItem, 0, 1, 0, 2, 3, "dir120", .orphan, 7)

            let childVI4 = childVI3.children[0] // dir120 <--> dir120
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // dir120 <-> dir120
            assertItem(child4, 0, 0, 0, 1, 0, "file101.txt", .same, 2)
            assertItem(child4.linkedItem, 0, 0, 0, 1, 0, "file101.txt", .same, 2)

            let childVI5 = childVI3.children[1] // dir120 <--> dir120
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // dir120 <-> dir120
            assertItem(child5, 1, 0, 0, 0, 0, "file102.txt", .old, 6)
            assertItem(child5.linkedItem, 0, 1, 0, 0, 0, "file102.txt", .changed, 3)

            let childVI6 = childVI3.children[2] // dir120 <--> dir120
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // dir120 <-> dir120
            assertItem(child6, 0, 0, 0, 1, 0, "file103.txt", .same, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file103.txt", .same, 2)
        }
    }

    @Test func displayNoOrphanShowEmptyFolders() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp, .size, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
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
        try createFolder("l")
        try createFolder("r")
        try createFolder("l/folder_1")
        try createFolder("r/folder_1")
        try createFolder("l/folder_1/folder_1_1")
        try createFolder("r/folder_1/folder_1_1")
        try createFolder("l/folder_1/folder_1_1/folder_2_1")
        try createFolder("r/folder_1/folder_1_1/folder_2_1")
        try createFolder("l/folder_1/folder_1_2")
        try createFolder("r/folder_1/folder_1_2")

        // create files
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_changed.m", "1234")
        try createFile("l/folder_1/folder_1_1/folder_2_1/file_matched.txt", "12")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_matched.txt", "12")
        try createFile("r/folder_1/folder_1_1/folder_2_1/file_older.txt", "1")
        try createFile("l/folder_1/folder_1_2/match_2_1.m", "1234")
        try createFile("r/folder_1/folder_1_2/match_2_1.m", "1234")
        try createFile("l/folder_1/file.txt", "1")
        try createFile("r/folder_1/file.txt", "1")
        try createFile("r/folder_1/right_orphan.txt", "1234567")

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
            assertItem(child1, 0, 0, 0, 3, 1, "l", .orphan, 7)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 3, 3, 1, "r", .orphan, 19)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 0, 0, 3, 4, "folder_1", .orphan, 7)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 3, 3, 4, "folder_1", .orphan, 19)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let child3 = child2.children[0] // folder_1 <-> folder_1
            assertItem(child3, 0, 0, 0, 1, 1, "folder_1_1", .orphan, 2)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 2, 1, 1, "folder_1_1", .orphan, 7)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let child4 = child3.children[0] // folder_1_1 <-> folder_1_1
            assertItem(child4, 0, 0, 0, 1, 3, "folder_2_1", .orphan, 2)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 2, 1, 3, "folder_2_1", .orphan, 7)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let child5 = child4.children[0] // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 4)

            let child6 = child4.children[1] // folder_2_1 <-> folder_2_1
            assertItem(child6, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)
            assertItem(child6.linkedItem, 0, 0, 0, 1, 0, "file_matched.txt", .same, 2)

            let child7 = child4.children[2] // folder_2_1 <-> folder_2_1
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 1)

            let child8 = child2.children[1] // folder_1 <-> folder_1
            assertItem(child8, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 4)
            #expect(child8.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.orphanFolders)")
            assertItem(child8.linkedItem, 0, 0, 0, 1, 1, "folder_1_2", .orphan, 4)
            #expect(child8.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child8.linkedItem!.orphanFolders)")

            let child9 = child8.children[0] // folder_1_2 <-> folder_1_2
            assertItem(child9, 0, 0, 0, 1, 0, "match_2_1.m", .same, 4)
            assertItem(child9.linkedItem, 0, 0, 0, 1, 0, "match_2_1.m", .same, 4)

            let child10 = child2.children[2] // folder_1 <-> folder_1
            assertItem(child10, 0, 0, 0, 1, 0, "file.txt", .same, 1)
            assertItem(child10.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, 1)

            let child11 = child2.children[3] // folder_1 <-> folder_1
            assertItem(child11, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child11.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        }

        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 1)
            let child1 = childVI1.item // (null) <-> (null)
            assertItem(child1, 0, 0, 0, 3, 1, "l", .orphan, 7)
            #expect(child1.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.orphanFolders)")
            assertItem(child1.linkedItem, 0, 0, 3, 3, 1, "r", .orphan, 19)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child1.linkedItem!.orphanFolders)")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 2)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 0, 0, 3, 4, "folder_1", .orphan, 7)
            #expect(child2.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.orphanFolders)")
            assertItem(child2.linkedItem, 0, 0, 3, 3, 4, "folder_1", .orphan, 19)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child2.linkedItem!.orphanFolders)")

            let childVI3 = childVI2.children[0] // folder_1 <--> folder_1
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // folder_1 <-> folder_1
            assertItem(child3, 0, 0, 0, 1, 1, "folder_1_1", .orphan, 2)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.orphanFolders)")
            assertItem(child3.linkedItem, 0, 0, 2, 1, 1, "folder_1_1", .orphan, 7)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child3.linkedItem!.orphanFolders)")

            let childVI4 = childVI3.children[0] // folder_1_1 <--> folder_1_1
            assertArrayCount(childVI4.children, 2)
            let child4 = childVI4.item // folder_1_1 <-> folder_1_1
            assertItem(child4, 0, 0, 0, 1, 3, "folder_2_1", .orphan, 2)
            #expect(child4.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.orphanFolders)")
            assertItem(child4.linkedItem, 0, 0, 2, 1, 3, "folder_2_1", .orphan, 7)
            #expect(child4.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count \(0) found \(child4.linkedItem!.orphanFolders)")

            let childVI5 = childVI4.children[0] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // folder_2_1 <-> folder_2_1
            assertItem(child5, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child5.linkedItem, 0, 0, 1, 0, 0, "file_changed.m", .orphan, 4)

            let childVI6 = childVI4.children[1] // folder_2_1 <--> folder_2_1
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // folder_2_1 <-> folder_2_1
            assertItem(child6, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child6.linkedItem, 0, 0, 1, 0, 0, "file_older.txt", .orphan, 1)

            let childVI7 = childVI2.children[1] // folder_1 <--> folder_1
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // folder_1 <-> folder_1
            assertItem(child7, 0, 0, 0, 0, 0, nil, .orphan, 0)
            assertItem(child7.linkedItem, 0, 0, 1, 0, 0, "right_orphan.txt", .orphan, 7)
        }
    }
}

// swiftlint:enable force_unwrapping function_body_length
