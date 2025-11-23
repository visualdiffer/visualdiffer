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

    func insert(_ line: DiffLine, at index: Int) {
        lines.insert(line, at: index)
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

        for line in lines where line.type != .missing {
            if let data = line.component.withEol.data(using: encoding) {
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
}
