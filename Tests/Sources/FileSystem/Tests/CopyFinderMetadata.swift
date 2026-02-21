//
//  CopyFinderMetadata.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/02/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable file_length force_unwrapping function_body_length
final class CopyFinderMetadata: BaseTests {
    @Test
    func copyWithComparatorTags() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.timestamp, .size, .content, .finderTags, .alignMatchCase],
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: false,
            isRightCaseSensitive: false
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
        try createFolder("l/dir")
        try createFolder("r/dir")
        try createFolder("l/dir/deeper")
        try createFolder("r/dir/deeper")
        try createFolder("l/dir/other")

        // create files
        try add(tags: ["Red"], fullPath: appendFolder("l"))
        try add(tags: ["Green"], fullPath: appendFolder("l/dir"))
        try add(tags: ["Green"], fullPath: appendFolder("l/dir/deeper"))
        try createFile("l/dir/deeper/file5.txt", "12345678901234")
        try createFile("r/dir/deeper/file5.txt", "123456789012345")
        try createFile("l/dir/file3.txt", "12345678901234")
        try add(tags: ["Purple"], fullPath: appendFolder("l/dir/file3.txt"))
        try createFile("l/dir/file4.txt", "12345678901234")
        try add(tags: ["Purple"], fullPath: appendFolder("l/dir/file4.txt"))
        try createFile("r/dir/file4.txt", "123456789012345")
        try add(tags: ["Blue"], fullPath: appendFolder("r/dir/file4.txt"))
        try createFile("l/file1.txt", "12345678901234")
        try add(tags: ["Work", "Urgent", "Red"], fullPath: appendFolder("l/file1.txt"))
        try createFile("l/file2.txt", "12345678901234")
        try add(tags: ["Yellow", "Purple"], fullPath: appendFolder("l/file2.txt"))
        try createFile("r/file2.txt", "123456789012345")
        try setFileTimestamp("r/file2.txt", "2001-03-24 10:45:32 +0600")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        let rootR = try #require(folderReader.rightRoot)
        let vi = try #require(rootL.visibleItem)

        let child1 = rootL // l <-> r
        assertItem(child1, 0, 3, 2, 0, 3, "l", .orphan, 70)
        #expect(child1.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child1.orphanFolders)")
        assertFolderTags(child1, false, "l")
        assertMismatchingTags(child1, 4, "l")
        assertItem(child1.linkedItem, 1, 2, 0, 0, 3, "r", .orphan, 45)
        #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.linkedItem!.orphanFolders)")
        assertFolderTags(child1.linkedItem, false, "r")
        assertMismatchingTags(child1.linkedItem, 4, "r")

        let child2 = child1.children[0] // l <-> r
        assertItem(child2, 0, 2, 1, 0, 4, "dir", .mismatchingTags, 42)
        #expect(child2.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child2.orphanFolders)")
        assertFolderTags(child2, true, "dir")
        assertMismatchingTags(child2, 2, "dir")
        assertItem(child2.linkedItem, 0, 2, 0, 0, 4, "dir", .mismatchingTags, 30)
        #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child2.linkedItem!.orphanFolders)")
        assertFolderTags(child2.linkedItem, true, "dir")
        assertMismatchingTags(child2.linkedItem, 2, "dir")

        let child3 = child2.children[0] // dir <-> dir
        assertItem(child3, 0, 1, 0, 0, 1, "deeper", .mismatchingTags, 14)
        #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.orphanFolders)")
        assertFolderTags(child3, true, "deeper")
        assertMismatchingTags(child3, 0, "deeper")
        assertItem(child3.linkedItem, 0, 1, 0, 0, 1, "deeper", .mismatchingTags, 15)
        #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.linkedItem!.orphanFolders)")
        assertFolderTags(child3.linkedItem, true, "deeper")
        assertMismatchingTags(child3.linkedItem, 0, "deeper")

        let child4 = child3.children[0] // deeper <-> deeper
        assertItem(child4, 0, 1, 0, 0, 0, "file5.txt", .changed, 14)
        assertFolderTags(child4, false, "file5.txt")
        assertMismatchingTags(child4, 0, "file5.txt")
        assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "file5.txt", .changed, 15)
        assertFolderTags(child4.linkedItem, false, "file5.txt")
        assertMismatchingTags(child4.linkedItem, 0, "file5.txt")

        let child5 = child2.children[1] // dir <-> dir
        assertItem(child5, 0, 0, 0, 0, 0, "other", .orphan, 0)
        #expect(child5.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child5.orphanFolders)")
        assertFolderTags(child5, false, "other")
        assertMismatchingTags(child5, 0, "other")
        assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child6 = child2.children[2] // dir <-> dir
        assertItem(child6, 0, 0, 1, 0, 0, "file3.txt", .orphan, 14)
        assertFolderTags(child6, false, "file3.txt")
        assertMismatchingTags(child6, 0, "file3.txt")
        assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child7 = child2.children[3] // dir <-> dir
        assertItem(child7, 0, 1, 0, 0, 0, "file4.txt", .changed, 14)
        assertFolderTags(child7, false, "file4.txt")
        assertMismatchingTags(child7, 1, "file4.txt")
        assertItem(child7.linkedItem, 0, 1, 0, 0, 0, "file4.txt", .changed, 15)
        assertFolderTags(child7.linkedItem, false, "file4.txt")
        assertMismatchingTags(child7.linkedItem, 1, "file4.txt")

        let child8 = child1.children[1] // l <-> r
        assertItem(child8, 0, 0, 1, 0, 0, "file1.txt", .orphan, 14)
        assertFolderTags(child8, false, "file1.txt")
        assertMismatchingTags(child8, 0, "file1.txt")
        assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

        let child9 = child1.children[2] // l <-> r
        assertItem(child9, 0, 1, 0, 0, 0, "file2.txt", .changed, 14)
        assertFolderTags(child9, false, "file2.txt")
        assertMismatchingTags(child9, 1, "file2.txt")
        assertItem(child9.linkedItem, 1, 0, 0, 0, 0, "file2.txt", .old, 15)
        assertFolderTags(child9.linkedItem, false, "file2.txt")
        assertMismatchingTags(child9.linkedItem, 1, "file2.txt")

        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // nil <-> nil
            assertItem(child1, 0, 3, 2, 0, 3, "l", .orphan, 70)
            #expect(child1.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child1.orphanFolders)")
            assertFolderTags(child1, false, "l")
            assertMismatchingTags(child1, 4, "l")
            assertItem(child1.linkedItem, 1, 2, 0, 0, 3, "r", .orphan, 45)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1.linkedItem, false, "r")
            assertMismatchingTags(child1.linkedItem, 4, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 2, 1, 0, 4, "dir", .mismatchingTags, 42)
            #expect(child2.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child2.orphanFolders)")
            assertFolderTags(child2, true, "dir")
            assertMismatchingTags(child2, 2, "dir")
            assertItem(child2.linkedItem, 0, 2, 0, 0, 4, "dir", .mismatchingTags, 30)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2.linkedItem, true, "dir")
            assertMismatchingTags(child2.linkedItem, 2, "dir")

            let childVI3 = childVI2.children[0] // dir <--> dir
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // dir <-> dir
            assertItem(child3, 0, 1, 0, 0, 1, "deeper", .mismatchingTags, 14)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.orphanFolders)")
            assertFolderTags(child3, true, "deeper")
            assertMismatchingTags(child3, 0, "deeper")
            assertItem(child3.linkedItem, 0, 1, 0, 0, 1, "deeper", .mismatchingTags, 15)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3.linkedItem, true, "deeper")
            assertMismatchingTags(child3.linkedItem, 0, "deeper")

            let childVI4 = childVI3.children[0] // deeper <--> deeper
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // deeper <-> deeper
            assertItem(child4, 0, 1, 0, 0, 0, "file5.txt", .changed, 14)
            assertFolderTags(child4, false, "file5.txt")
            assertMismatchingTags(child4, 0, "file5.txt")
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "file5.txt", .changed, 15)
            assertFolderTags(child4.linkedItem, false, "file5.txt")
            assertMismatchingTags(child4.linkedItem, 0, "file5.txt")

            let childVI5 = childVI2.children[1] // dir <--> dir
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // dir <-> dir
            assertItem(child5, 0, 0, 1, 0, 0, "file3.txt", .orphan, 14)
            assertFolderTags(child5, false, "file3.txt")
            assertMismatchingTags(child5, 0, "file3.txt")
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI2.children[2] // dir <--> dir
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // dir <-> dir
            assertItem(child6, 0, 1, 0, 0, 0, "file4.txt", .changed, 14)
            assertFolderTags(child6, false, "file4.txt")
            assertMismatchingTags(child6, 1, "file4.txt")
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file4.txt", .changed, 15)
            assertFolderTags(child6.linkedItem, false, "file4.txt")
            assertMismatchingTags(child6.linkedItem, 1, "file4.txt")

            let childVI7 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 1, 0, 0, "file1.txt", .orphan, 14)
            assertFolderTags(child7, false, "file1.txt")
            assertMismatchingTags(child7, 0, "file1.txt")
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 1, 0, 0, 0, "file2.txt", .changed, 14)
            assertFolderTags(child8, false, "file2.txt")
            assertMismatchingTags(child8, 1, "file2.txt")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 0, "file2.txt", .old, 15)
            assertFolderTags(child8.linkedItem, false, "file2.txt")
            assertMismatchingTags(child8.linkedItem, 1, "file2.txt")
        }

        try assertOnlySetup()

        // VDLocalFileManager doesn't hold the delegate so allocate it as local variable
        // otherwise is released to early it the test crashes
        let fileOperationDelegate = MockFileOperationManagerDelegate()
        let fileOperationManager = FileOperationManager(
            filterConfig: filterConfig,
            comparator: comparator,
            delegate: fileOperationDelegate,
            includesFiltered: false,
            copyFinderMetadataOnly: true
        )
        let fileOperation = CopyCompareItem(
            operationManager: fileOperationManager,
            bigFileSizeThreshold: 100_000
        )

        fileOperation.copy(
            srcRoot: child2,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        do {
            let child1 = rootL // l <-> r
            assertItem(child1, 0, 3, 2, 0, 3, "l", .orphan, 70)
            #expect(child1.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child1.orphanFolders)")
            assertFolderTags(child1, false, "l")
            assertMismatchingTags(child1, 1, "l")
            assertItem(child1.linkedItem, 1, 2, 0, 0, 3, "r", .orphan, 45)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1.linkedItem, false, "r")
            assertMismatchingTags(child1.linkedItem, 1, "r")

            let child2 = child1.children[0] // l <-> r
            assertItem(child2, 0, 2, 1, 0, 4, "dir", .orphan, 42)
            #expect(child2.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child2.orphanFolders)")
            assertFolderTags(child2, false, "dir")
            assertMismatchingTags(child2, 0, "dir")
            assertItem(child2.linkedItem, 0, 2, 0, 0, 4, "dir", .orphan, 30)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2.linkedItem, false, "dir")
            assertMismatchingTags(child2.linkedItem, 0, "dir")

            let child3 = child2.children[0] // dir <-> dir
            assertItem(child3, 0, 1, 0, 0, 1, "deeper", .orphan, 14)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.orphanFolders)")
            assertFolderTags(child3, false, "deeper")
            assertMismatchingTags(child3, 0, "deeper")
            assertItem(child3.linkedItem, 0, 1, 0, 0, 1, "deeper", .orphan, 15)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3.linkedItem, false, "deeper")
            assertMismatchingTags(child3.linkedItem, 0, "deeper")

            let child4 = child3.children[0] // deeper <-> deeper
            assertItem(child4, 0, 1, 0, 0, 0, "file5.txt", .changed, 14)
            assertFolderTags(child4, false, "file5.txt")
            assertMismatchingTags(child4, 0, "file5.txt")
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "file5.txt", .changed, 15)
            assertFolderTags(child4.linkedItem, false, "file5.txt")
            assertMismatchingTags(child4.linkedItem, 0, "file5.txt")

            let child5 = child2.children[1] // dir <-> dir
            assertItem(child5, 0, 0, 0, 0, 0, "other", .orphan, 0)
            #expect(child5.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child5.orphanFolders)")
            assertFolderTags(child5, false, "other")
            assertMismatchingTags(child5, 0, "other")
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child6 = child2.children[2] // dir <-> dir
            assertItem(child6, 0, 0, 1, 0, 0, "file3.txt", .orphan, 14)
            assertFolderTags(child6, false, "file3.txt")
            assertMismatchingTags(child6, 0, "file3.txt")
            assertItem(child6.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child7 = child2.children[3] // dir <-> dir
            assertItem(child7, 0, 1, 0, 0, 0, "file4.txt", .changed, 14)
            assertFolderTags(child7, false, "file4.txt")
            assertMismatchingTags(child7, 0, "file4.txt")
            assertItem(child7.linkedItem, 0, 1, 0, 0, 0, "file4.txt", .changed, 15)
            assertFolderTags(child7.linkedItem, false, "file4.txt")
            assertMismatchingTags(child7.linkedItem, 0, "file4.txt")

            let child8 = child1.children[1] // l <-> r
            assertItem(child8, 0, 0, 1, 0, 0, "file1.txt", .orphan, 14)
            assertFolderTags(child8, false, "file1.txt")
            assertMismatchingTags(child8, 0, "file1.txt")
            assertItem(child8.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let child9 = child1.children[2] // l <-> r
            assertItem(child9, 0, 1, 0, 0, 0, "file2.txt", .changed, 14)
            assertFolderTags(child9, false, "file2.txt")
            assertMismatchingTags(child9, 1, "file2.txt")
            assertItem(child9.linkedItem, 1, 0, 0, 0, 0, "file2.txt", .old, 15)
            assertFolderTags(child9.linkedItem, false, "file2.txt")
            assertMismatchingTags(child9.linkedItem, 1, "file2.txt")
        }
        do {
            // VisibleItems
            let childVI1 = vi // l <--> r
            assertArrayCount(childVI1.children, 3)
            let child1 = childVI1.item // nil <-> nil
            assertItem(child1, 0, 3, 2, 0, 3, "l", .orphan, 70)
            #expect(child1.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child1.orphanFolders)")
            assertFolderTags(child1, false, "l")
            assertMismatchingTags(child1, 1, "l")
            assertItem(child1.linkedItem, 1, 2, 0, 0, 3, "r", .orphan, 45)
            #expect(child1.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child1.linkedItem!.orphanFolders)")
            assertFolderTags(child1.linkedItem, false, "r")
            assertMismatchingTags(child1.linkedItem, 1, "r")

            let childVI2 = childVI1.children[0] // l <--> r
            assertArrayCount(childVI2.children, 3)
            let child2 = childVI2.item // l <-> r
            assertItem(child2, 0, 2, 1, 0, 4, "dir", .orphan, 42)
            #expect(child2.orphanFolders == 1, "OrphanFolder: Expected count 1 found \(child2.orphanFolders)")
            assertFolderTags(child2, false, "dir")
            assertMismatchingTags(child2, 0, "dir")
            assertItem(child2.linkedItem, 0, 2, 0, 0, 4, "dir", .orphan, 30)
            #expect(child2.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child2.linkedItem!.orphanFolders)")
            assertFolderTags(child2.linkedItem, false, "dir")
            assertMismatchingTags(child2.linkedItem, 0, "dir")

            let childVI3 = childVI2.children[0] // dir <--> dir
            assertArrayCount(childVI3.children, 1)
            let child3 = childVI3.item // dir <-> dir
            assertItem(child3, 0, 1, 0, 0, 1, "deeper", .orphan, 14)
            #expect(child3.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.orphanFolders)")
            assertFolderTags(child3, false, "deeper")
            assertMismatchingTags(child3, 0, "deeper")
            assertItem(child3.linkedItem, 0, 1, 0, 0, 1, "deeper", .orphan, 15)
            #expect(child3.linkedItem?.orphanFolders == 0, "OrphanFolder: Expected count 0 found \(child3.linkedItem!.orphanFolders)")
            assertFolderTags(child3.linkedItem, false, "deeper")
            assertMismatchingTags(child3.linkedItem, 0, "deeper")

            let childVI4 = childVI3.children[0] // deeper <--> deeper
            assertArrayCount(childVI4.children, 0)
            let child4 = childVI4.item // deeper <-> deeper
            assertItem(child4, 0, 1, 0, 0, 0, "file5.txt", .changed, 14)
            assertFolderTags(child4, false, "file5.txt")
            assertMismatchingTags(child4, 0, "file5.txt")
            assertItem(child4.linkedItem, 0, 1, 0, 0, 0, "file5.txt", .changed, 15)
            assertFolderTags(child4.linkedItem, false, "file5.txt")
            assertMismatchingTags(child4.linkedItem, 0, "file5.txt")

            let childVI5 = childVI2.children[1] // dir <--> dir
            assertArrayCount(childVI5.children, 0)
            let child5 = childVI5.item // dir <-> dir
            assertItem(child5, 0, 0, 1, 0, 0, "file3.txt", .orphan, 14)
            assertFolderTags(child5, false, "file3.txt")
            assertMismatchingTags(child5, 0, "file3.txt")
            assertItem(child5.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI6 = childVI2.children[2] // dir <--> dir
            assertArrayCount(childVI6.children, 0)
            let child6 = childVI6.item // dir <-> dir
            assertItem(child6, 0, 1, 0, 0, 0, "file4.txt", .changed, 14)
            assertFolderTags(child6, false, "file4.txt")
            assertMismatchingTags(child6, 0, "file4.txt")
            assertItem(child6.linkedItem, 0, 1, 0, 0, 0, "file4.txt", .changed, 15)
            assertFolderTags(child6.linkedItem, false, "file4.txt")
            assertMismatchingTags(child6.linkedItem, 0, "file4.txt")

            let childVI7 = childVI1.children[1] // l <--> r
            assertArrayCount(childVI7.children, 0)
            let child7 = childVI7.item // l <-> r
            assertItem(child7, 0, 0, 1, 0, 0, "file1.txt", .orphan, 14)
            assertFolderTags(child7, false, "file1.txt")
            assertMismatchingTags(child7, 0, "file1.txt")
            assertItem(child7.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)

            let childVI8 = childVI1.children[2] // l <--> r
            assertArrayCount(childVI8.children, 0)
            let child8 = childVI8.item // l <-> r
            assertItem(child8, 0, 1, 0, 0, 0, "file2.txt", .changed, 14)
            assertFolderTags(child8, false, "file2.txt")
            assertMismatchingTags(child8, 1, "file2.txt")
            assertItem(child8.linkedItem, 1, 0, 0, 0, 0, "file2.txt", .old, 15)
            assertFolderTags(child8.linkedItem, false, "file2.txt")
            assertMismatchingTags(child8.linkedItem, 1, "file2.txt")
        }
    }
}

// swiftlint:enable file_length force_unwrapping function_body_length
