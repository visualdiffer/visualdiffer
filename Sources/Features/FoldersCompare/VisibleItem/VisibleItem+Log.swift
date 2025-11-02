//
//  VisibleItem+Log.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/02/25.
//  Copyright (c) 2025 visualdiffer.com
//

#if DEBUG

    import os.log

    extension VisibleItem {
        // periphery:ignore
        func log(indent: Int) {
            let line = String(format: "%*c%@         %@", indent, " ", item.fileName ?? "", item.linkedItem?.fileName ?? "")
            Logger.debug.info("\(line)")

            for vi in children {
                vi.log(indent: indent + 2)
            }
        }

        func writelog(
            _ fileHandle: FileHandle,
            indent: Int
        ) {
            let spaces = String(repeating: " ", count: indent)
            let line = String(
                format: "%@ %@         %@ %@",
                spaces,
                item.fileName ?? "",
                item.summary.description,
                item.linkedItem?.fileName ?? "",
                item.linkedItem?.summary.description ?? ""
            )

            Self.writeLine(fileHandle, line: line)

            for vi in children {
                vi.writelog(fileHandle, indent: indent + 2)
            }
        }

        // periphery:ignore
        static func writeLine(_ fileHandle: FileHandle, line: String) {
            if let data = String(format: "%@\n", line).data(using: .ascii) {
                fileHandle.write(data)
            }
        }
    }
#endif
