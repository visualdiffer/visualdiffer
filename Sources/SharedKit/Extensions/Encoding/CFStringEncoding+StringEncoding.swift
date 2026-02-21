//
//  CFStringEncoding+StringEncoding.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

let noStringEncoding = String.Encoding(rawValue: UInt.max - 1)

extension CFStringEncoding {
    @inline(__always)
    var stringEncoding: String.Encoding? {
        let nsEncoding = CFStringConvertEncodingToNSStringEncoding(self)
        if nsEncoding == kCFStringEncodingInvalidId {
            return nil
        }
        return String.Encoding(rawValue: nsEncoding)
    }
}

extension CFStringEncodings {
    @inline(__always)
    var stringEncoding: String.Encoding? {
        CFStringEncoding(rawValue).stringEncoding
    }
}
