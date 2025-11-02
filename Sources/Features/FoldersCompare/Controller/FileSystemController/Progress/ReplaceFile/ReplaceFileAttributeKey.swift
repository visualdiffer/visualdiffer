//
//  ReplaceFileAttributeKey.swift
//  VisualDiffer
//
//  Created by davide ficano on 19/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct ReplaceFileAttributeKey: Hashable, RawRepresentable {
    let rawValue: String

    static let fromPath = ReplaceFileAttributeKey(rawValue: "fromPath")
    static let fromSize = ReplaceFileAttributeKey(rawValue: "fromSize")
    static let fromDate = ReplaceFileAttributeKey(rawValue: "fromDate")
    static let toPath = ReplaceFileAttributeKey(rawValue: "toPath")
    static let toSize = ReplaceFileAttributeKey(rawValue: "toSize")
    static let toDate = ReplaceFileAttributeKey(rawValue: "toDate")
}

extension [ReplaceFileAttributeKey: Any] {
    var fromPath: String? { self[.fromPath] as? String }
    var fromSize: Int? { self[.fromSize] as? Int }
    var fromDate: Date? { self[.fromDate] as? Date }
    var toPath: String? { self[.toPath] as? String }
    var toSize: Int? { self[.toSize] as? Int }
    var toDate: Date? { self[.toDate] as? Date }
}
