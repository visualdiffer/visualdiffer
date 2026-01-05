//
//  BufferedInputStream.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/07/14.
//  Copyright (c) 2014 visualdiffer.com
//

import Foundation
import AppKit

/// A line-by-line `InputStream` supporting `\n`, `\r`, and `\r\n` terminators.
// swiftlint:disable force_unwrapping
public class BufferedInputStream: InputStream {
    public enum Constants {
        public static let invalidated = -2
        public static let unmarked = -1
        public static let defaultCharBufferSize = 8192
        public static let defaultExpectedLineLength = 80
    }

    // The decorated stream
    private var stream: InputStream
    // The size of each chunk read from the stream into memory
    private var bufferSize: Int = 0
    // The encoding of the text represented by the underlying stream
    private var encoding: String.Encoding

    // Buffer containing the bytes of the current chunk read from the stream
    private var dataBuffer: [UInt8] = []
    private var dataBufferLen: Int = 0

    // Whether the stream was opened by this decorator and should therefore be closed with it
    private var shouldCloseStream = false

    private var skipLF = false
    private var nextChar = 0
    private var nChars = 0
    private var markedChar = Constants.unmarked
    private var readAheadLimit = 0

    /**
     * if using the object encoding doesn't create a valid string
     * then try to determine the best one
     */
    private let detectBestEncoding: Bool

    public init(
        stream: InputStream,
        encoding: String.Encoding,
        bufferSize: Int,
        detectBestEncoding: Bool = false
    ) {
        self.stream = stream
        self.encoding = encoding
        self.bufferSize = bufferSize
        self.detectBestEncoding = detectBestEncoding

        super.init()
    }

    public convenience init(
        url: URL,
        encoding: String.Encoding,
        bufferSize: Int = Constants.defaultCharBufferSize,
        detectBestEncoding: Bool = false
    ) throws {
        if let stream = InputStream(url: url) {
            self.init(
                stream: stream,
                encoding: encoding,
                bufferSize: bufferSize,
                detectBestEncoding: detectBestEncoding
            )
            shouldCloseStream = true
        } else {
            throw FileError.openFile(path: url.osPath)
        }
    }

    // MARK: read methods

    func readLine(ignoreLF: Bool = false) -> String? {
        var line: String?
        if let data = readLineAsData(ignoreLF: ignoreLF) {
            // we can't use the native Swift String(data:encoding) because the results are different
            // For example
            // let data: Data = Data([0x62, 0x70, 0x6c, 0x69, 0x73, 0x74, 0x30, 0x30, 0xd4, 0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x05])
            // let swiftString = String(data: data, encoding: .ascii)
            // let nsString = NSString(data: data, encoding: String.Encoding.ascii.rawValue)
            // swiftString is nil but nsString is not nil
            line = NSString(data: data, encoding: encoding.rawValue) as String?
            if line == nil, detectBestEncoding {
                line = lineWithBestEncoding(data: data)
            }
        }

        return line
    }

    private func lineWithBestEncoding(data: Data) -> String? {
        if let line = String(data: data, encoding: String.Encoding.windowsCP1252) {
            encoding = String.Encoding.windowsCP1252
            return line as String
        }
        // use NSAttributedString to detect best encoding
        var docAttrs = NSDictionary()
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.plain,
        ]
        do {
            let line = try withUnsafeMutablePointer(to: &docAttrs) { docAttrsPointer in
                try NSAttributedString(
                    data: data,
                    options: options,
                    documentAttributes: AutoreleasingUnsafeMutablePointer(docAttrsPointer)
                ).string
            }

            if let val = docAttrs[NSAttributedString.DocumentAttributeKey.characterEncoding] as? NSNumber {
                encoding = String.Encoding(rawValue: val.uintValue)
            }
            return line
        } catch {}
        return nil
    }

    public func readLineAsData(ignoreLF: Bool = false) -> Data? {
        var data: Data?
        var startChar = 0

        var omitLF = ignoreLF || skipLF

        while true {
            if nextChar >= nChars {
                fill()
            }
            if nextChar >= nChars { // EOF
                if let data, !data.isEmpty {
                    return data
                } else {
                    return nil
                }
            }
            var eol = false
            var chInt: UInt8 = 0
            // Skip a leftover '\n', if necessary
            if omitLF, dataBuffer[nextChar] == 0x0A {
                nextChar += 1
            }
            skipLF = false
            omitLF = false
            var i = nextChar
            while i < nChars {
                chInt = dataBuffer[i]
                if (chInt == 0x0A) || (chInt == 0x0D) {
                    eol = true
                    break
                }
                i += 1
            }
            startChar = nextChar
            nextChar = i
            if eol {
                dataBuffer.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                    let ptr = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self).advanced(by: startChar)
                    if data == nil {
                        data = Data(bytes: ptr, count: i - startChar)
                    } else {
                        data!.append(ptr, count: i - startChar)
                    }
                }

                nextChar += 1
                if chInt == 0x0D {
                    skipLF = true
                }
                return data
            }
            if data == nil {
                data = Data(capacity: Constants.defaultExpectedLineLength)
            }
            dataBuffer.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                let ptr = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self).advanced(by: startChar)
                data!.append(ptr, count: i - startChar)
            }
        }
    }

    private func fill() {
        var dst = 0
        if markedChar <= Constants.unmarked {
            // No mark
            dst = 0
        } else {
            // Marked
            let delta = nextChar - markedChar
            if delta >= readAheadLimit {
                // Gone past read-ahead limit: Invalidate mark
                markedChar = Constants.invalidated
                readAheadLimit = 0
                dst = 0
            } else {
                if readAheadLimit <= dataBufferLen {
                    // Shuffle in the current buffer
                    dataBuffer.replaceSubrange(markedChar ..< delta, with: dataBuffer)
                    markedChar = 0
                    dst = delta
                } else {
                    var ncb = [UInt8](repeating: 0, count: readAheadLimit)
                    ncb.replaceSubrange(markedChar ..< delta, with: dataBuffer)
                    // Reallocate buffer to accommodate read-ahead limit
                    dataBuffer = ncb
                    dataBufferLen = readAheadLimit
                    markedChar = 0
                    dst = delta
                }
                nChars = delta
                nextChar = delta
            }
        }

        let bytesRead = dataBuffer.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) -> Int in
            let ptr = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self).advanced(by: dst)
            return stream.read(ptr, maxLength: dataBufferLen - dst)
        }

        if bytesRead > 0 {
            nChars = dst + bytesRead
            nextChar = dst
        }
    }

    // MARK: NSInputStream methods

    override public func open() {
        shouldCloseStream = stream.streamStatus == Stream.Status.notOpen
        if shouldCloseStream {
            // If the underlying stream is not already open, we open it ourselves
            // and we will close it when the decorator is closed
            stream.open()
        }
        dataBuffer = [UInt8](repeating: 0, count: bufferSize)
        dataBufferLen = bufferSize

        skipLF = false
        nChars = 0
        nextChar = 0
        markedChar = Constants.unmarked
        readAheadLimit = 0
    }

    override public var hasBytesAvailable: Bool {
        stream.hasBytesAvailable
    }

    public func getBuffer(buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        stream.getBuffer(buffer, length: len)
    }

    override public func close() {
        if shouldCloseStream {
            // Close the underlying stream if is was opened by this decorator
            stream.close()
        }
    }
}

// swiftlint:enable force_unwrapping
