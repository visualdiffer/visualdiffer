//
//  DiffResult+Dump.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

#if DEBUG

    import os.log

    extension DiffResult {
        func fullDump() {
            let home = URL(filePath: NSHomeDirectory())
            let fullPath = home.appendingPathComponent("diffResult.txt").osPath
            Logger.debug.info("Dump path: '\(fullPath)'")

            try? FileManager.default.removeItem(atPath: fullPath)
            var fileHandle = FileHandle(forWritingAtPath: fullPath)

            if fileHandle == nil {
                FileManager.default.createFile(atPath: fullPath, contents: nil, attributes: nil)
                fileHandle = FileHandle(forWritingAtPath: fullPath)
            }
            guard let fileHandle else {
                Logger.debug.error("Unable to open file ' \(fullPath)'")
                return
            }
            defer {
                fileHandle.closeFile()
            }

            dump(fileHandle)
            Logger.debug.info("Dump completed")
        }

        static func writeLine(_ fileHandle: FileHandle, line: String) {
            if let data = String(format: "%@\n", line).data(using: .ascii) {
                fileHandle.write(data)
            }
        }

        func dump(_ fileHandle: FileHandle) {
            summary.dump(fileHandle)

            DiffResult.writeLine(fileHandle, line: "leftSide")
            leftSide.dump(fileHandle)

            DiffResult.writeLine(fileHandle, line: "rightSide")
            rightSide.dump(fileHandle)

            DiffResult.writeLine(fileHandle, line: "sections")
            for section in sections {
                section.dump(fileHandle)
            }
        }
    }

    extension DiffSummary {
        func dump(_ fileHandle: FileHandle) {
            DiffResult.writeLine(fileHandle, line: "matching = \(matching)")
            DiffResult.writeLine(fileHandle, line: "changed = \(changed)")
            DiffResult.writeLine(fileHandle, line: "deleted = \(deleted)")
            DiffResult.writeLine(fileHandle, line: "added = \(added)")
        }
    }

    extension DiffSide {
        func dump(_ fileHandle: FileHandle) {
            DiffResult.writeLine(fileHandle, line: "eof = \(eol)")

            for line in lines {
                line.dump(fileHandle)
            }
        }
    }

    extension DiffLine {
        func dump(_ fileHandle: FileHandle) {
            DiffResult.writeLine(fileHandle, line: "type = \(type) number = \(number) mode = \(mode)")
//        DiffResult.writeLine(fileHandle, line: "text = \(text)")
            DiffResult.writeLine(fileHandle, line: "isSectionSeparator = \(isSectionSeparator) filteredIndex = \(filteredIndex)")
        }
    }

    extension DiffSection {
        func dump(_ fileHandle: FileHandle) {
            DiffResult.writeLine(fileHandle, line: "start = \(start) end = \(end)")
        }
    }
#endif
