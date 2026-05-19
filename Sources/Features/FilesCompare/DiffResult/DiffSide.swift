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
        // validate that all lines can be encoded before truncating the file;
        // temp-file approach was discarded due to symlink and sandbox issues
        for line in lines where line.type != .missing {
            _ = try encodedData(for: line, encoding: encoding)
        }

        let fileHandle = try openFileHandle(forWritingTo: path)
        defer { fileHandle.closeFile() }

        for line in lines where line.type != .missing {
            try fileHandle.write(encodedData(for: line, encoding: encoding))
        }
    }

    func renumberLines() {
        var lineNumber = 1

        for line in lines where line.type != .missing {
            line.number = lineNumber
            lineNumber += 1
        }
    }

    func nonMissingLineComponents() -> [DiffLineComponent] {
        lines.compactMap { line in
            line.type == .missing ? nil : line.component
        }
    }

    private func encodedData(
        for line: DiffLine,
        encoding: String.Encoding
    ) throws -> Data {
        guard let data = line.component.withEol.data(using: encoding) else {
            throw FileError.encodingFailed(encoding: encoding)
        }

        return data
    }

    private func openFileHandle(forWritingTo url: URL) throws -> FileHandle {
        let fm = FileManager.default
        let osPath = url.osPath

        if !fm.fileExists(atPath: osPath) {
            // FileHandle needs an existing file
            fm.createFile(atPath: osPath, contents: nil)
        }
        let fileHandle = try FileHandle(forWritingTo: url)
        fileHandle.truncateFile(atOffset: 0)

        return fileHandle
    }
}
