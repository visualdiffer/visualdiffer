//
//  DualPaneSplitViewDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

class DualPaneSplitViewDelegate: NSObject, NSSplitViewDelegate {
    var minFirstPaneSize: CGFloat = 0
    var minSecondPaneSize: CGFloat = 0
    var collapsableSubviewIndex = 0

    @objc
    init(
        collapsableSubViewIndex index: Int,
        minFirstPaneSize: CGFloat,
        minSecondPaneSize: CGFloat
    ) {
        super.init()

        collapsableSubviewIndex = index
        self.minFirstPaneSize = minFirstPaneSize
        self.minSecondPaneSize = minSecondPaneSize
    }

    func splitView(_: NSSplitView, shouldHideDividerAt _: Int) -> Bool {
        true
    }

    func splitView(_: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        proposedMinimumPosition + minFirstPaneSize
    }

    func splitView(_: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        proposedMaximumPosition - minSecondPaneSize
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        subview == splitView.subviews[collapsableSubviewIndex]
    }
}
