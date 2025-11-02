//
//  EndOfLineTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class EndOfLineTests: DiffResultBaseTests {
    @Test func endOfLine() {
        let eolReturn = EndOfLine.detectEOL(from: "line1\rline2\nline3")
        let eolUnix = EndOfLine.detectEOL(from: "line1\nline2\nline3")
        let eolCarriageReturn = EndOfLine.detectEOL(from: "line1\r\nline2\nline3")
        let eolLineWithoutEOL = EndOfLine.detectEOL(from: "long line")

        #expect(eolReturn == .pc)
        #expect(eolUnix == .unix)
        #expect(eolCarriageReturn == .pc)
        #expect(eolLineWithoutEOL == .unix)
    }
}
