//
//  ExternalChangeSizeTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class ExternalChangeSizeTests: BaseTests {
    @Test
    func copyOverDestinationChangedAfterCompare() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
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

        let srcContent = "123456789012"
        let destContent = "12345"
        let changedContent = String(repeating: "x", count: 50)

        try createFolder("l/a")
        try createFolder("r/a")

        try createFile("l/a/file.txt", srcContent)
        try createFile("r/a/file.txt", destContent)

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        let folderL = rootL.children[0]
        let folderR = try #require(folderL.linkedItem)
        let fileL = folderL.children[0]

        #expect(folderR.subfoldersSize == Int64(destContent.count))

        try assertOnlySetup()

        // the destination changes on disk after the compare, the in-memory tree still counts the old size
        try createFile("r/a/file.txt", changedContent)

        let fileOperationDelegate = MockFileOperationManagerDelegate()
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
            srcRoot: fileL,
            srcBaseDir: appendFolder("l"),
            destination: .linkedSide(baseDir: appendFolder("r"))
        )

        #expect(fileOperationDelegate.errors.isEmpty)
        try assertFileExists(appendFolder("r/a/file.txt", false).osPath, srcContent)
        #expect(folderR.subfoldersSize == Int64(srcContent.count))
    }

    @Test
    func moveOverDestinationChangedAfterCompare() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
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

        let srcContent = "123456789012"
        let destContent = "12345"
        let changedContent = String(repeating: "x", count: 50)

        try createFolder("l/a")
        try createFolder("r/a")

        try createFile("l/a/file.txt", srcContent)
        try createFile("r/a/file.txt", destContent)

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        let folderL = rootL.children[0]
        let folderR = try #require(folderL.linkedItem)
        let fileL = folderL.children[0]

        #expect(folderR.subfoldersSize == Int64(destContent.count))

        try assertOnlySetup()

        // the destination changes on disk after the compare, the in-memory tree still counts the old size
        try createFile("r/a/file.txt", changedContent)

        let fileOperationDelegate = MockFileOperationManagerDelegate()
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
            srcRoot: fileL,
            srcBaseDir: appendFolder("l"),
            destBaseDir: appendFolder("r")
        )

        #expect(fileOperationDelegate.errors.isEmpty)
        try assertFileExists(appendFolder("r/a/file.txt", false).osPath, srcContent)
        #expect(folderL.subfoldersSize == 0)
        #expect(folderR.subfoldersSize == Int64(srcContent.count))
    }
}
