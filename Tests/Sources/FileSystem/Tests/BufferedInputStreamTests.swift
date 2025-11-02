//
//  BufferedInputStreamTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable force_unwrapping
final class BufferedInputStreamTests {
    @Test func minBufferSize() throws {
        let lines = [
            "Ciao 👋",
            "🍕+🍺=❤️",
            "🚀 Go!",
        ]
        try testLines(
            lines: lines,
            bufferSize: 1
        )
        try testBisLines(
            lines: lines,
            bufferSize: 1
        )
    }

    @Test func bigBufferSize() throws {
        let lines = [
            "Ciao 👋",
            "🍕+🍺=❤️",
            "🚀 Go!",
        ]
        try testLines(
            lines: lines,
            bufferSize: 100_000
        )
        try testBisLines(
            lines: lines,
            bufferSize: 100_000
        )
    }

    func testLines(
        lines: [String],
        bufferSize: Int,
        encoding: String.Encoding = .utf8,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let inputStrem = InputStream(data: lines.joined(separator: "\n").data(using: encoding)!)
        defer {
            inputStrem.close()
        }
        let bis = BufferedInputStream(
            stream: inputStrem,
            encoding: encoding,
            bufferSize: bufferSize
        )
        defer {
            bis.close()
        }

        bis.open()

        var i = 0
        while let line = bis.readLine() {
            #expect(line == lines[i], sourceLocation: sourceLocation)
            i += 1
        }
    }

    func testBisLines(
        lines: [String],
        bufferSize: Int,
        encoding: String.Encoding = .utf8,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let inputStrem = InputStream(data: lines.joined(separator: "\n").data(using: encoding)!)
        defer {
            inputStrem.close()
        }
        let bis = BufferedInputStream(
            stream: inputStrem,
            encoding: encoding,
            bufferSize: bufferSize
        )
        defer {
            bis.close()
        }

        bis.open()

        var i = 0
        while let line = bis.readLine() {
            #expect(line == lines[i], sourceLocation: sourceLocation)
            i += 1
        }
    }

    @Test func bigFile() throws {
        let testBundle = Bundle(for: type(of: self))

        guard let filePath = testBundle.url(forResource: "big_file_5000_lines", withExtension: "txt") else {
            Issue.record("Unable to find resource big_file_5000_lines.txt")
            return
        }

        let bis = try BufferedInputStream(
            url: filePath,
            encoding: .utf8,
            bufferSize: 500
        )
        defer {
            bis.close()
        }

        bis.open()

        var lineCount = 0
        while bis.readLine() != nil {
            lineCount += 1
        }

        #expect(lineCount == 5000)
    }

    #if OLD_OBJC_BUFFERED_INPUT_STREAM
        @Test("Test any regression with the original Objc code") func bigFile2() throws {
            let testBundle = Bundle(for: type(of: self))

            guard let filePath = testBundle.url(forResource: "big_file_5000_lines", withExtension: "txt") else {
                Issue.record("Unable to find resource big_file_5000_lines.txt")
                return
            }

            let bisNew = try BufferedInputStream(
                url: filePath,
                encoding: .utf8,
                bufferSize: 500
            )
            let bisOld = TOPBufferedInputStream(
                fileAtPath: filePath.osPath,
                encoding: String.Encoding.utf8.rawValue,
                bufferSize: 500
            )
            defer {
                bisNew.close()
                bisOld.close()
            }

            bisNew.open()
            bisOld.open()

            var lineCount = 0

            while true {
                guard let bisNewLine = bisNew.readLine(),
                      let bisOldLine = bisOld.readLine() else {
                    break
                }
                lineCount += 1
                #expect(bisNewLine == bisOldLine)
            }

            #expect(lineCount == 5000)
        }
    #endif

    @Test("Native Swift Data Encoding differs from Objc") func nativeSwiftAsciiEncoding() {
        let data = Data(
            [
                0x62,
                0x70,
                0x6C,
                0x69,
                0x73,
                0x74,
                0x30,
                0x30,
                0xD4,
                0x00,
                0x01,
                0x00,
                0x02,
                0x00,
                0x03,
                0x00,
                0x04,
                0x00,
                0x05,
            ]
        )
        // we can't use the native Swift String(data:encoding) because the results are different
        let swiftString = String(data: data, encoding: .ascii)
        let nsString = NSString(data: data, encoding: String.Encoding.ascii.rawValue)

        #expect(swiftString == nil)
        #expect(nsString != nil)
    }
}

// swiftlint:enable force_unwrapping
