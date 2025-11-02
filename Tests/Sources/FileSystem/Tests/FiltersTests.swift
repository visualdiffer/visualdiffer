//
//  FiltersTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class FiltersTests: BaseTests {
    @Test func filterFileNameIgnoreCase() {
        let root = CompareItem(
            path: "/fakePath",
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: nil
        )
        let item = CompareItem(
            path: "/fakePath/all_lower_case.txt",
            attrs: [.type: FileAttributeType.typeRegular],
            fileExtraOptions: [],
            parent: root
        )

        let filter = #"fileName ==[c] "ALL_LOWER_CASE.txt""#
        #expect(item.evaluate(filter: NSPredicate(format: filter)))
    }

    @Test() func filterFileNameCaseSensitive() {
        let root = CompareItem(
            path: "/fakePath",
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: nil
        )
        let item = CompareItem(
            path: "/fakePath/all_lower_case.txt",
            attrs: [.type: FileAttributeType.typeRegular],
            fileExtraOptions: [],
            parent: root
        )

        let filter = #"fileName CONTAINS "ALL_LOWER_CASE.txt""#
        #expect(item.evaluate(filter: NSPredicate(format: filter)) == false)
    }

    @Test() func filterPathIgnoreCase() {
        let root = CompareItem(
            path: "/fakePath",
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: nil
        )
        let dirName1 = CompareItem(
            path: "/fakePath/dirName1",
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: root
        )
        let item = CompareItem(
            path: "/fakePath/dirName1/all_lower_case.txt",
            attrs: [.type: FileAttributeType.typeRegular],
            fileExtraOptions: [],
            parent: dirName1
        )

        let filter = #"pathRelativeToRoot CONTAINS[c] "DIRNAME1""#
        #expect(item.evaluate(filter: NSPredicate(format: filter)))
    }

    @Test() func filterPathCaseSensitive() {
        let root = CompareItem(
            path: "/fakePath",
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: nil
        )
        let dirName1 = CompareItem(
            path: "/fakePath/dirName1",
            attrs: [.type: FileAttributeType.typeDirectory],
            fileExtraOptions: [],
            parent: root
        )
        let item = CompareItem(
            path: "/fakePath/dirName1/all_lower_case.txt",
            attrs: [.type: FileAttributeType.typeRegular],
            fileExtraOptions: [],
            parent: dirName1
        )

        let filter = #"pathRelativeToRoot CONTAINS "DIRNAME1""#
        #expect(item.evaluate(filter: NSPredicate(format: filter)) == false)
    }

    @Test func filterFileSize() {
        let attributes: [FileAttributeKey: Any] = [
            .size: NSNumber(value: 5),
        ]
        let item = CompareItem(
            path: nil,
            attrs: attributes,
            fileExtraOptions: [],
            parent: nil
        )

        let filter = "fileSize == 5"
        #expect(item.evaluate(filter: NSPredicate(format: filter)))
    }

    @Test func filterModificationDate() throws {
        let attributes: [FileAttributeKey: Any] = try [
            .modificationDate: buildDate("2012-05-05 11: 00: 11 +0000"),
        ]
        let item = CompareItem(
            path: nil,
            attrs: attributes,
            fileExtraOptions: [],
            parent: nil
        )

        // after 2012-06-01 06:00
        let filter = #"fileObjectModificationDate > CAST(347518800.000000, "NSDate")"#
        #expect(item.evaluate(filter: NSPredicate(format: filter)))
    }
}
