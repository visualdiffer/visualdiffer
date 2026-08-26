//
//  FindText.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/11.
//  Copyright (c) 2011 visualdiffer.com
//

protocol FindTextDelegate: AnyObject {
    func find(findText: FindText, searchPattern pattern: String) -> Bool
    func find(findText: FindText, moveToMatchIndex index: Int) -> Bool
    func numberOfMatches(in findText: FindText) -> Int
    func clearMatches(in findText: FindText)
    func selectAllMatches(in findText: FindText, side: DisplaySide)
}

class FindText: NSView, NSSearchFieldDelegate, NSMenuItemValidation {
    private static let viewHeight: CGFloat = 25

    private var lastIndexFound = -1

    var delegate: FindTextDelegate?

    // files and folders can be matched separately only when searching a folders comparison
    var showsFileFilters = false {
        didSet {
            updateSearchMenu()
        }
    }

    private(set) var findOptions = FindOptions()

    private lazy var rewindView: WindowOSD = .init(
        image: VDSymbol.Asset.rewind.image(),
        parent: window
    )

    private lazy var arrows: NSSegmentedControl = {
        let images = [
            NSImage.required(named: NSImage.goLeftTemplateName),
            NSImage.required(named: NSImage.goRightTemplateName),
        ]
        let view = NSSegmentedControl(
            images: images,
            trackingMode: .momentary,
            target: self,
            action: #selector(moveByArrow)
        )

        view.segmentStyle = .roundRect
        view.controlSize = .small
        view.isEnabled = false
        view.setWidth(16, forSegment: 0)
        view.setWidth(16, forSegment: 1)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var countLabel: NSTextField = {
        let view = NSTextField(frame: .zero)

        view.isBezeled = false
        view.isBordered = false
        view.drawsBackground = false
        view.controlSize = .small
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.alignment = .right
        view.focusRingType = .none
        view.isEditable = false
        view.isSelectable = false
        view.textColor = NSColor.controlTextColor
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var searchField: NSSearchField = {
        let view = NSSearchField(frame: .zero)

        view.bezelStyle = .roundedBezel
        view.controlSize = .small
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.translatesAutoresizingMaskIntoConstraints = false

        // allow to scroll when the text
        if let cell = view.cell as? NSSearchFieldCell {
            cell.isScrollable = true
            cell.wraps = false
        }

        view.target = self
        view.action = #selector(search)
        // used to receive NSControlTextEditingDelegate notifications
        view.delegate = self

        return view
    }()

    private lazy var matchCaseItem = menuItem(
        NSLocalizedString("Match Case", comment: ""),
        action: #selector(toggleMatchCase)
    )

    private lazy var matchFilesItem = menuItem(
        NSLocalizedString("Match Files", comment: ""),
        action: #selector(toggleMatchFiles)
    )

    private lazy var matchFoldersItem = menuItem(
        NSLocalizedString("Match Folders", comment: ""),
        action: #selector(toggleMatchFolders)
    )

    private lazy var modeItems: [NSMenuItem] = FindMode.allCases.map { mode in
        let item = NSMenuItem(
            title: mode.title,
            action: #selector(selectFindMode),
            keyEquivalent: ""
        )

        item.target = self
        // the tag is the only way to know the clicked mode because the menu shown
        // by the search field is a copy of this template
        item.tag = mode.rawValue

        return item
    }

    private lazy var searchMenu: NSMenu = {
        let menu = NSMenu()

        modeItems.forEach { menu.addItem($0) }
        menu.addItem(.separator())
        menu.addItem(matchCaseItem)
        menu.addItem(matchFilesItem)
        menu.addItem(matchFoldersItem)

        return menu
    }()

    var placeholder: String {
        get { searchField.placeholderString ?? "" }
        set { searchField.placeholderString = newValue }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupView()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    private func setupView() {
        addSubview(searchField)
        addSubview(arrows)
        addSubview(countLabel)

        updateSearchMenu()

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.viewHeight),

            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            searchField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchField.widthAnchor.constraint(equalToConstant: 240),

            arrows.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            arrows.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            arrows.trailingAnchor.constraint(equalTo: searchField.leadingAnchor, constant: -2),

            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: arrows.leadingAnchor, constant: -4),
        ])
    }

    // MARK: - Find methods

    var hasMatches: Bool {
        guard let delegate else {
            return false
        }

        return delegate.numberOfMatches(in: self) > 0
    }

    func updateCount() {
        guard let delegate else {
            return
        }

        let count = delegate.numberOfMatches(in: self)
        if count > 0 {
            arrows.isEnabled = true
            countLabel.stringValue = String(format: "%ld/%ld", lastIndexFound + 1, count)
        } else {
            arrows.isEnabled = false
            countLabel.stringValue = NSLocalizedString("Not found", comment: "")
        }
    }

    @objc
    func search(_: AnyObject) {
        guard let delegate else {
            return
        }

        delegate.clearMatches(in: self)
        lastIndexFound = -1
        let pattern = searchField.stringValue

        if pattern.isEmpty {
            countLabel.stringValue = ""
            arrows.isEnabled = false

            return
        }

        if delegate.find(findText: self, searchPattern: pattern) {
            moveToMatch(true)
        } else {
            updateCount()
        }
    }

    // MARK: - Move Methods

    func moveToMatch(_ gotoNext: Bool) {
        guard let delegate else {
            return
        }

        let foundCount = delegate.numberOfMatches(in: self)
        if foundCount == 0 {
            updateCount()
            return
        }

        var didWrap = false

        if gotoNext {
            if lastIndexFound + 1 < foundCount {
                lastIndexFound += 1
            } else {
                lastIndexFound = 0
                didWrap = true
            }
        } else {
            if lastIndexFound - 1 >= 0 {
                lastIndexFound -= 1
            } else {
                lastIndexFound = foundCount - 1
                didWrap = true
            }
        }
        if delegate.find(findText: self, moveToMatchIndex: lastIndexFound) {
            if didWrap {
                showWrapWindow()
            }
        } else {
            moveToMatch(gotoNext)
        }
        updateCount()
    }

    @objc
    func moveByArrow(_: AnyObject) {
        moveToMatch(arrows.selectedSegment == 1)
    }

    // MARK: - NSControlTextEditingDelegate and text change methods

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Move to next result using return key
        if commandSelector == #selector(insertNewline) {
            let isShiftDown = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
            moveToMatch(!isShiftDown)
            return true
        }
        return false
    }

    func showWrapWindow() {
        if let window {
            rewindView.animateInside(window.frame)
        }
    }

    // MARK: - View methods

    override func becomeFirstResponder() -> Bool {
        // doesn't expose searchField field but allow to set first responder
        searchField.becomeFirstResponder()
    }

    @objc
    private func toggleMatchCase(_: AnyObject) {
        findOptions.matchCase.toggle()
        optionsChanged()
    }

    @objc
    private func toggleMatchFiles(_: AnyObject) {
        findOptions.matchFiles.toggle()
        optionsChanged()
    }

    @objc
    private func toggleMatchFolders(_: AnyObject) {
        findOptions.matchFolders.toggle()
        optionsChanged()
    }

    @objc
    private func selectFindMode(_ sender: NSMenuItem) {
        guard let mode = FindMode(rawValue: sender.tag),
              mode != findOptions.mode else {
            return
        }

        findOptions.mode = mode
        optionsChanged()
    }

    private func optionsChanged() {
        // the matches found with the previous options are no longer valid
        search(self)
    }

    private func updateSearchMenu() {
        matchFilesItem.isHidden = !showsFileFilters
        matchFoldersItem.isHidden = !showsFileFilters

        // the template is copied when it is assigned, so it must be assigned again to show the changes
        searchField.searchMenuTemplate = searchMenu
    }

    // the shown items are copies of the template ones, their state is set while the menu is validated
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleMatchCase) {
            menuItem.state = findOptions.matchCase ? .on : .off
        } else if menuItem.action == #selector(selectFindMode) {
            menuItem.state = menuItem.tag == findOptions.mode.rawValue ? .on : .off
        } else if menuItem.action == #selector(toggleMatchFiles) {
            menuItem.state = findOptions.matchFiles ? .on : .off
            // the last checked file type cannot be turned off, nothing could be found anymore
            return findOptions.matchFolders || !findOptions.matchFiles
        } else if menuItem.action == #selector(toggleMatchFolders) {
            menuItem.state = findOptions.matchFolders ? .on : .off
            return findOptions.matchFiles || !findOptions.matchFolders
        }

        return true
    }

    private func menuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")

        item.target = self

        return item
    }
}
