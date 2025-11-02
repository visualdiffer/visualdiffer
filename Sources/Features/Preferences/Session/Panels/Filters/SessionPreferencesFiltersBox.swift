//
//  SessionPreferencesFiltersBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class SessionPreferencesFiltersBox: PreferencesBox, NSMenuItemValidation {
    private lazy var actionMenu: NSPopUpButton = {
        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.bezelStyle = .shadowlessSquare
        view.setButtonType(.momentaryPushIn)
        view.isBordered = true
        view.alignment = .left

        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.menu = createActionPopupMenu()

        return view
    }()

    private lazy var predicateEditorScrollView: NSScrollView = {
        let view = NSScrollView(frame: .zero)

        view.borderType = .bezelBorder
        view.autohidesScrollers = true
        view.hasHorizontalScroller = true
        view.hasVerticalScroller = true
        view.horizontalLineScroll = 19
        view.horizontalPageScroll = 10
        view.verticalLineScroll = 19
        view.verticalPageScroll = 10
        view.usesPredominantAxisScrolling = false
        view.translatesAutoresizingMaskIntoConstraints = false

        view.documentView = predicateEditor

        predicateEditor.translatesAutoresizingMaskIntoConstraints = false
        predicateEditor.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        return view
    }()

    private lazy var predicateEditor: FiltersPredicateEditor = {
        let view = FiltersPredicateEditor(frame: .zero)

        if let defaultFilters = SessionDiff.defaultFileFilters() {
            view.objectValue = NSPredicate(format: defaultFilters)
        }
        return view
    }()

    private var currentFilters: String? {
        (predicateEditor.objectValue as? NSPredicate)?.description
    }

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(predicateEditorScrollView)
            contentView.addSubview(actionMenu)
        }

        setupConstraints()
    }

    private func createActionPopupMenu() -> NSMenu {
        let popupMenu = NSMenu()

        // the button title image
        popupMenu.addItem(
            withTitle: "",
            action: nil,
            keyEquivalent: ""
        )
        .image = NSImage(named: NSImage.actionTemplateName)
        popupMenu.addItem(
            withTitle: NSLocalizedString("Fill with Defaults", comment: ""),
            action: #selector(fillWithDefaults),
            keyEquivalent: ""
        )
        popupMenu.addItem(
            withTitle: NSLocalizedString("Set Current as Defaults", comment: ""),
            action: #selector(saveDefaults),
            keyEquivalent: ""
        )
        popupMenu.addItem(
            withTitle: NSLocalizedString("Restore Factory Defaults", comment: ""),
            action: #selector(restoreDefaults),
            keyEquivalent: ""
        )
        popupMenu.addItem(NSMenuItem.separator())
        popupMenu.addItem(
            withTitle: NSLocalizedString("Copy to Clipboard", comment: ""),
            action: #selector(copyToClipboard),
            keyEquivalent: ""
        )
        popupMenu.addItem(
            withTitle: NSLocalizedString("Paste from Clipboard", comment: ""),
            action: #selector(pasteFromClipboard),
            keyEquivalent: ""
        )

        for item in popupMenu.items {
            item.target = self
        }

        return popupMenu
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            actionMenu.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionMenu.topAnchor.constraint(equalTo: contentView.topAnchor),

            predicateEditorScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            predicateEditorScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            predicateEditorScrollView.topAnchor.constraint(equalTo: actionMenu.bottomAnchor, constant: 10),
            predicateEditorScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Action Methods

    @objc func copyToClipboard(_: AnyObject) {
        if let filters = currentFilters as? NSString {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([filters])
        }
    }

    @objc func pasteFromClipboard(_: AnyObject) {
        let pasteboard = NSPasteboard.general
        let supportedTypes = [NSPasteboard.PasteboardType.string]

        if let bestType = pasteboard.availableType(from: supportedTypes),
           let filters = pasteboard.string(forType: bestType) {
            do {
                predicateEditor.objectValue = try NSPredicate.createSafe(withFormat: filters)
            } catch {
                let alert = NSAlert()

                alert.messageText = NSLocalizedString("File filter expression contains errors", comment: "")
                alert.alertStyle = .critical
                alert.informativeText = error.localizedDescription

                alert.runModal()
            }
        }
    }

    @objc func saveDefaults(_: AnyObject) {
        guard let filters = currentFilters else {
            return
        }

        var overwrite = true
        if CommonPrefs.shared.defaultFileFilters != nil {
            overwrite = NSAlert.showModalConfirm(
                messageText: NSLocalizedString("Replace Custom Defaults", comment: ""),
                informativeText: NSLocalizedString("Do you want to replace the current custom defaults?", comment: "")
            )
        }
        if overwrite {
            CommonPrefs.shared.defaultFileFilters = filters
        }
    }

    @objc func restoreDefaults(_: AnyObject) {
        let result = NSAlert.showModalConfirm(
            messageText: NSLocalizedString("Restore Defaults", comment: ""),
            informativeText: NSLocalizedString("The custom defined defaults will be replaced with application defaults, are you sure?", comment: "")
        )
        if result {
            CommonPrefs.shared.defaultFileFilters = nil
        }
    }

    @objc func fillWithDefaults(_: AnyObject) {
        if let defaultFilters = SessionDiff.defaultFileFilters() {
            predicateEditor.objectValue = NSPredicate(format: defaultFilters)
        }
    }

    // MARK: - NSMenuItemValidation

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        var enabled = true
        let action = menuItem.action

        if action == #selector(restoreDefaults) {
            let defaultFilters = CommonPrefs.shared.defaultFileFilters
            menuItem.isHidden = defaultFilters == nil
        } else if action == #selector(saveDefaults) {
            enabled = if let defaultFilters = CommonPrefs.shared.defaultFileFilters,
                         let filters = currentFilters {
                defaultFilters != filters
            } else {
                false
            }
        }

        return enabled
    }

    override func reloadData() {
        if let str = delegate?.preferenceBox(self, stringForKey: .defaultFileFilters) {
            predicateEditor.objectValue = NSPredicate(format: str)
        } else {
            predicateEditor.objectValue = nil
        }
    }

    func updatePendingData() {
        if let filters = currentFilters {
            delegate?.preferenceBox(self, setString: filters, forKey: .defaultFileFilters)
        }
    }
}
