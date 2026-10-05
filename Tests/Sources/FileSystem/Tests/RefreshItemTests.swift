//
//  RefreshItemTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class RefreshItemTests: BaseTests {
    private struct Fixture {
        let folderReader: FolderReader
        let comparator: ItemComparator
        let filterConfig: FilterConfig
    }

    private let comparatorBufferSize = 8192

    @Test
    func refreshChangedFileBecomesMatched() throws {
        let fixture = makeFixture()

        try removeItem("l")
        try removeItem("r")

        try createFolder("l/a")
        try createFolder("r/a")

        try createFile("l/a/file.txt", "12")
        try createFile("r/a/file.txt", "123")

        fixture.folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(fixture.folderReader.leftRoot)
        let fileL = rootL.children[0].children[0]
        assertChanged(rootL, rightSize: 3)

        try assertOnlySetup()

        // same size on both sides so the size comparison now reports a match
        try createFile("r/a/file.txt", "12")

        fileL.refresh(filterConfig: fixture.filterConfig, comparator: fixture.comparator)
        assertMatched(rootL, rightSize: 2)

        // nothing changed on disk so a second refresh must leave the counters untouched
        fileL.refresh(filterConfig: fixture.filterConfig, comparator: fixture.comparator)
        assertMatched(rootL, rightSize: 2)
    }

    @Test
    func refreshMatchedFileBecomesChanged() throws {
        let fixture = makeFixture()

        try removeItem("l")
        try removeItem("r")

        try createFolder("l/a")
        try createFolder("r/a")

        try createFile("l/a/file.txt", "12")
        try createFile("r/a/file.txt", "12")

        fixture.folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(fixture.folderReader.leftRoot)
        let fileL = rootL.children[0].children[0]
        assertMatched(rootL, rightSize: 2)

        try assertOnlySetup()

        // different size so the size comparison now reports a change
        try createFile("r/a/file.txt", "123")

        fileL.refresh(filterConfig: fixture.filterConfig, comparator: fixture.comparator)
        assertChanged(rootL, rightSize: 3)

        // nothing changed on disk so a second refresh must leave the counters untouched
        fileL.refresh(filterConfig: fixture.filterConfig, comparator: fixture.comparator)
        assertChanged(rootL, rightSize: 3)
    }

    private func makeFixture() -> Fixture {
        let comparator = ItemComparator(
            options: .size,
            delegate: MockItemComparatorDelegate(),
            bufferSize: comparatorBufferSize
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
        let folderReader = FolderReader(
            with: MockFolderReaderDelegate(isRunning: true),
            comparator: comparator,
            filterConfig: filterConfig,
            refreshInfo: RefreshInfo(initState: true)
        )
        return Fixture(folderReader: folderReader, comparator: comparator, filterConfig: filterConfig)
    }

    // left file is always 2 bytes, only the right side size varies
    private func assertChanged(
        _ rootL: CompareItem,
        rightSize: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let folderL = rootL.children[0]
        let fileL = folderL.children[0]

        assertItem(fileL, 0, 1, 0, 0, 0, "file.txt", .changed, 2, sourceLocation: sourceLocation)
        assertItem(fileL.linkedItem, 0, 1, 0, 0, 0, "file.txt", .changed, rightSize, sourceLocation: sourceLocation)
        assertItem(folderL, 0, 1, 0, 0, 1, "a", .orphan, 2, sourceLocation: sourceLocation)
        assertItem(folderL.linkedItem, 0, 1, 0, 0, 1, "a", .orphan, rightSize, sourceLocation: sourceLocation)

        #expect(rootL.changedFiles == 1, sourceLocation: sourceLocation)
        #expect(rootL.matchedFiles == 0, sourceLocation: sourceLocation)
        #expect(rootL.linkedItem?.changedFiles == 1, sourceLocation: sourceLocation)
        #expect(rootL.linkedItem?.matchedFiles == 0, sourceLocation: sourceLocation)
    }

    private func assertMatched(
        _ rootL: CompareItem,
        rightSize: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let folderL = rootL.children[0]
        let fileL = folderL.children[0]

        assertItem(fileL, 0, 0, 0, 1, 0, "file.txt", .same, 2, sourceLocation: sourceLocation)
        assertItem(fileL.linkedItem, 0, 0, 0, 1, 0, "file.txt", .same, rightSize, sourceLocation: sourceLocation)
        assertItem(folderL, 0, 0, 0, 1, 1, "a", .orphan, 2, sourceLocation: sourceLocation)
        assertItem(folderL.linkedItem, 0, 0, 0, 1, 1, "a", .orphan, rightSize, sourceLocation: sourceLocation)

        #expect(rootL.changedFiles == 0, sourceLocation: sourceLocation)
        #expect(rootL.matchedFiles == 1, sourceLocation: sourceLocation)
        #expect(rootL.linkedItem?.changedFiles == 0, sourceLocation: sourceLocation)
        #expect(rootL.linkedItem?.matchedFiles == 1, sourceLocation: sourceLocation)
    }
}
