//
//  NSProgressIndicator+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSProgressIndicator {
    static func bar() -> NSProgressIndicator {
        let view = NSProgressIndicator()

        view.isIndeterminate = false
        view.minValue = 0
        view.maxValue = 0
        view.doubleValue = 0
        view.controlSize = .regular
        view.style = .bar

        return view
    }
}
