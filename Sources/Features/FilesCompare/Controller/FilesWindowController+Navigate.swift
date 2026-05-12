//
//  FilesWindowController+Navigate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc
    func previousDifference(_: AnyObject) {
        moveToDifference(false, showAnim: true, moveToFile: CommonPrefs.shared.fileAutoAdvanceWhenNoMoreDifferences)
    }

    @objc
    func nextDifference(_: AnyObject) {
        moveToDifference(true, showAnim: true, moveToFile: CommonPrefs.shared.fileAutoAdvanceWhenNoMoreDifferences)
    }

    @objc
    func previousDifferenceFiles(_: AnyObject) {
        navigateToFile(false)
    }

    @objc
    func nextDifferenceFiles(_: AnyObject) {
        navigateToFile(true)
    }

    @objc
    func moveToDifference(
        _ gotoNext: Bool,
        showAnim: Bool,
        moveToFile: Bool
    ) {
        let currentPos = lastUsedView.selectedRow
        var didWrap = false

        let section = if gotoNext {
            currentDiffResult?.findNextSection(by: currentPos, didWrap: &didWrap)
        } else {
            currentDiffResult?.findPrevSection(by: currentPos, didWrap: &didWrap)
        }
        guard let section else {
            if moveToFile,
               canNavigateToFile(gotoNext: gotoNext) {
                navigateToFile(gotoNext, showAnim: showAnim)
            }
            return
        }

        if didWrap {
            if moveToFile {
                if canNavigateToFile(gotoNext: gotoNext) {
                    navigateToFile(gotoNext, showAnim: showAnim)
                    return
                }
                if showAnim,
                   !CommonPrefs.shared.fileWrapsAroundDifferences,
                   (document as? VDDocument)?.parentSession != nil {
                    showNoFileOSD(gotoNext)
                }
            }
            guard CommonPrefs.shared.fileWrapsAroundDifferences else {
                return
            }
        }

        let indexes = IndexSet(integer: section.start)

        // ensure all sections are visible moving to end but set selection to start
        leftView.scrollTo(row: section.start, center: true)
        leftView.selectRowIndexes(indexes, byExtendingSelection: false)
        rightView.selectRowIndexes(indexes, byExtendingSelection: false)
        if didWrap, showAnim {
            scopeBar.findView.showWrapWindow()
        }
    }

    private func canNavigateToFile(gotoNext: Bool) -> Bool {
        guard let document = document as? VDDocument,
              let parentSession = document.parentSession else {
            return false
        }

        if gotoNext {
            return parentSession.hasNextDifference(from: sessionDiff.leftPath, rightPath: sessionDiff.rightPath)
        }
        return parentSession.hasPreviousDifference(from: sessionDiff.leftPath, rightPath: sessionDiff.rightPath)
    }

    func navigateToFile(_ navigateToNext: Bool, showAnim: Bool = false) {
        guard let document = document as? VDDocument,
              let parentSession = document.parentSession else {
            return
        }

        let block: DiffOpenerDelegateBlock = { leftPath, rightPath in
            if leftPath == nil, rightPath == nil {
                self.showNoFileOSD(navigateToNext)
                return false
            }
            if !self.alertSaveDirtyFiles() {
                return false
            }
            // the document is marked as dirty when we set the sessionDiff properties
            // so we update leftPath and rightPath without recording modifications
            document.managedObjectContext?.updateWithoutRecordingModifications {
                self.sessionDiff.leftPath = leftPath
                self.sessionDiff.rightPath = rightPath
                self.reloadAllMove(toFirstDifference: true)
            }

            return true
        }

        if showAnim {
            showMoveToFileOSD(!navigateToNext)
        }
        if navigateToNext {
            parentSession.openNextDifference(
                from: sessionDiff.leftPath,
                rightPath: sessionDiff.rightPath,
                block: block
            )
        } else {
            parentSession.openPreviousDifference(
                from: sessionDiff.leftPath,
                rightPath: sessionDiff.rightPath,
                block: block
            )
        }
    }

    func showNoFileOSD(_ noNextFile: Bool) {
        if noNextFile {
            showOSD(image: NSImage(named: VDImageNameBottom), text: NSLocalizedString("No Next File", comment: ""))
        } else {
            showOSD(image: NSImage(named: VDImageNameTop), text: NSLocalizedString("No Previous File", comment: ""))
        }
    }

    func showMoveToFileOSD(_ gotoNext: Bool) {
        if gotoNext {
            let icon = NSImage(named: VDImageNamePrevFile)?.copy() as? NSImage
            icon?.size = NSSize(width: 60, height: 60)
            showOSD(image: icon, text: NSLocalizedString("Previous File", comment: ""))
        } else {
            let icon = NSImage(named: VDImageNameNextFile)?.copy() as? NSImage
            icon?.size = NSSize(width: 60, height: 60)
            showOSD(image: icon, text: NSLocalizedString("Next File", comment: ""))
        }
    }

    private func showOSD(image: NSImage?, text: String) {
        guard let window else {
            return
        }

        topBottomView.setImage(image)
        topBottomView.setText(text)
        topBottomView.animateInside(window.frame)
    }

    func canMoveToDifference(gotoNext: Bool, moveToFile: Bool) -> Bool {
        if let sections = currentDiffResult?.sections, !sections.isEmpty {
            return true
        }

        guard moveToFile else {
            return false
        }

        return canNavigateToFile(gotoNext: gotoNext)
    }
}
