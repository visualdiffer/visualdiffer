//
//  CompareUtil.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/01/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

public func compareTextFiles(
    _ lhs: URL,
    _ rhs: URL,
    _ encoding: String.Encoding,
    _ bufferSize: Int,
    _ isRunning: () -> Bool
) throws -> ComparisonResult {
    let leftBis = try BufferedInputStream(
        url: lhs,
        encoding: encoding,
        bufferSize: bufferSize
    )
    defer {
        leftBis.close()
    }

    let rightBis = try BufferedInputStream(
        url: rhs,
        encoding: encoding,
        bufferSize: bufferSize
    )

    defer {
        rightBis.close()
    }

    leftBis.open()
    rightBis.open()

    var ret: ComparisonResult = .orderedSame
    var eof = false

    repeat {
        autoreleasepool {
            ret = compareLine(leftBis, rightBis, &eof)
        }
    } while !eof && ret == .orderedSame && isRunning()

    return ret
}

func compareLine(
    _ leftBis: BufferedInputStream,
    _ rightBis: BufferedInputStream,
    _ eof: inout Bool
) -> ComparisonResult {
    let leftLine = leftBis.readLine()
    let rightLine = rightBis.readLine()
    if let leftLine,
       let rightLine {
        return leftLine.compare(rightLine)
    }
    eof = true
    if leftLine == nil, rightLine == nil {
        return .orderedSame
    }
    if leftLine == nil {
        return .orderedAscending
    }
    return .orderedDescending
}

public func compareDates(
    _ lhs: Date,
    _ rhs: Date,
    _ timestampToleranceSeconds: Int
) -> ComparisonResult {
    let interval = Int(lhs.timeIntervalSince(rhs))

    if interval == 0 || (-timestampToleranceSeconds <= interval && interval <= timestampToleranceSeconds) {
        return .orderedSame
    }
    return interval < 0 ? .orderedAscending : .orderedDescending
}

func compareData(_ lhs: Data, _ rhs: Data) -> ComparisonResult {
    let lCount = lhs.count
    let rCount = rhs.count

    return lhs.withUnsafeBytes { lBytes in
        rhs.withUnsafeBytes { rBytes in
            var ret = memcmp(lBytes.baseAddress, rBytes.baseAddress, min(lCount, rCount))
            if ret == 0, lCount != rCount {
                ret = lCount < rCount ? 1 : -1
            }
            // normalize to ComparisonResult value
            if ret < 0 {
                return .orderedAscending
            } else if ret > 0 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }
}

public func compareBinaryFiles(
    _ left: URL,
    _ right: URL,
    _ bufferSize: Int,
    _ isRunning: () -> Bool
) throws -> ComparisonResult {
    let leftFile = try FileHandle(forReadingFrom: left)

    defer {
        leftFile.closeFile()
    }

    let rightFile = try FileHandle(forReadingFrom: right)

    defer {
        rightFile.closeFile()
    }

    var result: ComparisonResult = .orderedSame

    repeat {
        if let leftData = try? leftFile.read(upToCount: bufferSize),
           let rightData = try? rightFile.read(upToCount: bufferSize) {
            if leftData.isEmpty || rightData.isEmpty {
                break
            }
            result = compareData(leftData, rightData)
        } else {
            break
        }
    } while result == .orderedSame && isRunning()

    return result
}
