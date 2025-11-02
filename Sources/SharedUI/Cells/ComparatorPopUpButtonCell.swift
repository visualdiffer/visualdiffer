//
//  ComparatorPopUpButtonCell.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

class ComparatorPopUpButtonCell: NSPopUpButtonCell {
    private var previousSelected: NSMenuItem?

    override init(textCell stringValue: String, pullsDown pullDown: Bool) {
        super.init(textCell: stringValue, pullsDown: pullDown)

        setupViews()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)

        setupViews()
    }

    override func selectItem(at index: Int) {
        if pullsDown {
            if let prevItem = previousSelected {
                prevItem.state = .off
            }

            if index >= 0, index < itemArray.count {
                itemArray[index].state = .on
                previousSelected = itemArray[index]
            }
        }
        super.selectItem(at: index)
    }

    private func setupViews() {
        let root = itemArray.first
        removeAllItems()

        if pullsDown {
            if let menu, let root {
                menu.addItem(root)
            }
        }

        let flags: [ComparatorOptions] = [
            .filename,
            .asText,
            .content,
            .size,
            .timestamp,
            [.timestamp, .size],
            [.timestamp, .content, .size],
        ]
        for flag in flags {
            addItem(withTitle: flag.description)
            lastItem?.tag = flag.rawValue
        }
    }
}
