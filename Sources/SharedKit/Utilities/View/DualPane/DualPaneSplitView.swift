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

    // the collapsed state is owned by the app through isHidden because
    // NSSplitView.isSubviewCollapsed(_:) reports true also for a pane not laid out yet
    @objc var hasSubviewCollapsed: Bool {
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
        }
    }

    @objc
    func toggleSubview(at index: Int) {
        if hasSubviewCollapsed {
            expandSubview(at: index)
        } else {
            collapseSubview(at: index)
        }
    }

    @objc
    func collapseSubview(at index: Int) {
        let collapseView = subviews[index]
        if collapseView.isHidden {
            return
        }
        collapseView.isHidden = true
        adjustSubviews()
    }

    @objc
    func expandSubview(at index: Int) {
        let expandView = subviews[index]
        if !expandView.isHidden {
            return
        }
        expandView.isHidden = false
        // the position is derived from the current size and kept inside the
        // range allowed by the delegate, otherwise NSSplitView collapses the pane again
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
