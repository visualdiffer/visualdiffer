//
//  FilesWindowController+Read.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor
extension FilesWindowController {
    @objc
    func startComparison() {
        reloadAllMove(toFirstDifference: true)
    }

    func reloadAllMove(toFirstDifference moveToFirstDifference: Bool) {
        do {
            resolvedLeftPath = nil
            resolvedRightPath = nil
            let (leftURL, leftLines) = try readDiffSource(for: .left)
            let (rightURL, rightLines) = try readDiffSource(for: .right)
            resolvedLeftPath = leftURL
            resolvedRightPath = rightURL
            let isSameResolvedPath = resolvedLeftPath != nil && resolvedLeftPath == resolvedRightPath

            leftPanelView.isEditAllowed = !isSameResolvedPath
            rightPanelView.isEditAllowed = !isSameResolvedPath

            compare(
                leftLines: leftLines,
                rightLines: rightLines,
                moveToFirstDifference: moveToFirstDifference
            )
        } catch let error as NSError {
            showError(error)
            return
        }
    }

    func compare(
        leftLines: [DiffLineComponent],
        rightLines: [DiffLineComponent],
        moveToFirstDifference: Bool
    ) {
        let newDiffResult = DiffResult()

        diffResult = newDiffResult
        currentDiffResult = nil

        newDiffResult.diff(
            leftLines: leftLines,
            rightLines: rightLines,
            options: preferences.diffResultOptions
        )
        setSliderMaxValue()
        differenceCounters.update(counters: DiffCountersItem.diffCounter(withResult: newDiffResult))
        refreshLinesStatus()

        // update eol for files
        leftPanelView.fileInfoBar.eol = newDiffResult.leftSide.eol
        rightPanelView.fileInfoBar.eol = newDiffResult.rightSide.eol

        // force toolbar to enable items
        window?.toolbar?.validateVisibleItems()

        synchronizeWindowTitleWithDocumentName()

        leftView.deselectAll(nil)
        rightView.deselectAll(nil)

        if moveToFirstDifference {
            moveToDifference(true, showAnim: false)
        }

        reloadRowHeights()
    }

    func showError(_ error: NSError) {
        guard let window else {
            return
        }
        let alert = NSAlert(error: error)

        alert.beginSheetModal(for: window)
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
}
