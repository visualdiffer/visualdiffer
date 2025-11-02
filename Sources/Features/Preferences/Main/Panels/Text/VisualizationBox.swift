//
//  VisualizationBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

class VisualizationBox: PreferencesBox, NSTextFieldDelegate {
    private lazy var tabWidthTitle: NSTextField = createTabWidthTitle()
    private lazy var tabWidthInput: NSTextField = createTabWidthInput()
    private lazy var tabWidthStepper: NSStepper = createTabWidthStepper()

    var tabWidth = 0 {
        didSet {
            CommonPrefs.shared.tabWidth = tabWidth
            tabWidthStepper.integerValue = tabWidth
            tabWidthInput.integerValue = tabWidth
        }
    }

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    func setupViews() {
        if let contentView {
            contentView.addSubview(tabWidthTitle)
            contentView.addSubview(tabWidthInput)
            contentView.addSubview(tabWidthStepper)
        }

        setupConstraints()
    }

    private func createTabWidthTitle() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = NSLocalizedString("Tab Width", comment: "")
        view.isEditable = false
        view.isSelectable = false
        view.drawsBackground = false
        view.isBordered = false
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func createTabWidthInput() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.alignment = .right
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cell?.sendsActionOnEndEditing = true
        view.formatter = IntegerFormatter()
        view.delegate = self

        return view
    }

    private func createTabWidthStepper() -> NSStepper {
        let view = NSStepper(frame: .zero)

        view.autorepeat = true
        view.minValue = 1
        view.maxValue = 100
        view.increment = 1
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(tabWidthStepperChanged)

        return view
    }

    func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            tabWidthTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            tabWidthTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            tabWidthInput.leadingAnchor.constraint(equalTo: tabWidthTitle.trailingAnchor, constant: 2),
            tabWidthInput.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            tabWidthInput.widthAnchor.constraint(equalToConstant: 40),

            tabWidthStepper.leadingAnchor.constraint(equalTo: tabWidthInput.trailingAnchor, constant: 2),
            tabWidthStepper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
        ])
    }

    @objc func tabWidthStepperChanged(_: AnyObject) {
        tabWidth = tabWidthStepper.integerValue
    }

    func controlTextDidChange(_: Notification) {
        tabWidth = tabWidthInput.integerValue
    }

    func control(_: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // arrow up and down are used to increment and decrement current value
        if commandSelector == #selector(moveUp) {
            tabWidth += 1
            textView.selectAll(nil)
            return true
        } else if commandSelector == #selector(moveDown) {
            if tabWidth > 0 {
                tabWidth -= 1
            }
            textView.selectAll(nil)
            return true
        }
        return false
    }

    override func reloadData() {
        tabWidth = CommonPrefs.shared.tabWidth
    }
}
