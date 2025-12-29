//
//  FoldersWindowController.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

import Quartz
import UserNotifications

// the heights are in flipped coordinates
private let splitViewMinHeight: CGFloat = 160.0
private let splitViewMaxHeight: CGFloat = 80.0

public class FoldersWindowController: NSWindowController,
    UNUserNotificationCenterDelegate {
    var observations: [NSKeyValueObservation] = []

    // contain the directories read CompareItem
    var leftItemOriginal: CompareItem?
    var rightItemOriginal: CompareItem?

    // contain the CompareItem to display
    var leftVisibleItems: VisibleItem?
    // swiftlint:disable:next implicitly_unwrapped_optional
    @objc dynamic var sessionDiff: SessionDiff!
    var dontResizeColumns = false
    var running = false
    var previewPanel: QLPreviewPanel?

    var hideEmptyFolders = false
    var showFilteredFiles = false

    // swiftlint:disable:next implicitly_unwrapped_optional
    var lastUsedView: FoldersOutlineView!

    // ComparatorPopUpButtonCell uses the tag property to select item but
    // sessionDiff.comparatorFlags bitmask should not match the tag value, so
    // sessionDiff.comparatorFlags is bit-masked with comparatorMethod in selection action methods
    var comparatorMethod: ComparatorOptions = [] {
        didSet {
            window?.subtitle = comparatorMethod.description

            updateComparisonToolbarItems(comparatorMethod)
            updateToolbarTooltip()
        }
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    var currentFont: NSFont!

    var comparator: ItemComparator?
    lazy var sessionPreferencesSheet: SessionPreferencesWindow = .init()

    var sessionChildren: [VDDocument]

    var leftSecureURL: URL?
    var rightSecureURL: URL?

    var fontZoomFactor: CGFloat = 0 {
        didSet {
            if fontZoomFactor < 0 || fontZoomFactor > 10 {
                fontZoomFactor = oldValue
            }
            updateStatusText()
            updateTreeViewFont()
        }
    }

    // MARK: - View Creation

    lazy var consoleSplitter: DualPaneSplitView = {
        let view = createConsoleSplitter()

        let folderPanels = createFolderPanelsSplitView()
        folderPanels.addArrangedSubview(leftPanelView)
        folderPanels.addArrangedSubview(rightPanelView)

        view.addArrangedSubview(folderPanels)
        view.addArrangedSubview(consoleView)

        return view
    }()

    lazy var consoleView: ConsoleView = createConsoleView()

    // hold it to be sure it isn't deallocated when used from another element
    // the FileSystemController uses it but is released before
    // periphery:ignore
    var progressIndicatorController: ProgressIndicatorController?

    var consoleDelegate = DualPaneSplitViewDelegate(
        collapsableSubViewIndex: 1,
        minSize: splitViewMinHeight,
        maxSize: splitViewMaxHeight
    )

    lazy var leftPanelView: FolderPanelView = .createFolderPanel(
        side: .left,
        delegate: self
    )

    lazy var rightPanelView: FolderPanelView = .createFolderPanel(
        side: .right,
        delegate: self
    )

    lazy var scopeBar: DisplayFiltersScopeBar = createDisplayFiltersScopeBar()

    lazy var differenceCounters: DifferenceCounters = .init(frame: .zero)

    lazy var progressView: ProgressBarView = createProgressView()

    lazy var statusbar: NSStackView = createStatusbar()

    lazy var statusbarText: NSTextField = createStatusbarText()

    init() {
        sessionChildren = []
        let window = WindowCancelOperation.createWindow()
        super.init(window: window)
        shouldCascadeWindows = false
        initAllViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public nonisolated func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if CommonPrefs.shared.showNotificationWhenWindowIsOnFront {
            completionHandler([.list, .sound])
        }
    }

    @objc func openWithApp(_ sender: AnyObject) {
        guard let path = sender.representedObject as? String else {
            return
        }
        let application = URL(filePath: path)
        lastUsedView.openSelected(with: application)
    }

    @objc func openWithOther(_: AnyObject) {
        lastUsedView.openSelectedWithOther()
    }

    @objc func copyUrls(_: AnyObject) {
        lastUsedView.copySelectedAsUrls()
    }

    @objc func expandAllFolders(_: AnyObject) {
        let selectedVisibleItems = lastUsedView.getSelectedVisibleItems(false)

        // views are in sync so it's sufficient to expand only one side to propagate to the other
        leftView.expandItem(nil, expandChildren: true)
        leftView.reloadData()
        rightView.reloadData()

        lastUsedView.restoreSelectionAndFocusPosition(selectedVisibleItems)
    }

    @objc func collapseAllFolders(_: AnyObject) {
        let selectedVisibleItems = lastUsedView.getSelectedVisibleItems(false)

        // views are in sync so it's sufficient to expand only one side to propagate to the other
        leftView.collapseItem(nil, collapseChildren: true)
        leftView.reloadData()
        rightView.reloadData()

        lastUsedView.restoreSelectionAndFocusPosition(selectedVisibleItems)
    }

    @objc func swapSides(_: AnyObject) {
        leftVisibleItems?.swap()

        let path = sessionDiff.leftPath
        sessionDiff.leftPath = sessionDiff.rightPath
        sessionDiff.rightPath = path

        let readOnly = sessionDiff.leftReadOnly
        sessionDiff.leftReadOnly = sessionDiff.rightReadOnly
        sessionDiff.rightReadOnly = readOnly

        leftView.reloadData()
        rightView.reloadData()
    }

    @objc func compareInfo(_: AnyObject) {
        guard let window else {
            return
        }
        let folderCompareInfoWindow = FolderCompareInfoWindow.createSheet()

        folderCompareInfoWindow.leftRoot = leftItemOriginal
        folderCompareInfoWindow.comparatorOptions = sessionDiff.comparatorOptions
        folderCompareInfoWindow.selectedItems = lastUsedView.selectedItems()

        folderCompareInfoWindow.beginSheetModal(for: window)
    }

    // MARK: - Find Methods

    @objc func find(_: AnyObject) {
        window?.makeFirstResponder(scopeBar)
    }

    @objc func findPrevious(_: AnyObject) {
        scopeBar.findView.moveToMatch(false)
    }

    @objc func findNext(_: AnyObject) {
        scopeBar.findView.moveToMatch(true)
    }

    // MARK: - Read only

    @objc func setLeftReadOnly(_: AnyObject) {
        sessionDiff.leftReadOnly.toggle()
    }

    @objc func setRightReadOnly(_: AnyObject) {
        sessionDiff.rightReadOnly.toggle()
    }

    // MARK: - Refresh

    @objc func stopRefresh(_: AnyObject) {
        let retVal = NSAlert.showModalConfirm(
            messageText: NSLocalizedString("Are you sure to stop the operation?", comment: ""),
            informativeText: NSLocalizedString("If the operation takes a long time to run, you can stop it, but the results could be inaccurate", comment: ""),
            suppressPropertyName: CommonPrefs.Name.confirmStopLongOperation.rawValue
        )
        if retVal {
            showConsoleView()
            consoleView.log(warning: NSLocalizedString("Stopped comparison", comment: ""))
            running = false
            progressView.waitStopMessage = NSLocalizedString("Stopping comparison can take a while, please wait...", comment: "")
            progressView.stop()
        }
    }

    func updateStatusText() {
        if fontZoomFactor == 0 {
            statusbarText.stringValue = ""
        } else {
            statusbarText.stringValue = "\(100 + Int(fontZoomFactor) * 10)%"
        }
    }

    // MARK: - Zoom Font

    @objc func zoomLargerFont(_: AnyObject) {
        fontZoomFactor += 1
    }

    @objc func zoomSmallerFont(_: AnyObject) {
        fontZoomFactor -= 1
    }

    @objc func zoomResetFont(_: AnyObject) {
        fontZoomFactor = 0
    }

    #if DEBUG
        override public func keyDown(with event: NSEvent) {
            // Cmd + F12 pressed, create the test code
            if event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers?.unicodeScalars.first?.value == UInt32(NSF12FunctionKey) {
                FileSystemTestHelper.createTestCode(leftView, sessionDiff: sessionDiff)
                NSLog("Unit Test generated and copied on clipboard")

                return
            }

            super.keyDown(with: event)
        }
    #endif
}
