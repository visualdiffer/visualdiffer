//
//  BaseTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/02/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

enum TestError: Error {
    case onlySetup
}

open class BaseTests {
    public var rootDir: URL
    public var dateBuilder = DateBuilder()
    public var className: String
    // swiftlint:disable:next line_length
    public let defaultPredicate = NSPredicate(format: "fileName == \".DS_Store\" OR fileName LIKE \"CVS\" OR fileName LIKE \".svn\" OR fileName LIKE \".git\" OR fileName LIKE \".hg\" OR fileName LIKE \".bzr\" OR fileName LIKE \"*~\" OR fileName ENDSWITH \".zip\" OR fileName ENDSWITH \".gz\" OR fileName ENDSWITH \".tgz\" OR fileName ENDSWITH \".tar\"")
    public let fm = FileManager.default

    public init(rootDir: URL) {
        className = String(describing: Self.self)
        self.rootDir = rootDir.appending(path: className, directoryHint: .isDirectory)
    }

    public convenience init() {
        self.init(rootDir: URL
            .desktopDirectory
            .appending(path: "visualdiffer/test_suite_swift/", directoryHint: .isDirectory))
    }

    public func buildDate(_ strDate: String) throws -> Date {
        try dateBuilder.isoDate(strDate)
    }
}
