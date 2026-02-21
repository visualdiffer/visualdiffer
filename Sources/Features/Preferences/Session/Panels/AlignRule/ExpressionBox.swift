//
//  ExpressionBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ExpressionBox: NSBox {
    var delegate: NSTextFieldDelegate? {
        get {
            expression.delegate
        }

        set {
            expression.delegate = newValue
        }
    }

    var popupMenu: NSMenu? {
        get {
            popup.menu
        }

        set {
            popup.menu = newValue
            // must be done only *after* setting the menu otherwise doesn't work
            expression.attachTo(popUpButton: popup)
        }
    }

    var text: String {
        get {
            expression.stringValue
        }

        set {
            expression.stringValue = newValue
        }
    }

    private lazy var expression: TextFieldSelectionHolder = {
        let view = TextFieldSelectionHolder(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var popup: NSPopUpButton = createPopUpButton()

    convenience init(title: String) {
        self.init(frame: .zero)

        self.title = title
        titleFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        titlePosition = .atTop
        boxType = .primary
        translatesAutoresizingMaskIntoConstraints = false
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView?.addSubview(expression)
        contentView?.addSubview(popup)

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            expression.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            expression.trailingAnchor.constraint(equalTo: popup.leadingAnchor, constant: -4),
            expression.topAnchor.constraint(equalTo: contentView.topAnchor),

            popup.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            popup.topAnchor.constraint(equalTo: expression.topAnchor),
        ])
    }

    private func createPopUpButton() -> NSPopUpButton {
        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    @objc
    func insertRegExp(_ sender: AnyObject) {
        guard let shortcut = sender.representedObject as? String,
              let editor = expression.currentEditor() else {
            return
        }
        let ellipsis = "..."
        let pattern = expression.stringValue

        if let ellipsisRange = shortcut.range(of: ellipsis) {
            let selectedRange = editor.selectedRange
            if selectedRange.length > 0 {
                if let range = Range(selectedRange, in: pattern) {
                    let selectionText = pattern[range]
                    let shortcutReplaced = shortcut.replacingOccurrences(of: ellipsis, with: selectionText)
                    let modified = pattern.replacingCharacters(in: range, with: shortcutReplaced)

                    // thanks Apple to make string manipulation so complicated!!
                    let location = shortcut.distance(from: shortcut.startIndex, to: ellipsisRange.lowerBound)
                    let newLowerBound = modified.index(range.lowerBound, offsetBy: location)
                    let selectionRange = NSRange(newLowerBound ... range.upperBound, in: modified)

                    // now select the string
                    editor.string = modified
                    editor.selectedRange = selectionRange
                }
            } else {
                editor.replaceCharacters(in: selectedRange, with: shortcut)

                let location = shortcut.distance(from: shortcut.startIndex, to: ellipsisRange.lowerBound)
                editor.selectedRange = NSRange(location: selectedRange.location + location, length: ellipsis.count)
            }
        } else {
            editor.insertText(shortcut)
        }
    }

    @objc
    func appendGroupExpression(_ sender: AnyObject) {
        if let sender = sender as? NSMenuItem,
           let text = sender.representedObject,
           let editor = expression.currentEditor() {
            editor.insertText(text)
        }
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        expression.becomeFirstResponder()
    }
}
