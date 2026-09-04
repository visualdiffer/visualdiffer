//
//  DualPaneSplitView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

// size used until the user resizes the collapsable pane
private let defaultCollapsablePaneSize: CGFloat = 120

private let userResizeKey = "NSSplitViewUserResizeKey"

class DualPaneSplitView: NSSplitView {
    var collapsablePaneSize: CGFloat = defaultCollapsablePaneSize

    // the paired split view is not retained, the view hierarchy keeps it alive
    private weak var synchronizedSplitView: DualPaneSplitView?

    // the collapsed state is owned by the app through isHidden because
    // NSSplitView.isSubviewCollapsed(_:) reports true also for a pane not laid out yet
    var hasSubviewCollapsed: Bool {
        subviews.isEmpty || subviews.contains { $0.isHidden }
    }

    // the collapsable pane is the one the delegate allows to collapse
    private var collapsablePaneIndex: Int? {
        subviews.firstIndex { delegate?.splitView?(self, canCollapseSubview: $0) == true }
    }

    override var dividerThickness: CGFloat {
        hasSubviewCollapsed ? 0.0 : super.dividerThickness
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        observeUserResize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observeUserResize()
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSSplitView.didResizeSubviewsNotification,
            object: self
        )
    }

    @objc
    func subviewResized(_ notification: Notification) {
        // only a manual drag defines the size to remember; on a window
        // resize NSSplitView scales the panes proportionally and that size is not a user choice
        guard let userResize = notification.userInfo?[userResizeKey] as? NSNumber,
              userResize.boolValue,
              !hasSubviewCollapsed,
              let index = collapsablePaneIndex else {
            return
        }

        let currentSize = paneSize(of: subviews[index])
        if currentSize > 0 {
            collapsablePaneSize = currentSize
            synchronizedSplitView?.matchCollapsablePaneSize(currentSize)
        }
    }

    /**
     Pair the split view with another one so they collapse, expand and resize together
     self is paired with other and other is paired with self, too
     */
    func setSynchronized(splitView: DualPaneSplitView) {
        synchronizedSplitView = splitView
        splitView.synchronizedSplitView = self
    }

    func toggleSubview() {
        if hasSubviewCollapsed {
            expandSubview()
        } else {
            collapseSubview()
        }
    }

    func collapseSubview() {
        guard let index = collapsablePaneIndex else {
            return
        }

        let collapseView = subviews[index]

        // returning when already collapsed also stops the pair from calling back
        if collapseView.isHidden {
            return
        }
        collapseView.isHidden = true
        adjustSubviews()
        // force a layout pass so AppKit removes the collapsed divider layer
        needsLayout = true
        synchronizedSplitView?.collapseSubview()
    }

    func expandSubview() {
        guard let index = collapsablePaneIndex else {
            return
        }

        let expandView = subviews[index]

        // returning when already expanded also stops the pair from calling back
        if !expandView.isHidden {
            return
        }
        expandView.isHidden = false
        moveDivider(collapsableIndex: index)
        synchronizedSplitView?.expandSubview()
    }

    // applies the size the paired split view got from the user, the comparison
    // stops the pair from bouncing the change back
    private func matchCollapsablePaneSize(_ size: CGFloat) {
        guard !hasSubviewCollapsed,
              let index = collapsablePaneIndex,
              paneSize(of: subviews[index]) != size else {
            return
        }

        collapsablePaneSize = size
        moveDivider(collapsableIndex: index)
    }

    // the position is derived from the current size and kept inside the
    // range allowed by the delegate, otherwise NSSplitView collapses the pane again
    private func moveDivider(collapsableIndex index: Int) {
        let available = paneSize(of: self)
        let position = index == 0 ? collapsablePaneSize : available - collapsablePaneSize - dividerThickness

        setPosition(constrain(position: position, available: available), ofDividerAt: 0)
        adjustSubviews()
    }

    private func observeUserResize() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subviewResized),
            name: NSSplitView.didResizeSubviewsNotification,
            object: self
        )
    }

    private func paneSize(of view: NSView) -> CGFloat {
        isVertical ? view.frame.width : view.frame.height
    }

    private func constrain(position: CGFloat, available: CGFloat) -> CGFloat {
        let minPosition = delegate?.splitView?(self, constrainMinCoordinate: 0, ofSubviewAt: 0) ?? 0
        let maxPosition = delegate?.splitView?(self, constrainMaxCoordinate: available, ofSubviewAt: 0) ?? available

        return min(max(position, minPosition), maxPosition)
    }
}
