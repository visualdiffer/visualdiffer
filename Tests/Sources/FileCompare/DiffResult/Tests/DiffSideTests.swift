//
//  DiffSideTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/05/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Foundation
import Testing
@testable import VisualDiffer

final class DiffSideTests: DiffResultBaseTests {
    @Test
    func writeLeavesOriginalFileUntouchedWhenEncodingFails() throws {
        try createFolder("")
        try removeItem("file.txt")
        try createFile("file.txt", "original")

        let diffSide = DiffSide()
        diffSide.add(
            line: DiffLine(
                with: .matching,
                number: 1,
                component: DiffLineComponent(text: "Euro €", eol: .missing)
            )
        )

        do {
            try diffSide.write(
                path: appendFolder("file.txt", false),
                encoding: .ascii
            )
            Issue.record("Expected encoding failure")
        } catch let error as FileError {
            #expect(error == .encodingFailed(encoding: .ascii))
        }

        let text = try String(
            contentsOf: appendFolder("file.txt", false),
            encoding: .utf8
        )
        #expect(text == "original")
    }

    @Test
    func writeUpdatesSymlinkDestinationWithoutReplacingTheLink() throws {
        try createFolder("")
        try removeItem("target.txt")
        try removeItem("link.txt")
        try createFile("target.txt", "original")
        try createSymlink("link.txt", "target.txt")

        let diffSide = DiffSide()
        diffSide.add(
            line: DiffLine(
                with: .matching,
                number: 1,
                component: DiffLineComponent(text: "updated", eol: .missing)
            )
        )

        let linkUrl = appendFolder("link.txt", false)
        let targetUrl = appendFolder("target.txt", false)

        try diffSide.write(
            path: linkUrl,
            encoding: .utf8
        )

        let targetText = try String(contentsOf: targetUrl, encoding: .utf8)
        #expect(targetText == "updated")

        let destination = try fm.destinationOfSymbolicLink(atPath: linkUrl.osPath)
        #expect(destination == targetUrl.osPath)
    }
}
