//
//  DualPaneSplitView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DualPaneSplitView: NSSplitView {
    var isSubviewCollapsed = false

    @objc var firstViewSize: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subviewResized),
            name: NSSplitView.didResizeSubviewsNotification,
            object: self
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subviewResized),
            name: NSSplitView.didResizeSubviewsNotification,
            object: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSSplitView.didResizeSubviewsNotification,
            object: self
        )
    }

    @objc func subviewResized(_ notification: Notification) {
        if hasSubviewCollapsed {
            return
        }
        guard let num = notification.userInfo?["NSSplitViewUserResizeKey"] as? NSNumber else {
            return
        }
        let isUserResize = num.boolValue
        if isUserResize {
            let view = subviews[0]
            firstViewSize = isVertical ? view.frame.width : view.frame.height
        }
    }

    @objc var hasSubviewCollapsed: Bool {
        if subviews.isEmpty {
            return true
        }
        for view in subviews where isSubviewCollapsed(view) {
            return true
        }
        return false
    }

    @objc func toggleSubview(at index: Int) {
        if hasSubviewCollapsed {
            expandSubview(at: index)
        } else {
            collapseSubview(at: index)
        }
    }

    @objc func collapseSubview(at index: Int) {
        if hasSubviewCollapsed {
            return
        }
        if index == 0 {
            let collapseView = subviews[0]
            collapseView.isHidden = true
            setPosition(0, ofDividerAt: 0)
        } else if index == 1 {
            let expandView = subviews[0]
            let collapseView = subviews[1]
            collapseView.isHidden = true
            let position = isVertical ? expandView.frame.width : expandView.frame.height
            setPosition(position, ofDividerAt: 0)
        } else {
            return
        }
        adjustSubviews()
    }

    @objc func expandSubview(at index: Int) {
        if !hasSubviewCollapsed {
            return
        }
        if index == 0 {
            let collapseView = subviews[0]
            collapseView.isHidden = false
            setPosition(firstViewSize, ofDividerAt: 0)
        } else if index == 1 {
            let collapseView = subviews[1]
            collapseView.isHidden = false
            setPosition(firstViewSize, ofDividerAt: 0)
        } else {
            return
        }
        adjustSubviews()
    }

    override var dividerThickness: CGFloat {
        hasSubviewCollapsed ? 0.0 : super.dividerThickness
    }
}
