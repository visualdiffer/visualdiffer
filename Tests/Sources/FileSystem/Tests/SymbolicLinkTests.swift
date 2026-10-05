//
//  SymbolicLinkTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class SymbolicLinkTests: BaseTests {
    @Test
    func symbolicLinkLoop() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: .contentTimestamp,
            delegate: comparatorDelegate,
            bufferSize: 8192
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
        try createFolder("l/parent")
        try createSymlink("l/parent/sym_parent", "../parent")

        try createFolder("r")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        assertErrors(
            folderReaderDelegate.errors, [
                FileError.symlinkLoop(path: appendFolder("l/parent/sym_parent").osPath),
            ]
        )
    }

    @Test
    func copyFileOverSymlinkToFile() throws {
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
        try removeItem("target")

        let srcContent = "123456789012"
        let targetContent = String(repeating: "x", count: 100)

        try createFolder("l/a")
        try createFolder("r/a")
        try createFolder("target")

        try createFile("l/a/file.txt", srcContent)
        // the target lives outside the compared folders so only the link is counted in r/a
        try createFile("target/big.txt", targetContent)
        try createSymlink("r/a/file.txt", "target/big.txt")

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
        let fileR = try #require(fileL.linkedItem)

        // the symlink contributes the resolved target size
        #expect(fileR.isSymbolicLink)
        #expect(fileR.fileSize == Int64(targetContent.count))
        #expect(folderR.subfoldersSize == Int64(targetContent.count))

        try assertOnlySetup()

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

        // read again from disk to get the expected sizes
        let freshReaderDelegate = MockFolderReaderDelegate(isRunning: true)
        let freshReader = FolderReader(
            with: freshReaderDelegate,
            comparator: comparator,
            filterConfig: filterConfig,
            refreshInfo: RefreshInfo(initState: true)
        )
        freshReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )
        let freshRootL = try #require(freshReader.leftRoot)
        let freshFolderR = try #require(freshRootL.children[0].linkedItem)

        #expect(freshFolderR.subfoldersSize == Int64(srcContent.count))
        #expect(fileR.fileSize == Int64(srcContent.count))
        #expect(folderR.subfoldersSize == freshFolderR.subfoldersSize)
    }

    @Test
    func moveFileOverSymlinkToFile() throws {
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
        try removeItem("target")

        let srcContent = "123456789012"
        let targetContent = String(repeating: "x", count: 100)

        try createFolder("l/a")
        try createFolder("r/a")
        try createFolder("target")

        try createFile("l/a/file.txt", srcContent)
        // the target lives outside the compared folders so only the link is counted in r/a
        try createFile("target/big.txt", targetContent)
        try createSymlink("r/a/file.txt", "target/big.txt")

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
        let fileR = try #require(fileL.linkedItem)

        // the symlink contributes the resolved target size
        #expect(fileR.isSymbolicLink)
        #expect(fileR.fileSize == Int64(targetContent.count))
        #expect(folderL.subfoldersSize == Int64(srcContent.count))
        #expect(folderR.subfoldersSize == Int64(targetContent.count))

        try assertOnlySetup()

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
        #expect(!fm.fileExists(atPath: appendFolder("l/a/file.txt", false).osPath))
        try assertFileExists(appendFolder("r/a/file.txt", false).osPath, srcContent)

        // read again from disk to get the expected sizes
        let freshReaderDelegate = MockFolderReaderDelegate(isRunning: true)
        let freshReader = FolderReader(
            with: freshReaderDelegate,
            comparator: comparator,
            filterConfig: filterConfig,
            refreshInfo: RefreshInfo(initState: true)
        )
        freshReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )
        let freshRootL = try #require(freshReader.leftRoot)
        let freshFolderL = freshRootL.children[0]
        let freshFolderR = try #require(freshFolderL.linkedItem)

        #expect(freshFolderL.subfoldersSize == 0)
        #expect(freshFolderR.subfoldersSize == Int64(srcContent.count))
        #expect(fileR.fileSize == Int64(srcContent.count))
        #expect(folderL.subfoldersSize == freshFolderL.subfoldersSize)
        #expect(folderR.subfoldersSize == freshFolderR.subfoldersSize)
    }
}
