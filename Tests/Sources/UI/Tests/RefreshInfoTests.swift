//
//  RefreshInfoTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class RefreshInfoTests: BaseTests {
    @Test func refreshInfoStartComparisonNoExpand() {
        let expected = RefreshInfo(
            initState: true,
            expandAllFolders: false
        )

        #expect(expected.refreshFolders == true)
        #expect(expected.realign == true)
        #expect(expected.refreshComparison == true)
        #expect(expected.expandAllFolders == false)
    }

    @Test func refreshInfoExcludeByNameNoExpand() {
        let expected = RefreshInfo(
            initState: false
        )

        #expect(expected.refreshFolders == false)
        #expect(expected.realign == false)
        #expect(expected.refreshComparison == false)
        #expect(expected.expandAllFolders == false)
    }

    @Test func refreshInfoSelectComparisonNoExpand() {
        let expected = RefreshInfo(
            initState: false,
            refreshComparison: true
        )

        #expect(expected.refreshFolders == false)
        #expect(expected.realign == false)
        #expect(expected.refreshComparison == true)
        #expect(expected.expandAllFolders == false)
    }

    @Test func refreshInfoSelectDisplayFlagsNoExpand() {
        let expected = RefreshInfo(
            initState: false
        )
        #expect(expected.refreshFolders == false)
        #expect(expected.realign == false)
        #expect(expected.refreshComparison == false)
        #expect(expected.expandAllFolders == false)
    }

    @Test func refreshInfoSetBaseFoldersSrcNoExpand() {
        let expected = RefreshInfo(
            initState: false,
            realign: true
        )

        #expect(expected.refreshFolders == false)
        #expect(expected.realign == true)
        #expect(expected.refreshComparison == true)
        #expect(expected.expandAllFolders == false)
    }

    // MARK: - expand

    @Test func refreshInfoStartComparisonExpand() {
        let expected = RefreshInfo(
            initState: true
        )
        #expect(expected.refreshFolders == true)
        #expect(expected.realign == true)
        #expect(expected.refreshComparison == true)
        #expect(expected.expandAllFolders == true)
    }

    @Test func refreshInfoExcludeByNameExpand() {
        let expected = RefreshInfo(
            initState: false,
            expandAllFolders: true
        )
        #expect(expected.refreshFolders == false)
        #expect(expected.realign == false)
        #expect(expected.refreshComparison == false)
        #expect(expected.expandAllFolders == true)
    }

    @Test func refreshInfoSelectComparisonExpand() {
        let expected = RefreshInfo(
            initState: false,
            refreshComparison: true,
            expandAllFolders: true
        )

        #expect(expected.refreshFolders == false)
        #expect(expected.realign == false)
        #expect(expected.refreshComparison == true)
        #expect(expected.expandAllFolders == true)
    }

    @Test func refreshInfoSelectDisplayFlagsExpand() {
        let expected = RefreshInfo(
            initState: false,
            expandAllFolders: true
        )

        #expect(expected.refreshFolders == false)
        #expect(expected.realign == false)
        #expect(expected.refreshComparison == false)
        #expect(expected.expandAllFolders == true)
    }

    @Test func refreshInfoSetBaseFoldersSrcExpand() {
        let expected = RefreshInfo(
            initState: false,
            realign: true,
            expandAllFolders: true
        )

        #expect(expected.refreshFolders == false)
        #expect(expected.realign == true)
        #expect(expected.refreshComparison == true)
        #expect(expected.expandAllFolders == true)
    }
}
