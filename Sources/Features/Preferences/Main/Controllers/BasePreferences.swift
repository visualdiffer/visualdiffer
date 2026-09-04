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

    // the widest panel needs 513 points and the full toolbar 479, this covers both, the panels
    // declare their own width so minWindowWidth() enlarges the window if one ever needs more
    private static let defaultContentWidth: CGFloat = 520

    // the inset a noTabsBezelBorder tab view keeps above and below its content
    private static let tabViewVerticalBorder: CGFloat = 20

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

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
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
            contentRect: NSRect(origin: .zero, size: NSSize(width: Self.defaultContentWidth, height: 0)),
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
        // the first tab is the default, on the first run there is no stored tab to restore
        var selectedItemItenIdentifier = toolbarIdentifiers.first
        var selectedItemIndex = 0

        if let lastPrefTab = UserDefaults.standard.string(forKey: Self.lastVisiblePrefTab) {
            let index = tabView.indexOfTabViewItem(withIdentifier: lastPrefTab)
            if index != NSNotFound {
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
    @objc
    func show(_: Any?) {
        panelWillShow()

        prefPanel.center()
        prefPanel.makeKeyAndOrderFront(self)

        // reopening the panel does not always reselect the tab, and without a tab change nothing
        // else recomputes the geometry
        resize()
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

    @objc
    func selectPrefTab(_ sender: Any) {
        if let toolbarItem = sender as? NSToolbarItem {
            UserDefaults.standard.setValue(toolbarItem.itemIdentifier.rawValue, forKey: Self.lastVisiblePrefTab)
            tabView.selectTabViewItem(withIdentifier: toolbarItem.itemIdentifier)
        }
    }

    // MARK: - Position and size

    func toolbarHeight(_: NSWindow) -> CGFloat {
        // both terms are derived from the window frame, the content view height cannot be used
        // because it is already laid out for the new panel while the frame is still the old one
        let windowFrame = NSWindow.contentRect(forFrameRect: prefPanel.frame, styleMask: prefPanel.styleMask)

        return windowFrame.size.height - prefPanel.contentLayoutRect.size.height
    }

    func minWindowHeight() -> CGFloat {
        guard let selectedView = tabView.selectedTabViewItem?.view else {
            return 0
        }

        // the panel fittingSize is the only quantity already updated when the tab changes, both
        // the tab view frames and its own fittingSize still describe the previous panel
        return selectedView.fittingSize.height + Self.tabViewVerticalBorder + toolbarHeight(prefPanel)
    }

    func resize() {
        let windowFrame = NSWindow.contentRect(forFrameRect: prefPanel.frame, styleMask: prefPanel.styleMask)
        let height = minWindowHeight()
        // the width comes from the panel constraints, a wider panel enlarges the window and the
        // width the user chose by dragging is never reduced
        let width = max(windowFrame.size.width, minWindowWidth())
        let frameRect = NSRect(
            x: windowFrame.origin.x,
            y: windowFrame.origin.y + windowFrame.size.height - height,
            width: width,
            height: height
        )
        prefPanel.setFrame(
            NSWindow.frameRect(forContentRect: frameRect, styleMask: prefPanel.styleMask),
            display: true,
            animate: prefPanel.isVisible
        )
    }

    func tabView(_: NSTabView, didSelect _: NSTabViewItem?) {
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

    func minWindowWidth() -> CGFloat {
        guard let selectedView = tabView.selectedTabViewItem?.view else {
            return 0
        }

        // the frames union used for the height reports the current layout, already squeezed when
        // the panel is too narrow, fittingSize is the width the constraints actually require
        let tabViewBorder = tabView.frame.size.width - tabView.contentRect.size.width

        return selectedView.fittingSize.width + tabViewBorder
    }
}
