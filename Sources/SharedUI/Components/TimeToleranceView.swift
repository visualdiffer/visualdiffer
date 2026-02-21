//
//  TimeToleranceView.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class TimeToleranceView: NSView, NSTextFieldDelegate {
    private lazy var inputText: NSTextField = createInputText()
    private lazy var stepper: NSStepper = createStepper()

    var onTextChanged: ((TimeToleranceView) -> Void)?

    var tolerance = 0 {
        didSet {
            if let onTextChanged {
                onTextChanged(self)
            }
            inputText.integerValue = tolerance
            stepper.integerValue = tolerance
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    private func setupViews() {
        addSubview(createStackView())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    private func createStackView() -> NSStackView {
        let view = NSStackView(views: [
            createTextWithTitle(NSLocalizedString("Ignore differences of", comment: "")),
            inputText,
            stepper,
            createTextWithTitle(NSLocalizedString("seconds or less", comment: "")),
        ])
        view.orientation = .horizontal
        view.alignment = .centerY
        view.spacing = 4

        return view
    }

    private func createTextWithTitle(_ title: String) -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.stringValue = title
        view.isEditable = false
        view.isSelectable = false
        view.drawsBackground = false
        view.isBordered = false

        return view
    }

    private func createInputText() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.alignment = .right
        view.cell?.sendsActionOnEndEditing = true
        view.formatter = IntegerFormatter()

        view.delegate = self
        view.widthAnchor.constraint(equalToConstant: 40).isActive = true

        return view
    }

    private func createStepper() -> NSStepper {
        let view = NSStepper(frame: .zero)

        view.autorepeat = true
        view.minValue = 0
        view.maxValue = 100
        view.increment = 1

        view.target = self
        view.action = #selector(stepperChanged)

        return view
    }

    @objc
    func stepperChanged(_: AnyObject) {
        tolerance = stepper.integerValue
    }

    func controlTextDidChange(_: Notification) {
        tolerance = inputText.integerValue
    }

    func control(_: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // arrow up and down are used to increment and decrement current value
        if commandSelector == #selector(moveUp) {
            tolerance += 1
            textView.selectAll(nil)
            return true
        } else if commandSelector == #selector(moveDown) {
            if tolerance > 0 {
                tolerance -= 1
            }
            textView.selectAll(nil)
            return true
        }
        return false
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        inputText.becomeFirstResponder()
    }
}
