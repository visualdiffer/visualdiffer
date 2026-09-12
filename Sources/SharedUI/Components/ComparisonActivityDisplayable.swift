//
//  ComparisonActivityDisplayable.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

// the status bar and the controls a running comparison takes over, shared by the file
// and the folder window so the two cannot drift apart again
@MainActor
protocol ComparisonActivityDisplayable: AnyObject {
    var differenceCounters: DifferenceCounters { get }
    var statusbarText: NSTextField { get }
    var progressView: ProgressBarView { get }
    var window: NSWindow? { get }

    var lockedScopeBar: ScopeBarView { get }
    var lockedPathViews: [PathView] { get }
}

extension ComparisonActivityDisplayable {
    // the progress replaces the counters and the status text while a comparison runs
    func setProgressHidden(_ hidden: Bool) {
        differenceCounters.isHidden = !hidden
        statusbarText.isHidden = !hidden
        progressView.isHidden = hidden
    }

    func setComparisonRunning(_ running: Bool) {
        setProgressHidden(!running)

        for pathView in lockedPathViews {
            pathView.isEnabled = !running
        }
        lockedScopeBar.setEnabledAllGroups(!running)

        // the toolbar is the only always visible validated control, it would otherwise
        // keep the items it draws until AppKit decides to validate again
        window?.toolbar?.validateVisibleItems()
    }
}
