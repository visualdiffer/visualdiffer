//
//  BaseTests+AssertFileSystem.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping
public extension BaseTests {
    func assertSymlink(
        _ item: CompareItem,
        _ destPath: String,
        _ isFolder: Bool,
        functionName: String = #function,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        guard let url = item.toUrl() else {
            try #require(item.path != nil, "Unable to find path for \(item)", sourceLocation: sourceLocation)
            return
        }
        do {
            let resolved = try FileManager.default.destinationOfSymbolicLink(atPath: url.osPath)
            let real = URL(filePath: resolved, directoryHint: item.isFolder ? .isDirectory : .notDirectory)
            let destUrl = appendFolder(destPath, functionName: functionName)
            #expect(destUrl == real, "symlink dest doesn't match: expected \(destUrl) found \(real)", sourceLocation: sourceLocation)
            #expect(item.isSymbolicLink, "\(url) must be a symlink", sourceLocation: sourceLocation)
            if isFolder {
                #expect(item.isFolder, "\(url) must be a folder", sourceLocation: sourceLocation)
            } else {
                #expect(item.isFile, "\(url) must be a file", sourceLocation: sourceLocation)
            }
        } catch {
            Issue.record(error, sourceLocation: sourceLocation)
        }
    }

    func assertTimestamps(
        _ item: CompareItem?,
        _ strCreateDate: String?,
        _ strModDate: String?,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        guard let item else {
            try #require(item != nil, "fs is nil", sourceLocation: sourceLocation)
            return
        }
        guard let fsPath = item.path else {
            try #require(item.path != nil, "Unable to find path for \(item)", sourceLocation: sourceLocation)
            return
        }
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: fsPath)

            if let strCreateDate {
                if let creationDate = attrs[.creationDate] as? Date {
                    let isDateEqual = try buildDate(strCreateDate) == creationDate
                    #expect(isDateEqual, "Expected creation date for \(item.fileName!) is \(strCreateDate) but found \(creationDate)", sourceLocation: sourceLocation)
                } else {
                    Issue.record("Unable to get file creation date for \(fsPath)", sourceLocation: sourceLocation)
                }
            }

            if let strModDate {
                if let modificationDate = attrs[.modificationDate] as? Date {
                    let isDateEqual = try buildDate(strModDate) == modificationDate
                    #expect(isDateEqual, "Expected modification date for \(item.fileName!) is \(strModDate) but found \(modificationDate)", sourceLocation: sourceLocation)
                } else {
                    Issue.record("Unable to get file modification date for \(fsPath)", sourceLocation: sourceLocation)
                }
            }
        } catch {
            Issue.record(error)
        }
    }

    func assertMismatchingTags(_ item: CompareItem?, _ oldValue: Int, _ fileName: String, sourceLocation: SourceLocation = #_sourceLocation) {
        guard let item else {
            Issue.record("CompareItem is nil", sourceLocation: sourceLocation)
            return
        }
        #expect(item.mismatchingTags == oldValue, "Tags for '\(fileName)' expected \(oldValue) found \(item.mismatchingTags)", sourceLocation: sourceLocation)
    }

    func assertFolderTags(_ item: CompareItem?, _ value: Bool, _ fileName: String, sourceLocation: SourceLocation = #_sourceLocation) {
        guard let item else {
            Issue.record("CompareItem is nil", sourceLocation: sourceLocation)
            return
        }
        #expect(item.summary.hasMetadataTags == value, "Folder '\(fileName)' tags must be \(value)", sourceLocation: sourceLocation)
    }

    func assertMismatchingLabels(_ item: CompareItem?, _ oldValue: Int, _ fileName: String? = "", sourceLocation: SourceLocation = #_sourceLocation) {
        guard let item else {
            Issue.record("CompareItem is nil", sourceLocation: sourceLocation)
            return
        }
        #expect(item.mismatchingLabels == oldValue, "Labels for '\(fileName!)' expected \(oldValue) found \(item.mismatchingLabels)", sourceLocation: sourceLocation)
    }

    func assertFolderLabels(_ item: CompareItem?, _ value: Bool, _ fileName: String? = "", sourceLocation: SourceLocation = #_sourceLocation) {
        guard let item else {
            Issue.record("CompareItem is nil", sourceLocation: sourceLocation)
            return
        }
        #expect(item.summary.hasMetadataLabels == value, "Folder '\(fileName!)' labels must be \(value)", sourceLocation: sourceLocation)
    }

    func assertResourceFileLabels(_ item: CompareItem?, _ expectedValue: Int, _ path: URL, sourceLocation: SourceLocation = #_sourceLocation) {
        guard let item else {
            Issue.record("CompareItem is nil", sourceLocation: sourceLocation)
            return
        }
        do {
            let foundValue = try getLabelNumber(item.toUrl()!)
            #expect(foundValue == expectedValue, "Label for '\(path)' expected \(expectedValue) found \(foundValue)", sourceLocation: sourceLocation)
        } catch {
            Issue.record("Found error \(error)", sourceLocation: sourceLocation)
        }
    }
}

// swiftlint:enable force_unwrapping
