//
//  BaseTests+AssertCompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

public extension BaseTests {
    // swiftlint:disable:next function_parameter_count
    func assertItem(
        _ item: CompareItem?,
        _ expectedOld: Int,
        _ expectedChg: Int,
        _ expectedAdd: Int,
        _ expectedMatch: Int,
        _ expectedChildren: Int,
        _ expectedFileName: String?,
        _ expectedType: CompareChangeType,
        _ expectedSubfoldersizeOrFileSize: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard let item else {
            Issue.record("CompareItem is nil", sourceLocation: sourceLocation)
            return
        }
        let safeName = expectedFileName ?? "(nil filename)"
        if let expectedFileName {
            if let fsFileName = item.fileName {
                #expect(fsFileName == expectedFileName, "fileName doesn't match \(fsFileName) <-> \(expectedFileName)", sourceLocation: sourceLocation)
            } else {
                Issue.record("fileName doesn't match path is null <-> \(expectedFileName)")
            }
        } else {
            #expect(item.path == nil, "fileName doesn't match \(safeName) <-> \(item.fileName ?? "")", sourceLocation: sourceLocation)
        }
        #expect(item.olderFiles == expectedOld, "older for '\(safeName)' expected \(expectedOld) found \(item.olderFiles)", sourceLocation: sourceLocation)
        #expect(item.changedFiles == expectedChg, "changed for \(safeName)' expected \(expectedChg) found \(item.changedFiles)", sourceLocation: sourceLocation)
        #expect(item.orphanFiles == expectedAdd, "orphan for '\(safeName)' expected \(expectedAdd) found \(item.orphanFiles)", sourceLocation: sourceLocation)
        #expect(item.matchedFiles == expectedMatch, "matched for '\(safeName)' expected \(expectedMatch) found \(item.matchedFiles)", sourceLocation: sourceLocation)
        #expect(item.children.count == expectedChildren, "children for '\(safeName)' expected \(expectedChildren) found \(item.children.count)", sourceLocation: sourceLocation)
        #expect(item.type == expectedType, "type for '\(safeName)' expected '\(expectedType)' found '\(item.type)'", sourceLocation: sourceLocation)
        if item.isFile {
            #expect(item.fileSize == expectedSubfoldersizeOrFileSize, "fileSize for '\(safeName)' expected \(expectedSubfoldersizeOrFileSize) found \(item.fileSize)", sourceLocation: sourceLocation)
        } else {
            #expect(item.subfoldersSize == expectedSubfoldersizeOrFileSize, "subfoldersSize for '\(safeName)' expected \(expectedSubfoldersizeOrFileSize) found \(item.subfoldersSize)", sourceLocation: sourceLocation)
        }
    }

    func assertArrayCount(_ arr: [some Any], _ expectedCount: Int, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(arr.count == expectedCount, "\(arr) array count expected \(expectedCount) but found \(arr.count)", sourceLocation: sourceLocation)
    }

    func assertError(_ error: Error, _ expected: FileError, sourceLocation: SourceLocation = #_sourceLocation) {
        guard let fileError = error as? FileError else {
            Issue.record("Error is not a FileError: \(error)", sourceLocation: sourceLocation)
            return
        }
        #expect(
            fileError == expected,
            "Error doesn't match: expected '\(expected) found '\(error)'",
            sourceLocation: sourceLocation
        )
    }

    /**
     Create the test setup and then stop execution
     */
    func assertOnlySetup(
        sourceLocation _: SourceLocation = #_sourceLocation
    ) throws {
        #if TEST_ONLY_SETUP
            throw TestError.onlySetup
        #endif
    }
}
