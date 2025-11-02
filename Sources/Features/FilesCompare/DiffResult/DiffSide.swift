//
//  DiffSide.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/12/10.
//  Copyright (c) 2010 visualdiffer.com
//

class DiffSide {
    private(set) var lines: [DiffLine] = []
    var eol: EndOfLine = .unix
    var hasTrailingEOL: Bool = false

    var linesCount: Int {
        lines.reversed().first { $0.number > 0 }?.number ?? 0
    }

    func findLineIndex(by lineNumber: Int) -> Int? {
        lines.firstIndex { $0.number == lineNumber }
    }

    func add(line: DiffLine) {
        lines.append(line)
    }

    func removeLine(at index: Int) {
        lines.remove(at: index)
    }

    func index(of line: DiffLine) -> Int? {
        lines.firstIndex { $0 === line }
    }

    func write(
        path: URL,
        encoding: String.Encoding
    ) throws {
        let fm = FileManager.default
        let osPath = path.osPath

        if !fm.fileExists(atPath: osPath) {
            // NSFileHandle needs an existing file
            fm.createFile(atPath: osPath, contents: nil)
        }
        let fileHandle = try FileHandle(forWritingTo: path)
        defer { fileHandle.closeFile() }
        fileHandle.truncateFile(atOffset: 0)

        var linesToWrite = lines.count
        if !hasTrailingEOL {
            linesToWrite -= 1
        }

        let newLineData = eol.stringValue.data(using: encoding)
        for line in lines[0 ..< linesToWrite] where line.type != .missing {
            if let data = line.text.data(using: encoding),
               let newLineData {
                fileHandle.write(data)
                fileHandle.write(newLineData)
            }
        }
        if !hasTrailingEOL {
            // don't append newline
            if let line = lines.last,
               line.type != .missing,
               let data = line.text.data(using: encoding) {
                fileHandle.write(data)
            }
        }
    }

    func renumberLines() {
        var lineNumber = 1

        for line in lines where line.type != .missing {
            line.number = lineNumber
            lineNumber += 1
        }
    }

    func setupEOL(text: String) {
        if text.isEmpty {
            hasTrailingEOL = false
            eol = .unix
        } else {
            hasTrailingEOL = text.last == "\n"
            eol = EndOfLine.detectEOL(from: text)
        }
    }
}
