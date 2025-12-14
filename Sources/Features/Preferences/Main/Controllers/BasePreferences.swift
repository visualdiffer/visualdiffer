//
//  BasePreferences.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/08/15.
//  Copyright (c) 2015 visualdiffer.com
//

class BasePreferences: NSWindowController, NSToolbarDelegate, NSTabViewDelegate, NSWindowDelegate {
    static let prefsToolbarIdentifier = NSToolbar.Identifier("PreferencesToolbar")
    static let lastVisiblePrefTab = "lastVisiblePrefTab"

    private lazy var tabView: NSTabView = createTabView()
    private lazy var prefPanel: NSWindow = createPrefPanel()

    // Contains the toolbar identifiers sorted by show order
    var toolbarIdentifiers: [NSToolbarItem.Identifier] {
        []
    }

    init() {
        super.init(window: nil)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        setupTabView()
        prefPanel.contentView?.addSubview(tabView)

        setupConstraints()
    }

    private func createPrefPanel() -> NSWindow {
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
        ]

        let view = NSPanel(
            contentRect: .zero,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        view.title = NSLocalizedString("Settings", comment: "")
        view.hasShadow = true
        view.isRestorable = true
        view.titlebarSeparatorStyle = .automatic
        view.setFrameAutosaveName("Settings")
        view.toolbarStyle = .automatic

        view.isFloatingPanel = false
        view.hidesOnDeactivate = false // Don't hide when app deactivates
        view.becomesKeyOnlyIfNeeded = false // Allow it to become key
        view.isReleasedWhenClosed = false

        if #available(macOS 11.0, *) {
            view.toolbarStyle = .preference
        }

        view.toolbar = createToolbar()
        view.delegate = self

        return view
    }

    private func createTabView() -> NSTabView {
        let view = NSTabView(frame: .zero)

        view.tabViewType = .noTabsBezelBorder
        view.allowsTruncatedLabels = false
        view.drawsBackground = true
        view.translatesAutoresizingMaskIntoConstraints = false

        view.delegate = self

        return view
    }

    private func setupTabView() {
        for identifier in toolbarIdentifiers {
            tabView.addTabViewItem(NSTabViewItem(identifier: identifier))
        }
    }

    func createToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: Self.prefsToolbarIdentifier)

        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = true
        toolbar.sizeMode = .regular
        toolbar.displayMode = .iconAndLabel
        toolbar.delegate = self

        return toolbar
    }

    private func setupConstraints() {
        guard let contentView = prefPanel.contentView else {
            return
        }
        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    func selectLastUsedTab() {
        var selectedItemItenIdentifier: NSToolbarItem.Identifier?
        var selectedItemIndex = NSNotFound

        if let lastPrefTab = UserDefaults.standard.string(forKey: Self.lastVisiblePrefTab) {
            let index = tabView.indexOfTabViewItem(withIdentifier: lastPrefTab)
            if index == NSNotFound {
                selectedItemItenIdentifier = toolbarIdentifiers.first
                selectedItemIndex = 0
            } else {
                selectedItemItenIdentifier = NSToolbarItem.Identifier(lastPrefTab)
                selectedItemIndex = index
            }
        }
        if let selectedItemItenIdentifier {
            prefPanel.toolbar?.selectedItemIdentifier = selectedItemItenIdentifier
            tabView.selectTabViewItem(at: selectedItemIndex)
        }
    }

    // Called before the panel is shown on screen, any UI initialization can be done here
    // the default implementation calls selectLastUsedTab
    func panelWillShow() {
        selectLastUsedTab()
    }

    // This method is called when the Preference panel is inside the Main.xib
    @objc func show(_: Any?) {
        panelWillShow()

        prefPanel.center()
        prefPanel.makeKeyAndOrderFront(self)
    }

    // This method is called when the Preference panel is implemented as NSWindowController
    // otherwise isn't called
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        show(sender)
    }

    // MARK: - Toolbar delegate

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarIdentifiers
    }

    func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarIdentifiers
    }

    func toolbarSelectableItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarIdentifiers
    }

    @objc func selectPrefTab(_ sender: Any) {
        if let toolbarItem = sender as? NSToolbarItem {
            UserDefaults.standard.setValue(toolbarItem.itemIdentifier.rawValue, forKey: Self.lastVisiblePrefTab)
            tabView.selectTabViewItem(withIdentifier: toolbarItem.itemIdentifier)
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

    func toolbarHeight(_: NSWindow) -> CGFloat {
        let windowFrame = NSWindow.contentRect(forFrameRect: prefPanel.frame, styleMask: prefPanel.styleMask)
        return windowFrame.size.height - (prefPanel.contentView?.frame.size.height ?? 0)
    }

    func minWindowHeight() -> CGFloat {
        let contentRect = contentRect()
        // Border top + toolbar
        return contentRect.size.height + 40 + toolbarHeight(prefPanel)
    }

    func resize() {
        let windowFrame = NSWindow.contentRect(forFrameRect: prefPanel.frame, styleMask: prefPanel.styleMask)
        let height = minWindowHeight()
        let frameRect = NSRect(x: windowFrame.origin.x, y: windowFrame.origin.y + windowFrame.size.height - height, width: windowFrame.size.width, height: height)
        prefPanel.setFrame(NSWindow.frameRect(forContentRect: frameRect, styleMask: prefPanel.styleMask), display: true, animate: prefPanel.isVisible)
    }

    func tabView(_: NSTabView, didSelect _: NSTabViewItem?) {
        resize()
    }

    func windowDidBecomeKey(_: Notification) {
        resize()
    }

    func windowWillResize(_: NSWindow, to frameSize: NSSize) -> NSSize {
        // Only allow horizontal sizing
        NSSize(width: frameSize.width, height: prefPanel.frame.size.height)
    }

    /*
     We do this to catch the case where the user enters a value into
     one of the text fields but closes the window without hitting enter or tab.
     */
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.makeFirstResponder(nil) // validate editing
    }
}
