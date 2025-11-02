//
//  DualPaneSplitViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

class DualPaneSplitViewDelegate: NSObject, NSSplitViewDelegate {
    var minSize: CGFloat = 0
    var maxSize: CGFloat = 0
    var collapsableSubviewIndex = 0

    @objc init(
        collapsableSubViewIndex index: Int,
        minSize: CGFloat,
        maxSize: CGFloat
    ) {
        super.init()

        collapsableSubviewIndex = index
        self.minSize = minSize
        self.maxSize = maxSize
    }

    func splitView(_: NSSplitView, shouldHideDividerAt _: Int) -> Bool {
        true
    }

    func splitView(_: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        proposedMinimumPosition + minSize
    }

    func splitView(_: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        proposedMaximumPosition - maxSize
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        subview == splitView.subviews[collapsableSubviewIndex]
    }
}
