//
//  FilesWindowController+Navigate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    private static let moveToFileOSDIconSize = NSSize(width: 60, height: 60)

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
            if moveToFile {
                navigateToFile(gotoNext, showAnim: showAnim, showsNoFileOSD: showAnim)
            }
            return
        }

        if didWrap {
            if moveToFile,
               navigateToFile(
                   gotoNext,
                   showAnim: showAnim,
                   showsNoFileOSD: showAnim && !CommonPrefs.shared.fileWrapsAroundDifferences
               ) {
                return
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

    // returns whether the parent session holds a file in that direction, the search it
    // costs is the same one the move needs so the two cannot be asked separately
    @discardableResult
    func navigateToFile(
        _ navigateToNext: Bool,
        showAnim: Bool = false,
        showsNoFileOSD: Bool = true
    ) -> Bool {
        guard let document = document as? VDDocument,
              let parentSession = document.parentSession else {
            return false
        }

        var hasFile = false

        let block: DiffOpenerDelegateBlock = { leftPath, rightPath in
            if leftPath == nil, rightPath == nil {
                // the controls stay enabled as long as a folder session is behind the
                // file, so this direction can have no file at all and the press would
                // otherwise do nothing
                if showsNoFileOSD {
                    self.showNoFileOSD(navigateToNext)
                }
                return false
            }
            hasFile = true

            if showAnim {
                self.showMoveToFileOSD(!navigateToNext)
            }
            if !self.alertSaveDirtyFiles() {
                return false
            }
            // moving to another file of the parent session is navigation, not a session edit
            document.updateWithoutMarkingEdited {
                self.sessionDiff.leftPath = leftPath
                self.sessionDiff.rightPath = rightPath
            }
            self.startReload(toFirstDifference: true)

            return true
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

        return hasFile
    }

    func showNoFileOSD(_ noNextFile: Bool) {
        let (symbol, text) = noNextFile
            ? (VDSymbol.Asset.bottom, NSLocalizedString("No Next File", comment: ""))
            : (VDSymbol.Asset.top, NSLocalizedString("No Previous File", comment: ""))
        showOSD(image: symbol.image(), text: text)
    }

    func showMoveToFileOSD(_ gotoNext: Bool) {
        let (symbol, text) = gotoNext
            ? (VDSymbol.Asset.prevFile, NSLocalizedString("Previous File", comment: ""))
            : (VDSymbol.Asset.nextFile, NSLocalizedString("Next File", comment: ""))
        showOSD(image: symbol.image(), text: text, size: Self.moveToFileOSDIconSize)
    }

    private func showOSD(image: NSImage, text: String, size: NSSize? = nil) {
        guard let window else {
            return
        }

        topBottomView.setImage(image, size: size)
        topBottomView.setText(text)
        topBottomView.animateInside(window.frame)
    }

    func canMoveToDifference() -> Bool {
        if let sections = currentDiffResult?.sections, !sections.isEmpty {
            return true
        }

        // asking the parent session for the next differing file walks its whole tree and
        // the answer is asked again at every validation, on a large folder session that
        // is half a second each time; the action itself shows the OSD when there is no
        // file to move to
        return CommonPrefs.shared.fileAutoAdvanceWhenNoMoreDifferences && parentSession != nil
    }
}
