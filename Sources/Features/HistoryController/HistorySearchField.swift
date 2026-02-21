//
//  HistorySearchField.swift
//  VisualDiffer
//
//  Created by davide ficano on 20/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

@objc
class HistorySearchField: NSSearchField, NSSearchFieldDelegate {
    @objc var historyController: HistoryController?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    func setupViews() {
        placeholderString = NSLocalizedString("Search History <⌘F>", comment: "")
        bezelStyle = .roundedBezel
        target = self
        action = #selector(search)
        translatesAutoresizingMaskIntoConstraints = false

        // used to receive NSControlTextEditingDelegate notifications
        delegate = self
    }

    @objc
    func search(_: AnyObject) {
        if let historyController {
            let pattern = stringValue.trimmingCharacters(in: NSCharacterSet.whitespaces)
            historyController.filterFor(pattern: pattern)
        }
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let historyController else {
            return false
        }
        let row = historyController.tableView.selectedRow

        if commandSelector == #selector(moveUp) {
            historyController.tableView.selectRow(closestTo: row - 1, byExtendingSelection: false, ensureVisible: true)
            return true
        } else if commandSelector == #selector(moveDown) {
            historyController.tableView.selectRow(closestTo: row + 1, byExtendingSelection: false, ensureVisible: true)
            return true
        } else if commandSelector == #selector(insertNewline) {
            historyController.delegate?.history(controller: historyController, doubleClickedEntity: nil)
            return true
        }
        return false
    }
}
