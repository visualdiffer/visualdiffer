//
//  NSAlert+ReplaceFile.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

@MainActor
private struct ViewItemConfiguration {
    let key: ReplaceFileAttributeKey
    let view: NSTextField
    let indent: CGFloat

    init(key: ReplaceFileAttributeKey, view: NSTextField, indent: CGFloat = 0) {
        self.key = key
        self.indent = indent
        self.view = view
    }

    static let configurations: [ViewItemConfiguration] = [
        ViewItemConfiguration(
            key: .toTitle,
            view: NSTextField.hintWithTitle(
                NSLocalizedString("Would you like to replace the existing file?", comment: "")
            )
        ),

        ViewItemConfiguration(
            key: .toPath,
            view: createPathTextField(),
            indent: 30
        ),

        ViewItemConfiguration(
            key: .toSize,
            view: createNumberTextField(),
            indent: 30
        ),

        ViewItemConfiguration(
            key: .toDate,
            view: createDateTextField(),
            indent: 30
        ),

        ViewItemConfiguration(
            key: .fromTitle,
            view: NSTextField.hintWithTitle(NSLocalizedString("With this one?", comment: ""))
        ),

        ViewItemConfiguration(
            key: .fromPath,
            view: createPathTextField(),
            indent: 30
        ),

        ViewItemConfiguration(
            key: .fromSize,
            view: createNumberTextField(),
            indent: 30
        ),

        ViewItemConfiguration(
            key: .fromDate,
            view: createDateTextField(),
            indent: 30
        ),
    ]
}

extension NSAlert {
    func replaceFile(
        from info: [ReplaceFileAttributeKey: Any],
        operationOnSingleItem: Bool
    ) {
        setupIcon(info: info)
        setupButtons(operationOnSingleItem: operationOnSingleItem)
        setupMessages(info: info)
        setupAccessoryView(info: info)
    }

    func addButton(replaceFile: NSApplication.ModalResponse.ReplaceFile) {
        let button = addButton(withTitle: replaceFile.title)

        button.keyEquivalent = replaceFile.keyEquivalent
        button.tag = replaceFile.rawValue
        button.toolTip = String.localizedStringWithFormat(NSLocalizedString("Press '%@'", comment: ""), replaceFile.keyDescription)
    }

    private func setupButtons(operationOnSingleItem: Bool) {
        // Don't use three buttons otherwise NSAlert doesn't space equally buttons
        let buttons: [NSApplication.ModalResponse.ReplaceFile] = operationOnSingleItem
            ? [.no, .yes]
            : [.cancel, .noToAll, .no, .yesToAll, .yes]

        for button in buttons {
            addButton(replaceFile: button)
        }
    }

    private func setupIcon(info: [ReplaceFileAttributeKey: Any]) {
        if let toPath = info.toPath {
            icon = NSWorkspace.shared.icon(forFile: toPath)
        }
    }

    private func setupMessages(info: [ReplaceFileAttributeKey: Any]) {
        let name = if let fromPath = info.fromPath {
            URL(filePath: fromPath).lastPathComponent
        } else {
            ""
        }
        messageText = NSLocalizedString("Replace existing file?", comment: "")
        informativeText = String(format: NSLocalizedString("This folder contains a newer file named %@", comment: ""), name)
    }

    private func setupAccessoryView(info: [ReplaceFileAttributeKey: Any]) {
        accessoryView = createAccessoryView(createReplaceDetailView(info))
    }

    private func createAccessoryView(_ contentView: NSView) -> NSView {
        let contentRect = contentView.frame

        let view = NSView(frame: contentRect)
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.widthAnchor.constraint(equalToConstant: contentRect.size.width),
        ])

        return view
    }

    private func createReplaceDetailView(_ info: [ReplaceFileAttributeKey: Any]) -> NSStackView {
        let stack = NSStackView(frame: NSRect(x: 0, y: 0, width: 480, height: 200))

        stack.orientation = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        for item in ViewItemConfiguration.configurations {
            stack.addArrangedSubview(item.view)

            if item.indent > 0 {
                item.view.leadingAnchor.constraint(
                    equalTo: stack.leadingAnchor,
                    constant: item.indent
                ).isActive = true
            }

            if let obj = info[item.key] {
                item.view.objectValue = obj
            }
        }

        return stack
    }
}

@MainActor
private func createPathTextField() -> NSTextField {
    let view = NSTextField.hintWithTitle("")

    view.lineBreakMode = .byTruncatingMiddle
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
}

@MainActor
private func createNumberTextField() -> NSTextField {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal

    let view = NSTextField.hintWithTitle("")
    view.formatter = formatter
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
}

@MainActor
private func createDateTextField() -> NSTextField {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium

    let view = NSTextField.hintWithTitle("")
    view.formatter = formatter
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
}

// Private keys for internal use only
private extension ReplaceFileAttributeKey {
    static let toTitle = ReplaceFileAttributeKey(rawValue: "toTitle")
    static let fromTitle = ReplaceFileAttributeKey(rawValue: "fromTitle")
}
