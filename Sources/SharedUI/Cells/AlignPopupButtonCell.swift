//
//  AlignPopupButtonCell.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

class AlignPopupButtonCell: NSPopUpButtonCell {
    override init(textCell stringValue: String, pullsDown pullDown: Bool) {
        super.init(textCell: stringValue, pullsDown: pullDown)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    private func setupViews() {
        removeAllItems()

        addItem(withTitle: NSLocalizedString("Match File Name Case", comment: ""))
        lastItem?.tag = ComparatorOptions.alignMatchCase.rawValue

        addItem(withTitle: NSLocalizedString("Ignore File Name Case", comment: ""))
        lastItem?.tag = ComparatorOptions.alignIgnoreCase.rawValue

        addItem(withTitle: NSLocalizedString("Use Filesystem Case", comment: ""))
        lastItem?.tag = ComparatorOptions.alignFileSystemCase.rawValue
    }
}
