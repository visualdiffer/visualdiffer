//
//  NSToolbar+Create.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

class SegmentedToolbarItemGroup: NSToolbarItemGroup {
    @objc
    func performSegmentAction(_ sender: NSSegmentedControl) {
        let item = subitems[sender.selectedSegment]
        if let action = item.action {
            NSApp.sendAction(action, to: item.target, from: item)
        }
    }

    override func validate() {
        guard let control = view as? NSSegmentedControl else {
            return
        }

        // let each subitem run the standard target/action validation and mirror the result on its segment
        for (index, item) in subitems.enumerated() {
            item.validate()
            control.setEnabled(item.isEnabled, forSegment: index)
        }
    }
}

@objc
extension NSToolbar {
    convenience init(identifier: String, delegate dele: NSToolbarDelegate) {
        self.init(identifier: identifier)

        displayMode = .iconAndLabel
        allowsUserCustomization = true
        autosavesConfiguration = true
        delegate = dele
    }
}

extension NSToolbar {
    func makeSegmentedItemGroup(
        identifier: NSToolbarItem.Identifier,
        label: String,
        subitemIdentifiers: [NSToolbarItem.Identifier],
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItemGroup {
        let group = SegmentedToolbarItemGroup(itemIdentifier: identifier)
        group.label = label
        group.paletteLabel = label
        group.subitems = subitemIdentifiers.compactMap {
            delegate?.toolbar?(self, itemForItemIdentifier: $0, willBeInsertedIntoToolbar: flag)
        }

        // segment indices must stay aligned with subitems, so every subitem needs an image,
        // otherwise performSegmentAction and validate would map to the wrong segment
        let images = group.subitems.compactMap(\.image)
        precondition(
            images.count == group.subitems.count,
            "each segmented subitem must provide an image"
        )

        let segmented = NSSegmentedControl(
            images: images,
            trackingMode: .momentary,
            target: group,
            action: #selector(SegmentedToolbarItemGroup.performSegmentAction)
        )
        segmented.segmentStyle = .separated
        for (index, item) in group.subitems.enumerated() {
            segmented.setToolTip(item.toolTip, forSegment: index)
        }
        group.view = segmented

        return group
    }
}
