//
//  PathView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

class PathView: NSView {
    var isEnabled = false {
        didSet {
            for view in stackView.views {
                if let control = view as? NSControl {
                    control.isEnabled = isEnabled
                }
            }
        }
    }

    var isSaveHidden: Bool {
        get {
            saveButton.isHidden
        }

        set {
            saveButton.isHidden = newValue
        }
    }

    var delegate: PathControlDelegate? {
        get {
            pathControl.delegate as? PathControlDelegate
        }

        set {
            pathControl.delegate = newValue
            if let delegate = newValue {
                let canPerform = delegate.responds(to: #selector(PathControlDelegate.saveFile))
                if canPerform {
                    saveButton.target = delegate
                    saveButton.action = #selector(PathControlDelegate.saveFile)
                }
            } else {
                saveButton.target = nil
                saveButton.action = nil
            }
        }
    }

    lazy var lockButton: NSButton = createLockButton()
    lazy var pathControl: PathControl = createPathControl()
    lazy var browseButton: NSButton = createBrowseButton()
    lazy var saveButton: NSButton = createSaveButton()

    private lazy var stackView: NSStackView = createStackView()
    private lazy var separator: NSBox = createSeparator()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        setupStackView()

        addSubview(stackView)
        setupConstraints()

        // enable iterates the views so we must set it only after all views are added to self
        isEnabled = true
    }

    private func setupStackView() {
        stackView.addArrangedSubview(lockButton)
        stackView.addArrangedSubview(pathControl)
        stackView.addArrangedSubview(separator)
        stackView.addArrangedSubview(browseButton)
        stackView.addArrangedSubview(saveButton)
        stackView.setCustomSpacing(6, after: separator)
        stackView.setCustomSpacing(4, after: browseButton)
    }

    private func createLockButton() -> NSButton {
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

        return view
    }

    private func createPathControl() -> PathControl {
        let view = PathControl(frame: .zero)

        view.controlSize = .small
        view.isEditable = false
        view.refusesFirstResponder = true
        view.alignment = .left
        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        return view
    }

    private func createBrowseButton() -> NSButton {
        guard let image = NSImage(named: VDImageNameBrowse) else {
            fatalError("Unable to create image for \(VDImageNameBrowse)")
        }
        let view = NSButton(
            image: image,
            target: pathControl,
            action: #selector(PathControl.choosePath)
        )

        view.toolTip = NSLocalizedString("Choose Path", comment: "")
        view.isBordered = false
        view.refusesFirstResponder = true

        return view
    }

    private func createSaveButton() -> NSButton {
        guard let image = NSImage(named: VDImageNameSave) else {
            fatalError("Unable to create image for \(VDImageNameSave)")
        }
        let view = NSButton(
            image: image,
            target: nil,
            action: nil
        )

        view.toolTip = NSLocalizedString("Save ^S", comment: "")
        view.isBordered = false
        view.refusesFirstResponder = true

        return view
    }

    private func createSeparator() -> NSBox {
        let view = NSBox(frame: .zero)

        view.title = ""
        view.boxType = .separator
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createStackView() -> NSStackView {
        let stack = NSStackView()

        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 2.0
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            separator.topAnchor.constraint(equalTo: stackView.topAnchor),
            separator.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
    }

    func bindControls(side: DisplaySide) {
        guard let delegate = pathControl.delegate else {
            return
        }
        // We enable the views ourselves but when NSConditionallySetsEnabledBindingOption is true (the default)
        // they are automagically enabled by the binding system so we turn off the NSConditionallySetsEnabledBindingOption flag
        let pathControlBindOptions = [
            NSBindingOption.conditionallySetsEnabled: false,
        ]

        if side == .left {
            lockButton.bind(
                .value,
                to: delegate,
                withKeyPath: "sessionDiff.leftReadOnly",
                options: nil
            )
            pathControl.bind(
                .value,
                to: delegate,
                withKeyPath: "sessionDiff.leftPath",
                options: pathControlBindOptions
            )
            if !saveButton.isHidden {
                saveButton.bind(
                    .enabled,
                    to: delegate,
                    withKeyPath: "leftView.isDirty",
                    options: nil
                )
            }
        } else {
            lockButton.bind(
                .value,
                to: delegate,
                withKeyPath: "sessionDiff.rightReadOnly",
                options: nil
            )
            pathControl.bind(
                .value,
                to: delegate,
                withKeyPath: "sessionDiff.rightPath",
                options: pathControlBindOptions
            )
            if !saveButton.isHidden {
                saveButton.bind(
                    .enabled,
                    to: delegate,
                    withKeyPath: "rightView.isDirty",
                    options: nil
                )
            }
        }
    }
}
