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
}

class FindText: NSView, NSSearchFieldDelegate {
    private var lastIndexFound = -1

    var delegate: FindTextDelegate?

    private lazy var rewindView: WindowOSD = .init(
        // swiftlint:disable:next force_unwrapping
        image: NSImage(named: VDImageNameRewind)!,
        parent: window
    )

    private lazy var arrows: NSSegmentedControl = {
        let images = [
            // swiftlint:disable:next force_unwrapping
            NSImage(named: NSImage.goLeftTemplateName)!,
            // swiftlint:disable:next force_unwrapping
            NSImage(named: NSImage.goRightTemplateName)!,
        ]
        let view = NSSegmentedControl(
            images: images,
            trackingMode: .momentary,
            target: self,
            action: #selector(moveByArrow)
        )

        view.segmentStyle = .roundRect
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

        view.placeholderString = NSLocalizedString("Find File Name <⌘F>", comment: "")
        view.bezelStyle = .roundedBezel
        view.controlSize = .small
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

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupView()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(searchField)
        addSubview(arrows)
        addSubview(countLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            searchField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchField.widthAnchor.constraint(equalToConstant: 240),

            arrows.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            arrows.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            arrows.trailingAnchor.constraint(equalTo: searchField.leadingAnchor, constant: -2),

            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
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

    @objc func search(_: AnyObject) {
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

    @objc func moveByArrow(_: AnyObject) {
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
}
