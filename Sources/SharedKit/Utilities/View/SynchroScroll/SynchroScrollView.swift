//
//  SynchroScrollView.swift
//  VisualDiffer
//
//  Created by davide ficano on 05/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

@MainActor class SynchroScrollView: NSScrollView {
    private var synchronizedScrollView: NSScrollView? // not retained

    @objc func setSynchronized(scrollview: NSScrollView) {
        // stop an existing scroll view synchronizing
        stopSynchronizing()

        // don't retain the watched view, because we assume that it will
        // be retained by the view hierarchy for as long as we're around.
        synchronizedScrollView = scrollview

        // get the content view of the
        let synchronizedContentView = scrollview.contentView

        // Make sure the watched view is sending bounds changed
        // notifications (which is probably does anyway, but calling
        // this again won't hurt).
        scrollview.postsBoundsChangedNotifications = true

        // a register for those notifications on the synchronized content view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(synchronizedViewContentBoundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: synchronizedContentView
        )
    }

    @objc func synchronizedViewContentBoundsDidChange(_ notification: Notification) {
        // get the changed content view from the notification
        guard let changedContentView = notification.object as? NSClipView else {
            return
        }

        // get the origin of the NSClipView of the scroll view that
        // we're watching
        let changedBoundsOrigin = changedContentView.documentVisibleRect.origin

        // get our current origin
        let curOffset = contentView.bounds.origin
        var newOffset = curOffset

        // scrolling is synchronized in the vertical plane
        // so only modify the y component of the offset
        newOffset.y = changedBoundsOrigin.y

        // if our synced position is different from our current
        // position, reposition our content view

        if curOffset != changedBoundsOrigin {
            // note that a scroll view watching this one will
            // get notified here
            contentView.scroll(to: newOffset)

            // we have to tell the NSScrollView to update its
            // scrollers
            reflectScrolledClipView(contentView)
        }
    }

    func stopSynchronizing() {
        guard let synchronizedScrollView else {
            return
        }
        let synchronizedContentView = synchronizedScrollView.contentView

        // remove any existing notification registration
        NotificationCenter.default.removeObserver(
            self,
            name: NSView.boundsDidChangeNotification,
            object: synchronizedContentView
        )

        self.synchronizedScrollView = nil
    }
}
