//
//  FilesWindowController+Navigate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc func previousDifference(_: AnyObject) {
        moveToDifference(false, showAnim: true)
    }

    @objc func nextDifference(_: AnyObject) {
        moveToDifference(true, showAnim: true)
    }

    @objc func previousDifferenceFiles(_: AnyObject) {
        navigateToFile(false)
    }

    @objc func nextDifferenceFiles(_: AnyObject) {
        navigateToFile(true)
    }

    @objc func moveToDifference(_ gotoNext: Bool, showAnim: Bool) {
        let currentPos = lastUsedView.selectedRow
        var didWrap = false

        let section = if gotoNext {
            currentDiffResult?.findNextSection(by: currentPos, wrapAround: true, didWrap: &didWrap)
        } else {
            currentDiffResult?.findPrevSection(by: currentPos, wrapAround: true, didWrap: &didWrap)
        }
        if let section {
            let indexes = IndexSet(integer: section.start)

            // ensure all sections are visible moving to end but set selection to start
            leftView.scrollTo(row: section.start, center: true)
            leftView.selectRowIndexes(indexes, byExtendingSelection: false)
            rightView.selectRowIndexes(indexes, byExtendingSelection: false)
            if didWrap, showAnim {
                scopeBar.findView.showWrapWindow()
            }
        }
    }

    func navigateToFile(_ navigateToNext: Bool) {
        guard let document = document as? VDDocument,
              let parentSession = document.parentSession else {
            return
        }

        let block: DiffOpenerDelegateBlock = { leftPath, rightPath in
            if leftPath == nil, rightPath == nil {
                self.showOSDTop(!navigateToNext)
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

        if navigateToNext {
            parentSession.nextDifferenceFiles(from: sessionDiff.leftPath, rightPath: sessionDiff.rightPath, block: block)
        } else {
            parentSession.prevDifferenceFiles(from: sessionDiff.leftPath, rightPath: sessionDiff.rightPath, block: block)
        }
    }

    func showOSDTop(_ noPrevFile: Bool) {
        guard let window else {
            return
        }
        if noPrevFile {
            topBottomView.setImage(NSImage(named: VDImageNameTop))
            topBottomView.setText(NSLocalizedString("No Previous File", comment: ""))
        } else {
            topBottomView.setImage(NSImage(named: VDImageNameBottom))
            topBottomView.setText(NSLocalizedString("No Next File", comment: ""))
        }
        topBottomView.animateInside(window.frame)
    }
}
