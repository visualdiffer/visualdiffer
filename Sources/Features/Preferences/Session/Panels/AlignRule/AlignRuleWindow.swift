//
//  AlignRuleWindow.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

class AlignRuleWindow: NSWindow, NSTextFieldDelegate {
    enum Mode {
        case insert
        case update
    }

    var alignRules = [AlignRule]()
    var mode = Mode.insert

    var editedRule: AlignRule?

    private var leftOptions: NSRegularExpression.Options = []
    private var rightOptions: AlignTemplateOptions = []

    private lazy var leftExpressionBox: ExpressionBox = {
        let view = ExpressionBox(
            title: NSLocalizedString("Left file name matches regular expression", comment: "")
        )
        view.delegate = self
        view.popupMenu = ExpressionBox.defaultRegExpMenu

        return view
    }()

    private lazy var rightExpressionBox: ExpressionBox = {
        let view = ExpressionBox(
            title: NSLocalizedString("Right file name matches pattern (this is not a regular expression)", comment: "")
        )
        view.delegate = self
        view.popupMenu = ExpressionBox.defaultRightExpressionMenu

        return view
    }()

    private lazy var testBox: AlignTestResultBox = .init(
        title: NSLocalizedString("Test Rule", comment: "")
    )
    private lazy var standardButtons: StandardButtons = .init(
        primaryTitle: NSLocalizedString("Add", comment: ""),
        secondaryTitle: NSLocalizedString("Cancel", comment: ""),
        target: self,
        action: #selector(closeAlignWindow)
    )

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )

        minSize = NSSize(width: 480, height: 300)
        setupViews()
    }

    private func setupViews() {
        if let contentView {
            contentView.addSubview(leftExpressionBox)
            contentView.addSubview(rightExpressionBox)
            contentView.addSubview(testBox)
            contentView.addSubview(standardButtons)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            leftExpressionBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            leftExpressionBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            leftExpressionBox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            leftExpressionBox.heightAnchor.constraint(equalToConstant: 60),

            rightExpressionBox.leadingAnchor.constraint(equalTo: leftExpressionBox.leadingAnchor),
            rightExpressionBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rightExpressionBox.topAnchor.constraint(equalTo: leftExpressionBox.bottomAnchor, constant: 10),
            rightExpressionBox.heightAnchor.constraint(equalToConstant: 60),

            testBox.leadingAnchor.constraint(equalTo: leftExpressionBox.leadingAnchor),
            testBox.trailingAnchor.constraint(equalTo: leftExpressionBox.trailingAnchor),
            testBox.topAnchor.constraint(equalTo: rightExpressionBox.bottomAnchor, constant: 10),
            testBox.heightAnchor.constraint(equalToConstant: 100),

            standardButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    func beginSheet(
        _ sheetWindow: NSWindow,
        alignRule: AlignRule,
        mode: Mode,
        completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil
    ) {
        editedRule = alignRule
        self.mode = mode

        fillUI(alignRule)

        sheetWindow.beginSheet(self, completionHandler: handler)
        // The sheet isn't destroyed so when it is reopen the first responder
        // corresponds to the last set when sheet was closed
        leftExpressionBox.becomeFirstResponder()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_: Notification) {
        updateTestResult()
    }

    // MARK: - Private methods

    private func fillUI(_ alignRule: AlignRule) {
        standardButtons.primaryButton.title = mode == .insert ? NSLocalizedString("Add", comment: "") : NSLocalizedString("Update", comment: "")

        // make a local copy of all values, so we can compare them with current rule to find changes
        leftExpressionBox.text = alignRule.regExp.pattern
        rightExpressionBox.text = alignRule.template.pattern
        leftOptions = alignRule.regExp.options
        rightOptions = alignRule.template.options

        testBox.clear()
    }

    private func updateTestResult() {
        testBox.leftExpression = leftExpressionBox.text
        testBox.rightExpression = rightExpressionBox.text
        testBox.regularExpressionOptions = leftOptions
        testBox.reloadData()
    }

    private func validateRule() throws {
        let strLeftExpression = leftExpressionBox.text
        let strRightExpression = rightExpressionBox.text

        if strLeftExpression.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
            throw AlignRuleError.emptyExpression(isLeft: true)
        }

        do {
            _ = try NSRegularExpression(
                pattern: strLeftExpression,
                options: leftOptions
            )
        } catch {
            throw AlignRuleError.invalidRegularExpression(error: error)
        }

        if strRightExpression.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
            throw AlignRuleError.emptyExpression(isLeft: false)
        }

        // check if current rule already exists
        if mode == .insert {
            let item = alignRules.first {
                $0.regExp.pattern == strLeftExpression &&
                    $0.regExp.options == leftOptions &&
                    $0.template.pattern == strRightExpression &&
                    $0.template.options == rightOptions
            }

            if item != nil {
                throw AlignRuleError.ruleAlreadyExists
            }
        }
    }

    // MARK: - Action methods

    @objc
    func closeAlignWindow(_ sender: AnyObject) {
        guard let sender = sender as? NSButton else {
            return
        }
        editedRule = nil
        if sender === standardButtons.primaryButton {
            do {
                try validateRule()
                editedRule = AlignRule(
                    regExp: AlignRegExp(pattern: leftExpressionBox.text, options: leftOptions),
                    template: AlignTemplate(pattern: rightExpressionBox.text, options: rightOptions)
                )
            } catch {
                let alert = NSAlert()

                alert.messageText = NSLocalizedString("Rule cannot be saved", comment: "")
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()

                // do not close the window
                return
            }
        }

        sheetParent?.endSheet(self, returnCode: .init(sender.tag))
    }

    @objc
    func toggleLeftExpressionCaseSensitive(_: AnyObject) {
        if leftOptions.contains(.caseInsensitive) {
            leftOptions.remove(.caseInsensitive)
        } else {
            leftOptions.insert(.caseInsensitive)
        }
        updateTestResult()
    }

    @objc
    func toggleRightExpressionCaseSensitive(_: AnyObject) {
        if rightOptions.contains(.caseInsensitive) {
            rightOptions.remove(.caseInsensitive)
        } else {
            rightOptions.insert(.caseInsensitive)
        }
        updateTestResult()
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let action = menuItem.action

        if action == #selector(toggleLeftExpressionCaseSensitive) {
            menuItem.state = leftOptions.contains(.caseInsensitive) ? .on : .off
        } else if action == #selector(toggleRightExpressionCaseSensitive) {
            menuItem.state = rightOptions.contains(.caseInsensitive) ? .on : .off
        }
        return true
    }
}

extension AlignRuleWindow {
    static func createSheet() -> AlignRuleWindow {
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
        ]

        return AlignRuleWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
    }

    private enum AlignRuleError: LocalizedError {
        case emptyExpression(isLeft: Bool)
        case ruleAlreadyExists
        case invalidRegularExpression(error: Error)

        var errorDescription: String? {
            switch self {
            case let .emptyExpression(isLeft):
                isLeft
                    // swiftlint:disable:next void_function_in_ternary
                    ? NSLocalizedString("Left expression can't be empty", comment: "")
                    : NSLocalizedString("Right expression can't be empty", comment: "")
            case .ruleAlreadyExists:
                NSLocalizedString("An identical rule already exists", comment: "")
            case let .invalidRegularExpression(error):
                String(
                    format: NSLocalizedString("Regular expression doesn't compile: %@", comment: ""),
                    error.localizedDescription
                )
            }
        }
    }
}
