//
//  FileSessionPreferencesWindow.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FileSessionPreferencesWindow: NSWindowController, NSTabViewDelegate {
    private lazy var tabView: NSTabView = createTabView()
    private lazy var standardButtons: StandardButtons = .init(
        primaryTitle: NSLocalizedString("OK", comment: ""),
        secondaryTitle: NSLocalizedString("Cancel", comment: ""),
        target: self,
        action: #selector(closeSessionSettingsSheet)
    )

    private var loadedTabs = Set<NSUserInterfaceItemIdentifier>()
    var preferences = FilePreferences()

    // TabView Identifiers
    private static let comparisonPanelIdentifier = NSUserInterfaceItemIdentifier("Comparison")

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
        view.setFrameAutosaveName("fileSessionPreferencesFrame")
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
        preferences: FilePreferences,
        selectedTab: FileSessionPreferencesWindow.Tab,
        completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil
    ) {
        guard let window else {
            return
        }
        fill(with: preferences)

        tabView.selectTabViewItem(at: selectedTab.rawValue)

        sheetWindow.beginSheet(window, completionHandler: handler)
    }

    @objc
    func closeSessionSettingsSheet(_ sender: AnyObject) {
        guard let window else {
            return
        }
        let response = NSApplication.ModalResponse(sender.tag)
        if response == .OK {
            window.endEditing()
        }
        window.sheetParent?.endSheet(window, returnCode: response)
    }

    func fill(with preferences: FilePreferences) {
        self.preferences = preferences
        reload(tabItem: tabView.selectedTabViewItem)
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
            let view = FilePreferencesComparisonPanel(frame: .zero)
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

extension FileSessionPreferencesWindow {
    enum Tab: Int {
        case comparison
    }
}
