//
//  DisplayFiltersPopUpButtonCell.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

class DisplayFiltersPopUpButtonCell: NSPopUpButtonCell {
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

        addItem(withTitle: NSLocalizedString("Show All", comment: ""))
        lastItem?.tag = DisplayOptions.showAll.rawValue

        addItem(withTitle: NSLocalizedString("Only Mismatches", comment: ""))
        lastItem?.tag = DisplayOptions.onlyMismatches.rawValue

        addItem(withTitle: NSLocalizedString("Only Matches", comment: ""))
        lastItem?.tag = DisplayOptions.onlyMatches.rawValue

        addItem(withTitle: NSLocalizedString("No Orphans", comment: ""))
        lastItem?.tag = DisplayOptions.noOrphan.rawValue

        addItem(withTitle: NSLocalizedString("Only Orphans", comment: ""))
        lastItem?.tag = DisplayOptions.onlyOrphans.rawValue
    }
}
