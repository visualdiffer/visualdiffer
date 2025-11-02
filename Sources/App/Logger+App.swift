//
//  Logger+App.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os.log

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "visualdiffer"

    static let general = Logger(subsystem: subsystem, category: "General")
    static let ui = Logger(subsystem: subsystem, category: "UI") // swiftlint:disable:this identifier_name
    static let fs = Logger(subsystem: subsystem, category: "FileSystem") // swiftlint:disable:this identifier_name

    #if DEBUG
        static let debug = Logger(subsystem: subsystem, category: "Debug")
    #endif
}
