//
//  ComparatorTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/03/13.
//  Copyright (c) 2013 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping
final class ComparatorTests: BaseTests {
    @Test
    func timestampTolerance() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .timestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192,
            timestampToleranceSeconds: 5
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: true,
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

        try createFolder("l")
        try createFolder("r")

        // create files
        try createFile("l/sample01.txt", "content")
        try createFile("l/sample02.txt", "content")
        try createFile("l/sample03.txt", "content")
        try createFile("l/sample04.txt", "content")
        try createFile("l/sample05.txt", "content")

        try createFile("r/sample01.txt", "content")
        try createFile("r/sample02.txt", "content")
        try createFile("r/sample03.txt", "content")
        try createFile("r/sample04.txt", "content")
        try createFile("r/sample05.txt", "content")

        try setFileTimestamp("l/sample01.txt", "2001-03-24 10: 45: 00 +0600")
        try setFileTimestamp("l/sample02.txt", "2001-03-24 10: 45: 14 +0600")
        try setFileTimestamp("l/sample03.txt", "2001-03-24 10: 45: 30 +0600")
        try setFileTimestamp("l/sample04.txt", "2001-03-24 10: 45: 40 +0600")
        try setFileTimestamp("l/sample05.txt", "2001-03-24 10: 45: 20 +0600")

        try setFileTimestamp("r/sample01.txt", "2001-03-24 10: 45: 05 +0600")
        try setFileTimestamp("r/sample02.txt", "2001-03-24 10: 45: 10 +0600")
        try setFileTimestamp("r/sample03.txt", "2001-03-24 10: 45: 36 +0600")
        try setFileTimestamp("r/sample04.txt", "2001-03-24 10: 45: 20 +0600")
        try setFileTimestamp("r/sample05.txt", "2001-03-24 10: 45: 15 +0600")

        let rootL = try #require(folderReader.readFolder(
            atPath: appendFolder("l"),
            parent: nil,
            recursive: false
        ))

        let rootR = try #require(folderReader.readFolder(
            atPath: appendFolder("r"),
            parent: nil,
            recursive: false
        ))

        let expectedResults: [ComparisonResult] = [
            .orderedSame,
            .orderedSame,
            .orderedAscending,
            .orderedDescending,
            .orderedSame,
        ]
        let count = expectedResults.count

        #expect(count == rootL.children.count, "Expected count \(count) found \(rootL.children.count)")

        for i in 0 ..< rootL.children.count {
            let l = rootL.children[i]
            let r = rootR.children[i]
            let result = comparator.compare(l, r)
            #expect(result == expectedResults[i], "Result \(result) : Dates tolerance (\(comparator.timestampToleranceSeconds) secs) error \(String(describing: l.fileModificationDate)), \(String(describing: r.fileModificationDate))")
        }
    }

    @Test
    func compareAsText() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .asText,
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

        // create files
        try createFile("l/sample01.txt", "a\nb")
        try createFile("r/sample01.txt", "a\r\nb")

        try createFile("l/sample02.txt", "a\nb")
        try createFile("r/sample02.txt", "a\n\rb")

        try createFile("l/sample03.txt", "a\n\n\nb")
        try createFile("r/sample03.txt", "a\r\n\r\n\r\nb")

        let rootL = try #require(folderReader.readFolder(
            atPath: appendFolder("l"),
            parent: nil,
            recursive: false
        ))

        let rootR = try #require(folderReader.readFolder(
            atPath: appendFolder("r"),
            parent: nil,
            recursive: false
        ))

        let expectedResults: [ComparisonResult] = [
            .orderedSame,
            .orderedDescending,
            .orderedSame,
        ]
        let count = expectedResults.count

        #expect(count == rootL.children.count, "Expected count  \(count) found \(rootL.children.count)")

        for i in 0 ..< count {
            let l = rootL.children[i]
            let r = rootR.children[i]
            let result = comparator.compareContent(l, r, ignoreLineEndingDiff: true)
            #expect(result == expectedResults[i], "Result (index \(i)) expected \(expectedResults[i]) found \(result)")
        }
    }

    @Test
    func binaryContent() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .content,
            delegate: comparatorDelegate,
            bufferSize: 13
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: true,
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

        try createFolder("l")
        try createFolder("r")

        // a and b are identical
        let leftBytes: [UInt8] = [
            0x96, 0xBD, 0x8D, 0xC7, 0xE9, 0xE8, 0x75, 0x18, 0x99, 0xF1,
            0x15, 0x2F, 0x58, 0xCC, 0x8B, 0xB1, 0x50, 0x3F, 0xD1, 0xEF,
            0xC9, 0xF8, 0xCD, 0xE1, 0x90, 0x18, 0x1D, 0x0B, 0x02, 0x8A,
            0x71, 0x0E, 0x49, 0xB9, 0x1B, 0xE3, 0x78, 0x68, 0x9D, 0x97,
        ]
        var rightBytes: [UInt8] = [
            0x96, 0xBD, 0x8D, 0xC7, 0xE9, 0xE8, 0x75, 0x18, 0x99, 0xF1,
            0x15, 0x2F, 0x58, 0xCC, 0x8B, 0xB1, 0x50, 0x3F, 0xD1, 0xEF,
            0xC9, 0xF8, 0xCD, 0xE1, 0x90, 0x18, 0x1D, 0x0B, 0x02, 0x8A,
            0x71, 0x0E, 0x49, 0xB9, 0x1B, 0xE3, 0x78, 0x68, 0x9D, 0x97,
        ]

        // create files
        try createDataFile("l/sample01.txt", leftBytes)
        try createDataFile("l/sample02.txt", leftBytes)
        try createDataFile("l/sample03.txt", leftBytes)

        // increment last byte
        rightBytes[rightBytes.count - 1] = leftBytes[leftBytes.count - 1]
        rightBytes[rightBytes.count - 1] += 0x11
        try createDataFile("r/sample01.txt", rightBytes)

        try createDataFile("r/sample02.txt", leftBytes)

        // decrement last byte
        rightBytes[rightBytes.count - 1] = leftBytes[leftBytes.count - 1]
        rightBytes[rightBytes.count - 1] -= 0x11
        try createDataFile("r/sample03.txt", rightBytes)

        let rootL = try #require(folderReader.readFolder(
            atPath: appendFolder("l"),
            parent: nil,
            recursive: false
        ))

        let rootR = try #require(folderReader.readFolder(
            atPath: appendFolder("r"),
            parent: nil,
            recursive: false
        ))

        let expectedResults: [ComparisonResult] = [
            .orderedAscending,
            .orderedSame,
            .orderedDescending,
        ]
        let count = expectedResults.count

        #expect(count == rootL.children.count, "Expected count \(count) found \(rootL.children.count)")

        for i in 0 ..< rootL.children.count {
            let l = rootL.children[i]
            let r = rootR.children[i]
            let result = comparator.compare(l, r)
            #expect(result == expectedResults[i], "Result \(result) found \(expectedResults[i]): Content \(l.path!) \(r.path!)")
        }
    }

    @Test
    func size() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .size,
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

        // create files
        try createFile("l/sample01.txt", "1")
        try createFile("l/sample02.txt", "123456")
        try createFile("l/sample03.txt", "123456")
        try createFile("l/sample04.txt", "21")

        try createFile("r/sample01.txt", "1234")
        try createFile("r/sample02.txt", "1")
        try createFile("r/sample03.txt", "123")
        try createFile("r/sample04.txt", "21")

        let rootL = try #require(folderReader.readFolder(
            atPath: appendFolder("l"),
            parent: nil,
            recursive: false
        ))

        let rootR = try #require(folderReader.readFolder(
            atPath: appendFolder("r"),
            parent: nil,
            recursive: false
        ))

        let expectedResults: [ComparisonResult] = [
            .orderedAscending,
            .orderedDescending,
            .orderedDescending,
            .orderedSame,
        ]
        let count = expectedResults.count

        #expect(count == rootL.children.count, "Expected count \(count) found \(rootL.children.count)")

        for i in 0 ..< rootL.children.count {
            let l = rootL.children[i]
            let r = rootR.children[i]
            let result = comparator.compare(l, r)
            #expect(result == expectedResults[i], "Result \(result) : Size error \(l.fileSize), \(r.fileSize)")
        }
    }
}

// swiftlint:enable force_unwrapping
