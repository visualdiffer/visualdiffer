//
//  String+Path.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

extension String {
    func isAbsolutePath() -> Bool {
        hasPrefix("/")
    }

    /**
     * No native valid alteratives to the NSString version
     */
    var standardizingPath: String {
        (self as NSString).standardizingPath
    }
}
