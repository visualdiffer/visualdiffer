//
//  FileSizeFormatter.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

@objc
class FileSizeFormatter: NumberFormatter, @unchecked Sendable {
    private(set) var showInBytes = false
    private(set) var showUnitForBytes = true
    private(set) var useGibiBytes = false

    @objc static let `default` = FileSizeFormatter()

    @objc
    override init() {
        super.init()

        numberStyle = .decimal
        maximumFractionDigits = 2
    }

    @objc
    convenience init(
        showInBytes: Bool,
        showUnitForBytes: Bool,
        useGibiBytes: Bool = false
    ) {
        self.init()

        self.showInBytes = showInBytes
        self.showUnitForBytes = showUnitForBytes
        self.useGibiBytes = useGibiBytes
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func string(
        from number: NSNumber,
        showInBytes: Bool,
        showUnitForBytes: Bool,
        useGibiBytes: Bool = false
    ) -> String? {
        var floatSize = number.doubleValue
        let divider: Double = useGibiBytes ? 1024 : 1000
        let unitThreshold = divider - 1

        if floatSize < unitThreshold || showInBytes {
            if let value = super.string(from: NSNumber(value: floatSize)) {
                return String(format: "%@%@", value, showUnitForBytes ? " bytes" : "")
            }
            return "\(floatSize)"
        }

        floatSize /= divider
        if floatSize < unitThreshold {
            if let value = super.string(from: NSNumber(value: floatSize)) {
                return String(format: "%@ KB", value)
            }
            return "\(floatSize)"
        }

        floatSize /= divider
        if floatSize < unitThreshold {
            if let value = super.string(from: NSNumber(value: floatSize)) {
                return String(format: "%@ MB", value)
            }
            return "\(floatSize)"
        }

        floatSize /= divider
        if let value = super.string(from: NSNumber(value: floatSize)) {
            return String(format: "%@ GB", value)
        }
        return "\(floatSize)"
    }

    override func string(from number: NSNumber) -> String? {
        string(
            from: number,
            showInBytes: showInBytes,
            showUnitForBytes: showUnitForBytes,
            useGibiBytes: useGibiBytes
        )
    }
}
