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
        let eolCarriageMixed = DiffLineComponent.splitLines("line1\rline2\nline3").detectEOL()
        let eolUnix = DiffLineComponent.splitLines("line1\nline2\nline3").detectEOL()
        let eolCRLFMixed = DiffLineComponent.splitLines("line1\r\nline2\nline3").detectEOL()
        let eolCR = DiffLineComponent.splitLines("line1\rline2\rline3").detectEOL()
        let eolCRLF = DiffLineComponent.splitLines("line1\r\nline2\r\nline3").detectEOL()
        let eolLineWithoutEOL = DiffLineComponent.splitLines("long line").detectEOL()

        #expect(eolCarriageMixed == .mixed)
        #expect(eolUnix == .unix)
        #expect(eolCRLFMixed == .mixed)
        #expect(eolCRLF == .pcCRLF)
        #expect(eolCR == .pcCR)
        #expect(eolLineWithoutEOL == .missing)
    }
}
