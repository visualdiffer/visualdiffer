//
//  FileSizeFormatter.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

@objc class FileSizeFormatter: NumberFormatter, @unchecked Sendable {
    private(set) var showInBytes = false
    private(set) var showUnitForBytes = true

    @objc static let `default` = FileSizeFormatter()

    @objc override init() {
        super.init()

        numberStyle = .decimal
        maximumFractionDigits = 2
    }

    @objc convenience init(
        showInBytes: Bool,
        showUnitForBytes: Bool
    ) {
        self.init()

        self.showInBytes = showInBytes
        self.showUnitForBytes = showUnitForBytes
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func string(
        from number: NSNumber,
        showInBytes: Bool,
        showUnitForBytes: Bool
    ) -> String? {
        var floatSize = number.doubleValue

        if floatSize < 1023 || showInBytes {
            if let value = super.string(from: NSNumber(value: floatSize)) {
                return String(format: "%@%@", value, showUnitForBytes ? " bytes" : "")
            }
            return "\(floatSize)"
        }

        floatSize /= 1024
        if floatSize < 1023 {
            if let value = super.string(from: NSNumber(value: floatSize)) {
                return String(format: "%@ KB", value)
            }
            return "\(floatSize)"
        }

        floatSize /= 1024
        if floatSize < 1023 {
            if let value = super.string(from: NSNumber(value: floatSize)) {
                return String(format: "%@ MB", value)
            }
            return "\(floatSize)"
        }

        floatSize /= 1024
        if let value = super.string(from: NSNumber(value: floatSize)) {
            return String(format: "%@ GB", value)
        }
        return "\(floatSize)"
    }

    override func string(from number: NSNumber) -> String? {
        string(from: number, showInBytes: showInBytes, showUnitForBytes: showUnitForBytes)
    }
}
