//
//  PathChooser.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation
import Cocoa

@MainActor class PathChooser: NSObject, NSComboBoxDelegate {
    var currentPath: String {
        get {
            comboBox.stringValue
        }

        set {
            comboBox.stringValue = URL(filePath: newValue).standardizingPath
            dropView.filePath = comboBox.stringValue
        }
    }

    var isReadOnly: Bool {
        get {
            readOnlyButton.state == .on
        }

        set {
            readOnlyButton.state = newValue ? .on : .off
        }
    }

    var dropView: FileDropView
    lazy var chooserView: NSStackView = {
        let view = NSStackView()

        view.orientation = .horizontal
        view.alignment = .centerY
        view.spacing = 4
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var readOnlyButton: NSButton = {
        let view = NSButton(frame: .zero)

        view.title = ""
        view.toolTip = NSLocalizedString("Make read-only", comment: "")
        view.setButtonType(.switch)
        view.bezelStyle = .flexiblePush
        view.image = NSImage(named: NSImage.lockUnlockedTemplateName)
        view.alternateImage = NSImage(named: NSImage.lockLockedTemplateName)
        view.imagePosition = .imageLeft
        view.alignment = .left
        view.refusesFirstResponder = true
        view.state = .on
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var comboBox: NSComboBox = {
        let view = NSComboBox(frame: .zero)

        view.completes = true
        view.isButtonBordered = true
        view.drawsBackground = true
        view.translatesAutoresizingMaskIntoConstraints = false

        view.delegate = self
        view.target = self
        view.action = #selector(comboBoxSelectText)

        return view
    }()

    private var chooseButton: NSButton
    private var comboBoxPaths: NSArrayController

    init(
        userDefault: String,
        dropTitle: String,
        dropDelegate: FileDropImageViewDelegate,
        chooseTitle: String
    ) {
        dropView = FileDropView.create(title: dropTitle, delegate: dropDelegate)
        chooseButton = NSButton(title: chooseTitle, target: nil, action: nil)
        comboBoxPaths = NSArrayController(forUserDefault: userDefault)

        super.init()

        setupViews(dropTitle, dropDelegate: dropDelegate, chooseTitle: chooseTitle)
        bindControls()
    }

    private func setupViews(
        _: String,
        dropDelegate _: FileDropImageViewDelegate,
        chooseTitle _: String
    ) {
        chooseButton.target = self
        chooseButton.action = #selector(choosePath)

        [
            readOnlyButton,
            comboBox,
            chooseButton,
        ].forEach { chooserView.addArrangedSubview($0) }

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            readOnlyButton.leadingAnchor.constraint(equalTo: chooserView.leadingAnchor),
            readOnlyButton.topAnchor.constraint(equalTo: chooserView.topAnchor),
            readOnlyButton.bottomAnchor.constraint(equalTo: chooserView.bottomAnchor),

            comboBox.leadingAnchor.constraint(equalTo: readOnlyButton.trailingAnchor, constant: 4),
            comboBox.trailingAnchor.constraint(equalTo: chooseButton.leadingAnchor, constant: -8),
            comboBox.topAnchor.constraint(equalTo: chooserView.topAnchor),

            chooseButton.trailingAnchor.constraint(equalTo: chooserView.trailingAnchor),
            chooseButton.topAnchor.constraint(equalTo: chooserView.topAnchor),
            chooseButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])
    }

    func selectLastUsedPath() {
        guard let arr = comboBoxPaths.arrangedObjects as? [String],
              !arr.isEmpty else {
            return
        }

        comboBox.selectItem(at: 0)
        currentPath = arr[0]
    }

    @objc func choosePath(_: AnyObject) {
        let url = URL(filePath: currentPath)
        let selectedUrl = url.selectPath(
            panelTitle: NSLocalizedString("Select File or Folder", comment: ""),
            chooseFiles: true,
            chooseDirectories: true
        )

        if let selectedUrl {
            currentPath = selectedUrl.osPath
        }
    }

    func bindControls() {
        comboBox.bind(
            NSBindingName.content,
            to: comboBoxPaths,
            withKeyPath: "arrangedObjects",
            options: nil
        )
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let comboBox = notification.object as? NSComboBox,
           let filePath = comboBox.objectValueOfSelectedItem as? String {
            dropView.filePath = filePath
        }
    }

    @objc func comboBoxSelectText(_ sender: AnyObject) {
        if let comboBox = sender as? NSComboBox {
            dropView.filePath = comboBox.stringValue
        }
    }

    func addPath(_ newPath: String) {
        comboBoxPaths.addPath(newPath)
    }
}
