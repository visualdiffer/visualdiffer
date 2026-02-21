//
//  NSTextField+CenterVertically.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

@objc
extension NSTextField {
    func centerVertically() {
        let centeredCell = RSVerticallyCenteredTextFieldCell(textCell: "")

        centeredCell.controlSize = .small
        centeredCell.isScrollable = true
        centeredCell.lineBreakMode = .byClipping
        centeredCell.alignment = .center

        cell = centeredCell
    }
}
