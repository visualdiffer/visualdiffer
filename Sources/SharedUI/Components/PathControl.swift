//
//  PathControl.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/10/11.
//  Copyright (c) 2011 visualdiffer.com
//

@objc
protocol PathControlDelegate: NSPathControlDelegate {
    @objc
    @MainActor
    optional func pathControl(_ pathControl: PathControl, willContextMenu menu: NSMenu)
    @objc
    @MainActor
    optional func pathControl(_ pathControl: PathControl, chosenURL url: URL)
    @objc
    @MainActor
    optional func pathControl(_ pathControl: PathControl, openWithApp app: URL)
    @objc
    @MainActor
    optional func pathControlOpenWithOtherApp(_ pathControl: PathControl)

    @objc
    @MainActor
    optional func saveFile(_ sender: AnyObject?)
}

public class PathControl: NSPathControl, NSMenuItemValidation {
    var safePathComponentItem: NSPathControlItem? {
        // click is outside any cell so clickedPathItem returns nil
        guard let item = clickedPathItem else {
            return pathItems.last
        }

        return item
    }

    var clickedPath: URL? {
        clickedPathItem?.url
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    private func setupViews() {
        menu = Self.defaultMenu
        target = self
        doubleAction = #selector(handleDoubleClick(_:))
    }

    // MARK: -

    // MARK: Menu messages

    override public class var defaultMenu: NSMenu? {
        let theMenu = NSMenu(title: NSLocalizedString("Contextual Menu", comment: ""))

        theMenu.addItem(
            withTitle: NSLocalizedString("Choose...", comment: ""),
            action: #selector(choosePath),
            keyEquivalent: ""
        )
        theMenu.addItem(NSMenuItem.separator())

        theMenu.addItem(
            withTitle: NSLocalizedString("Copy Path", comment: ""),
            action: #selector(copyFullPaths),
            keyEquivalent: ""
        )
        let item = theMenu.addItem(
            withTitle: NSLocalizedString("Copy File Name", comment: ""),
            action: #selector(copyFileNames),
            keyEquivalent: ""
        )
        item.keyEquivalentModifierMask = .option
        item.isAlternate = true

        theMenu.addItem(
            withTitle: NSLocalizedString("Show in Finder", comment: ""),
            action: #selector(showInFinder),
            keyEquivalent: ""
        )

        return theMenu
    }

    override public func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event)?.copy() as? NSMenu

        if let menu,
           let delegate = delegate as? PathControlDelegate {
            delegate.pathControl?(self, willContextMenu: menu)
        }

        return menu
    }

    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if !isEnabled {
            return false
        }
        let action = menuItem.action

        if url == nil {
            if action == #selector(choosePath) {
                return true
            } else if action == #selector(copyFileNames) {
                // otherwise the item "Copy File Name" is always visible
                menuItem.isAlternate = false
            }
            menuItem.isHidden = true
            return false
        }

        if action == #selector(copyFileNames) {
            menuItem.isAlternate = true
        }

        menuItem.isHidden = false

        return true
    }

    // MARK: - Actions

    @objc
    func showInFinder(_: AnyObject) {
        guard let url = safePathComponentItem?.url else {
            return
        }

        // the URL returned by pathCell cannot be resolved by Finder, so we pass the file path
        let paths = [url.osPath]
        NSWorkspace.shared.show(inFinder: paths)
    }

    @objc
    func copyFileNames(_: AnyObject) {
        guard let url = safePathComponentItem?.url else {
            return
        }

        NSPasteboard.general.copy(lines: [url.lastPathComponent])
    }

    @objc
    func copyFullPaths(_: AnyObject) {
        guard let url = safePathComponentItem?.url else {
            return
        }

        NSPasteboard.general.copy(lines: [url.osPath])
    }

    @objc
    func openWithApp(_ sender: AnyObject) {
        // store the delegate to a strong local variable
        if let delegate = delegate as? PathControlDelegate,
           let applicationPath = sender.representedObject as? String {
            delegate.pathControl?(self, openWithApp: URL(filePath: applicationPath))
        }
    }

    @objc
    func openWithOther(_: AnyObject) {
        if let delegate = delegate as? PathControlDelegate {
            delegate.pathControlOpenWithOtherApp?(self)
        }
    }

    @objc
    func choosePath(_: AnyObject) {
        guard let delegate = delegate as? PathControlDelegate else {
            return
        }

        let openPanel = NSOpenPanel()

        openPanel.directoryURL = safePathComponentItem?.url ?? url

        delegate.pathControl?(self, willDisplay: openPanel)

        if openPanel.runModal() == .OK {
            let URL = openPanel.urls[0]

            if let bindingsInfo = infoForBinding(.value) {
                // note that we set the value with a path string, not a URL
                if let object = bindingsInfo[NSBindingInfoKey.observedObject] as? NSObject,
                   let bindingsPath = bindingsInfo[NSBindingInfoKey.observedKeyPath] as? String {
                    object.setValue(
                        URL.path,
                        forKeyPath: bindingsPath
                    )
                }
            }
            delegate.pathControl?(self, chosenURL: URL)
        }
    }

    // MARK: - overridden

    override public var intrinsicContentSize: NSSize {
        // keep it flexible when using Auto Layout
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    @objc
    private func handleDoubleClick(_ sender: AnyObject) {
        let modifiers = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if modifiers.isEmpty {
            showInFinder(sender)
        } else if modifiers == .option {
            copyFullPaths(sender)
        }
    }
}
