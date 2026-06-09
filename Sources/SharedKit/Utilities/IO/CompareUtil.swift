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

    var result = ComparisonResult.orderedSame
    var eof = false

    repeat {
        autoreleasepool {
            (eof, result) = compareLine(leftBis, rightBis)
        }
    } while !eof && result == .orderedSame && isRunning()

    return result
}

func compareLine(
    _ leftBis: BufferedInputStream,
    _ rightBis: BufferedInputStream
) -> (eof: Bool, result: ComparisonResult) {
    let leftLine = leftBis.readLine()
    let rightLine = rightBis.readLine()
    if let leftLine,
       let rightLine {
        return (false, leftLine.compare(rightLine))
    }
    if leftLine == nil, rightLine == nil {
        return (true, .orderedSame)
    }
    if leftLine == nil {
        return (true, .orderedAscending)
    }
    return (true, .orderedDescending)
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

    var result = ComparisonResult.orderedSame
    var eof = false

    repeat {
        autoreleasepool {
            (eof, result) = compareBinaryChunk(leftFile, rightFile, bufferSize)
        }
    } while !eof && result == .orderedSame && isRunning()

    return result
}

private func compareBinaryChunk(
    _ leftFile: FileHandle,
    _ rightFile: FileHandle,
    _ bufferSize: Int
) -> (eof: Bool, result: ComparisonResult) {
    guard let leftData = try? leftFile.read(upToCount: bufferSize),
          let rightData = try? rightFile.read(upToCount: bufferSize),
          !leftData.isEmpty,
          !rightData.isEmpty else {
        return (true, .orderedSame)
    }

    return (false, compareData(leftData, rightData))
}
