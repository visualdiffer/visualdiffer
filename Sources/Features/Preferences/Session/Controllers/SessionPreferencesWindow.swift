//
//  SessionPreferencesWindow.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/03/13.
//  Copyright (c) 2013 visualdiffer.com
//

class SessionPreferencesWindow: NSWindowController, NSTabViewDelegate, @preconcurrency PreferencesBoxDataSource {
    private lazy var tabView: NSTabView = createTabView()
    private lazy var standardButtons: StandardButtons = .init(
        primaryTitle: NSLocalizedString("OK", comment: ""),
        secondaryTitle: NSLocalizedString("Cancel", comment: ""),
        target: self,
        action: #selector(closeSessionSettingsSheet)
    )

    private var loadedTabs = Set<NSUserInterfaceItemIdentifier>()
    private var currentPreferences = Data()

    // used to retrieve pending data not updated on every modification
    private var sessionPreferencesFiltersPanel: SessionPreferencesFiltersPanel?

    // TabView Identifiers
    private static let comparisonPanelIdentifier = NSUserInterfaceItemIdentifier("Comparison")
    private static let fileFiltersPanelIdentifier = NSUserInterfaceItemIdentifier("FileFilters")
    private static let alignmentPanelIdentifier = NSUserInterfaceItemIdentifier("Alignment")

    required init() {
        super.init(window: Self.createPanel())

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        if let contentView = window?.contentView {
            contentView.addSubview(tabView)
            contentView.addSubview(standardButtons)
        }

        setupConstraints()
    }

    private static func createPanel() -> NSPanel {
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
        ]

        let view = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        view.hasShadow = true
        view.isRestorable = true
        view.setFrameAutosaveName("sessionPreferencesFrame")
        view.minSize = NSSize(width: 500, height: 400)

        return view
    }

    private func createTabView() -> NSTabView {
        let view = NSTabView(frame: .zero)

        view.tabViewType = .topTabsBezelBorder
        view.allowsTruncatedLabels = false
        view.drawsBackground = true
        view.translatesAutoresizingMaskIntoConstraints = false

        view.delegate = self

        let tabInfo = [
            (Self.comparisonPanelIdentifier, NSLocalizedString("Comparison", comment: "")),
            (Self.fileFiltersPanelIdentifier, NSLocalizedString("File Filters", comment: "")),
            (Self.alignmentPanelIdentifier, NSLocalizedString("Alignment", comment: "")),
        ]

        for (identifier, label) in tabInfo {
            let item = NSTabViewItem(identifier: identifier)
            item.label = label
            view.addTabViewItem(item)
        }

        return view
    }

    private func setupConstraints() {
        guard let contentView = window?.contentView else {
            return
        }
        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            // very bad approach because I'm unable to have the tabView fills the height and place the button below it.
            // Problem: If I place the button below the tabView when I change tab the button resizes vertically instead of stay fixed
            // Workaround: I move the tabView to parent bottom and reduce its size (i.e. -40)
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            standardButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    func beginSheet(
        _ sheetWindow: NSWindow,
        sessionDiff: SessionDiff?,
        selectedTab: SessionPreferencesWindow.Tab,
        completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil
    ) {
        guard let window else {
            return
        }
        if let sessionDiff {
            fillWithSessionDiff(sessionDiff)
        }

        tabView.selectTabViewItem(at: selectedTab.rawValue)

        sheetWindow.beginSheet(window, completionHandler: handler)
    }

    func updateSessionDiff(_ sessionDiff: SessionDiff) {
        currentPreferences.updateSessionDiff(sessionDiff)
    }

    func fillWithSessionDiff(_ sessionDiff: SessionDiff) {
        currentPreferences = Data.fromSessionDiff(sessionDiff)
        reload(tabItem: tabView.selectedTabViewItem)
    }

    func fillWithUserDefaults() {
        currentPreferences = Data.fromUserDefaults()
        reload(tabItem: tabView.selectedTabViewItem)
    }

    @objc func closeSessionSettingsSheet(_ sender: AnyObject) {
        guard let window else {
            return
        }
        let response = NSApplication.ModalResponse(sender.tag)
        if response == .OK {
            updatePendingData()
            window.endEditing()
        }
        window.sheetParent?.endSheet(window, returnCode: response)
    }

    func updatePendingData() {
        sessionPreferencesFiltersPanel?.updatePendingData()
    }

    // MARK: - TabView delegate

    func tabView(_: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        guard let tabViewItem,
              let identifier = tabViewItem.identifier as? NSUserInterfaceItemIdentifier else {
            return
        }

        if loadedTabs.contains(identifier) {
            return
        }
        loadedTabs.insert(identifier)

        if identifier == Self.comparisonPanelIdentifier {
            let view = SessionPreferencesComparisonPanel(frame: .zero)
            view.delegate = self
            tabViewItem.view = view
        } else if identifier == Self.fileFiltersPanelIdentifier {
            let panel = SessionPreferencesFiltersPanel(frame: .zero)
            panel.delegate = self
            sessionPreferencesFiltersPanel = panel
            tabViewItem.view = sessionPreferencesFiltersPanel
        } else if identifier == Self.alignmentPanelIdentifier {
            let view = AlignmentPanel(frame: .zero)
            view.delegate = self
            tabViewItem.view = view
        }
        reload(tabItem: tabViewItem)
    }

    func tabView(_: NSTabView, didSelect _: NSTabViewItem?) {
        resize()
    }

    func reload(tabItem: NSTabViewItem?) {
        if let view = tabItem?.view as? PreferencesPanelDataSource {
            view.reloadData()
        }
    }

    // MARK: - PreferenceBox delegate

    func preferenceBox(_: PreferencesBox, boolForKey key: CommonPrefs.Name) -> Bool {
        switch key {
        case .virtualResourceFork:
            currentPreferences.fileExtraOptions.hasCheckResourceForks
        case .virtualFinderLabel:
            currentPreferences.comparatorOptions.hasFinderLabel
        case .virtualFinderTags:
            currentPreferences.comparatorOptions.hasFinderTags
        case .followSymLinks:
            currentPreferences.followSymLinks
        case .skipPackages:
            currentPreferences.skipPackages
        case .traverseFilteredFolders:
            currentPreferences.traverseFilteredFolders
        case .expandAllFolders:
            currentPreferences.expandAllFolders
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, setBool value: Bool, forKey key: CommonPrefs.Name) {
        switch key {
        case .virtualResourceFork:
            currentPreferences.fileExtraOptions = currentPreferences.fileExtraOptions.changeCheckResourceForks(value)
        case .virtualFinderLabel:
            currentPreferences.comparatorOptions = currentPreferences.comparatorOptions.changeFinderLabel(value)
        case .virtualFinderTags:
            currentPreferences.comparatorOptions = currentPreferences.comparatorOptions.changeFinderTags(value)
        case .followSymLinks:
            currentPreferences.followSymLinks = value
        case .skipPackages:
            currentPreferences.skipPackages = value
        case .traverseFilteredFolders:
            currentPreferences.traverseFilteredFolders = value
        case .expandAllFolders:
            currentPreferences.expandAllFolders = value
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, integerForKey key: CommonPrefs.Name) -> Int {
        switch key {
        case .virtualComparatorWithoutMethod:
            currentPreferences.comparatorOptions.onlyMethodFlags.rawValue
        case .virtualDisplayFiltersWithoutMethod:
            currentPreferences.displayOptions.onlyMethodFlags.rawValue
        case .virtualAlignFlags:
            currentPreferences.comparatorOptions.onlyAlignFlags.rawValue
        case .timestampToleranceSeconds:
            currentPreferences.timestampToleranceSeconds
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, setInteger value: Int, forKey key: CommonPrefs.Name) {
        switch key {
        case .virtualComparatorWithoutMethod:
            currentPreferences.comparatorOptions = currentPreferences.comparatorOptions.changeWithoutMethod(value)
        case .virtualDisplayFiltersWithoutMethod:
            currentPreferences.displayOptions = currentPreferences.displayOptions.changeWithoutMethod(value)
        case .virtualAlignFlags:
            currentPreferences.comparatorOptions = currentPreferences.comparatorOptions.changeAlign(value)
        case .timestampToleranceSeconds:
            currentPreferences.timestampToleranceSeconds = value
        default:
            fatalError("key \(key) not handled")
        }
    }

    func preferenceBox(_: PreferencesBox, stringForKey key: CommonPrefs.Name) -> String? {
        switch key {
        case .defaultFileFilters:
            currentPreferences.fileFilters
        default:
            fatalError("The key \(key) is not supported")
        }
    }

    func preferenceBox(_: PreferencesBox, setString value: String?, forKey key: CommonPrefs.Name) {
        switch key {
        case .defaultFileFilters:
            currentPreferences.fileFilters = value
        default:
            fatalError("The key \(key) is not supported")
        }
    }

    func preferenceBox(_: PreferencesBox, objectForKey key: CommonPrefs.Name) -> Any? {
        switch key {
        case .virtualAlignRules:
            currentPreferences.alignRules
        default:
            fatalError("The key \(key) is not supported")
        }
    }

    func preferenceBox(_: PreferencesBox, setObject value: Any?, forKey key: CommonPrefs.Name) {
        switch key {
        case .virtualAlignRules:
            if let value = value as? [AlignRule] {
                currentPreferences.alignRules = value
            }
        default:
            fatalError("The key \(key) is not supported")
        }
    }

    func preferenceBox(_ preferencesBox: PreferencesBox, isEnabled key: CommonPrefs.Name) -> Bool {
        switch key {
        case .virtualFinderLabel:
            preferenceBox(preferencesBox, boolForKey: .virtualFinderTags) == false
        case .virtualFinderTags:
            preferenceBox(preferencesBox, boolForKey: .virtualFinderLabel) == false
        default:
            true
        }
    }

    // MARK: - Position and size

    func contentRect() -> NSRect {
        var contentRect = NSRect.zero

        if let selectedTabView = tabView.selectedTabViewItem?.view {
            for view in selectedTabView.subviews {
                // the result of Swift's GCRect.union is different from NSUnionRect
                // so we stay on it
                // swiftlint:disable:next legacy_nsgeometry_functions
                contentRect = NSUnionRect(contentRect, view.frame)
            }
        }

        return contentRect
    }

    func toolbarHeight(_ window: NSWindow?) -> CGFloat {
        guard let window else {
            return 0
        }
        let windowFrame = NSWindow.contentRect(forFrameRect: window.frame, styleMask: window.styleMask)
        return windowFrame.size.height - (window.contentView?.frame.size.height ?? 0)
    }

    func minWindowHeight() -> CGFloat {
        let contentRect = contentRect()
        // Border top + toolbar
        return contentRect.size.height + 40 + toolbarHeight(window)
    }

    func resize() {
        guard let window,
              window.isVisible else {
            return
        }
        let newSize = NSSize(
            width: window.contentView?.frame.size.width ?? 0,
            height: minWindowHeight()
        )

        window.setContentSize(newSize)
    }
}

extension SessionPreferencesWindow {
    enum Tab: Int {
        case comparison
        case filters
        case alignment
    }
}
