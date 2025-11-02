//
//  EncodingPopUpButtonCell.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/10/25.
//  Copyright (c) 2025 visualdiffer.com
//

private let wantsAutomaticTag = -1

class EncodingPopUpButtonCell: NSPopUpButtonCell {
    override init(textCell stringValue: String, pullsDown pullDown: Bool) {
        super.init(textCell: stringValue, pullsDown: pullDown)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(encodingsListChanged),
            name: EncodingManager.listNotification,
            object: nil
        )
        EncodingManager.shared.setupPopUpCell(
            self,
            selectedEncoding: noStringEncoding,
            withDefaultEntry: false
        )
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(encodingsListChanged),
            name: EncodingManager.listNotification,
            object: nil
        )
        EncodingManager.shared.setupPopUpCell(
            self,
            selectedEncoding: noStringEncoding,
            withDefaultEntry: false
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     * Do not allow selecting the "Customize" item and the separator before it.
     * (Note that the customize item can be chosen and an action will be sent, but the selection doesn't change to it.)
     */
    override func selectItem(at index: Int) {
        if index + 2 <= numberOfItems {
            super.selectItem(at: index)
        }
    }

    @objc func encodingsListChanged(_: Notification) {
        let encoding = if let value = selectedItem?.representedObject as? NSNumber {
            String.Encoding(rawValue: value.uintValue)
        } else {
            noStringEncoding
        }
        EncodingManager.shared.setupPopUpCell(
            self,
            selectedEncoding: encoding,
            withDefaultEntry: numberOfItems > 0 && item(at: 0)?.tag == wantsAutomaticTag
        )
    }
}
