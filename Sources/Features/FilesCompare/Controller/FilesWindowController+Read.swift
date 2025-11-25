//
//  FilesWindowController+Read.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor extension FilesWindowController {
    @objc func startComparison() {
        reloadAllMove(toFirstDifference: true)
    }

    func reloadAllMove(toFirstDifference moveToFirstDifference: Bool) {
        resolvedLeftPath = sessionDiff.resolvePath(
            for: .left,
            chooseFileType: .file,
            alwaysResolveSymlinks: CommonPrefs.shared.alwaysResolveSymlinks
        )
        resolvedRightPath = sessionDiff.resolvePath(
            for: .right,
            chooseFileType: .file,
            alwaysResolveSymlinks: CommonPrefs.shared.alwaysResolveSymlinks
        )

        let leftContent: String
        let rightContent: String

        do {
            leftContent = if let resolvedLeftPath {
                try leftPanelView.readFile(resolvedLeftPath)
            } else {
                ""
            }
            rightContent = if let resolvedRightPath {
                try rightPanelView.readFile(resolvedRightPath)
            } else {
                ""
            }
        } catch let error as NSError {
            showError(error)
            return
        }

        if resolvedLeftPath != nil, resolvedLeftPath == resolvedRightPath {
            leftPanelView.isEditAllowed = false
            rightPanelView.isEditAllowed = false
        } else {
            leftPanelView.isEditAllowed = true
            rightPanelView.isEditAllowed = true
        }

        let newDiffResult = DiffResult()

        diffResult = newDiffResult
        currentDiffResult = nil

        newDiffResult.diff(leftText: leftContent, rightText: rightContent, options: preferences.diffResultOptions)
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
    }

    func showError(_ error: NSError) {
        guard let window else {
            return
        }
        let alert = NSAlert(error: error)

        alert.beginSheetModal(for: window)
    }
}
