//
//  FilesWindowController+Read.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor
extension FilesWindowController {
    func startComparison() {
        startReload(toFirstDifference: true)
    }

    // entry point for every caller, an AppKit action or a delegate
    //
    // the read runs inline: an action is dispatched while AppKit is still handling the
    // event, and a task created there does not start until that handling returns, which
    // after a double click takes hundreds of milliseconds
    //
    // `completion` runs once the result is installed, a request that is refused, queued
    // or whose read fails never calls it
    func startReload(
        toFirstDifference moveToFirstDifference: Bool,
        statusMessage: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        // the window can close between the request and the comparison, sessionDiff is
        // a managed object and its context goes away with the document
        if isClosed {
            return
        }

        // the caller may have already changed the paths or the options, dropping the
        // request would leave the views showing them next to the previous comparison
        if isComparing {
            var request = pendingReload ?? PendingReload()

            request.toFirstDifference = request.toFirstDifference || moveToFirstDifference
            request.statusMessage = statusMessage ?? request.statusMessage
            pendingReload = request

            return
        }

        beginCompare()

        // the read that fails is the last one started, its path completes the console message
        var readingPath = sessionDiff.leftPath ?? ""

        // the panels keep showing the previous comparison when a read throws
        let wasLeftDirty = leftView.isDirty
        let wasRightDirty = rightView.isDirty
        let wasLeftEditAllowed = leftPanelView.isEditAllowed
        let wasRightEditAllowed = rightPanelView.isEditAllowed
        let previousLeftPath = resolvedLeftPath
        let previousRightPath = resolvedRightPath

        do {
            resolvedLeftPath = nil
            resolvedRightPath = nil

            // the read lowers it for anything that is not plain text, it has to start
            // from a known state or an early return keeps the previous refusal forever
            leftPanelView.isEditAllowed = true
            rightPanelView.isEditAllowed = true

            showReading(path: readingPath)
            let (leftURL, leftLines) = try readDiffSource(for: .left)

            readingPath = sessionDiff.rightPath ?? ""
            showReading(path: readingPath)
            let (rightURL, rightLines) = try readDiffSource(for: .right)

            resolvedLeftPath = leftURL
            resolvedRightPath = rightURL

            let isSameResolvedPath = resolvedLeftPath != nil && resolvedLeftPath == resolvedRightPath

            // reading already refused the edit for anything that is not plain text,
            // comparing a file against itself can only forbid it further
            leftPanelView.isEditAllowed = leftPanelView.isEditAllowed && !isSameResolvedPath
            rightPanelView.isEditAllowed = rightPanelView.isEditAllowed && !isSameResolvedPath

            runComparison(
                leftLines: leftLines,
                rightLines: rightLines,
                moveToFirstDifference: moveToFirstDifference
            ) { [self] in
                completion?()

                // the message is set before the controls are released, a queued request
                // the release starts would otherwise find the counters already restored
                if let statusMessage {
                    showStatusMessage(statusMessage)
                }
            }
        } catch let error as NSError {
            // a queued request would read again the file that just failed
            pendingReload = nil

            // the panel whose read succeeded already cleared its
            // dirty flag and the edits it still shows are unreachable without it
            resolvedLeftPath = previousLeftPath
            resolvedRightPath = previousRightPath
            leftPanelView.isEditAllowed = wasLeftEditAllowed
            rightPanelView.isEditAllowed = wasRightEditAllowed
            leftView.isDirty = wasLeftDirty
            rightView.isDirty = wasRightDirty

            endCompare()
            log(error: error.format(withPath: readingPath))
        }
    }

    func compare(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        moveToFirstDifference: Bool,
        completion: (() -> Void)? = nil
    ) {
        if isClosed || isComparing {
            return
        }
        beginCompare()

        runComparison(
            leftLines: leftLines,
            rightLines: rightLines,
            moveToFirstDifference: moveToFirstDifference,
            completion: completion
        )
    }

    private func readDiffSource(
        for side: SessionDiff.Side
    ) throws -> (resolvedURL: URL?, lines: [DiffLineComponent]) {
        let path: String?
        let diffSide: DiffSide?
        let panel: FilePanelView

        switch side {
        case .left:
            path = sessionDiff.leftPath
            diffSide = diffResult?.leftSide
            panel = leftPanelView
        case .right:
            path = sessionDiff.rightPath
            diffSide = diffResult?.rightSide
            panel = rightPanelView
        }

        if let path,
           path.isEmpty {
            return (nil, diffSide?.nonMissingLineComponents() ?? [])
        }

        let resolvedURL = sessionDiff.resolvePath(
            for: side,
            chooseFileType: .file,
            alwaysResolveSymlinks: CommonPrefs.shared.alwaysResolveSymlinks
        )

        guard let resolvedURL else {
            return (nil, [])
        }

        let content = try panel.readFile(resolvedURL)
        let lines = DiffLineComponent.splitLines(content)

        return (resolvedURL, lines)
    }

    // shows the progress and locks the controls
    private func beginCompare() {
        isComparing = true
        comparisonStartedAt = Date()

        setComparisonRunning(true)
    }

    private func endCompare() {
        isComparing = false

        guard !isClosed,
              let pendingReload else {
            pendingReload = nil
            setComparisonRunning(false)
            return
        }

        self.pendingReload = nil

        // the queued comparison starts right away, unlocking here would blink the
        // counters back with the numbers of the one that just ended
        startReload(
            toFirstDifference: pendingReload.toFirstDifference,
            statusMessage: pendingReload.statusMessage
        )
    }

    private func runComparison(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        moveToFirstDifference: Bool,
        completion: (() -> Void)?
    ) {
        let newDiffResult = DiffResult(options: preferences.diffResultOptions)

        // the reading message belongs to the phase that is over, from here on the
        // progress is only the bar
        progressView.updateMessage("")
        updateProgress(percentage: 0)

        // the stream starts the comparison as it is created, so it is created here and
        // not inside the task, which is what waits for the event handling to return
        let progress = newDiffResult.diffDetached(
            leftLines: leftLines,
            rightLines: rightLines
        )

        Task {
            // the views keep showing the previous comparison, only the progress moves
            for await percentage in progress {
                updateProgress(percentage: percentage)
            }

            installComparison(
                newDiffResult,
                moveToFirstDifference: moveToFirstDifference,
                completion: completion
            )
        }
    }

    private func didCompare(
        _ newDiffResult: DiffResult,
        moveToFirstDifference: Bool
    ) {
        diffResult = newDiffResult
        currentDiffResult = nil

        // both hold lines of the comparison being replaced, the filtered result is only
        // reassigned when a line filter is active and the cache is keyed by line identity
        filteredDiffResult = nil
        cachedLineTextMap.removeAll()

        setSliderMaxValue()
        differenceCounters.update(counters: DiffCountersItem.diffCounter(withResult: newDiffResult))
        refreshLinesStatus()

        // update eol for files
        leftPanelView.fileInfoBar.eol = newDiffResult.leftSide.eol
        rightPanelView.fileInfoBar.eol = newDiffResult.rightSide.eol

        synchronizeWindowTitleWithDocumentName()
        window?.subtitle = preferences.diffResultOptions.description

        leftView.deselectAll(nil)
        rightView.deselectAll(nil)

        if moveToFirstDifference {
            // force layout before scrolling, this is necessary on some "slow" machine
            leftView.enclosingScrollView?.layoutSubtreeIfNeeded()
            rightView.enclosingScrollView?.layoutSubtreeIfNeeded()
            moveToDifference(true, showAnim: false, moveToFile: false)
        }
    }

    private func updateProgress(percentage: Int) {
        progressView.setProgress(
            position: Double(percentage),
            maxValue: Double(DiffProgress.maxPercentage)
        )
    }

    // reading a file blocks the main thread, so the message is drawn right away
    private func showReading(path: String?) {
        guard let path,
              !path.isEmpty else {
            return
        }

        progressView.displayMessage(String(format: NSLocalizedString("Reading %@", comment: ""), path))
    }

    // installs the result and releases the controls, the completion runs in between so
    // it sees the new rows while the controls are still locked
    private func installComparison(
        _ newDiffResult: DiffResult,
        moveToFirstDifference: Bool,
        completion: (() -> Void)?
    ) {
        guard !isClosed else {
            endCompare()
            return
        }

        // installing the result freezes the window for a while, the progress must still
        // be up there instead of a status bar that looks idle
        didCompare(newDiffResult, moveToFirstDifference: moveToFirstDifference)
        logComparisonCompleted(elapsedTimeText: Date().timeIntervalSince(comparisonStartedAt).format())
        completion?()

        endCompare()
    }
}
