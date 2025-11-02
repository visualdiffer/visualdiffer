//
//  ExpressionBox+Menu.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension ExpressionBox {
    @objc static var defaultRightExpressionMenu: NSMenu {
        let menu = NSMenu()

        // the button title image
        menu.addItem(
            withTitle: "",
            action: nil,
            keyEquivalent: ""
        )
        .image = NSImage(named: NSImage.actionTemplateName)

        menu.addItem(
            withTitle: NSLocalizedString("Ignore Case", comment: ""),
            action: #selector(AlignRuleWindow.toggleRightExpressionCaseSensitive),
            keyEquivalent: ""
        )
        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            withTitle: NSLocalizedString("Matched Range $0", comment: ""),
            action: #selector(appendGroupExpression),
            keyEquivalent: ""
        )
        .representedObject = "$0"

        for i in 1 ..< 10 {
            menu.addItem(
                withTitle: String(format: NSLocalizedString("Capture Group $%ld", comment: ""), i),
                action: #selector(appendGroupExpression),
                keyEquivalent: ""
            )
            .representedObject = String(format: "$%ld", i)
        }

        return menu
    }

    @objc static var defaultRegExpMenu: NSMenu {
        let menu = NSMenu()

        // the button title image
        menu.addItem(
            withTitle: "",
            action: nil,
            keyEquivalent: ""
        )
        .image = NSImage(named: NSImage.actionTemplateName)

        menu.addItem(
            withTitle: NSLocalizedString("Ignore Case", comment: ""),
            action: #selector(AlignRuleWindow.toggleLeftExpressionCaseSensitive),
            keyEquivalent: ""
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: NSLocalizedString("Regular Expression Special Characters", comment: ""),
            action: nil,
            keyEquivalent: ""
        )

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: NSLocalizedString(". : any character except a newline", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "."
        menu.addItem(
            withTitle: NSLocalizedString("\\d : any decimal digit", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\d"
        menu.addItem(
            withTitle: NSLocalizedString("\\D : any non-digit", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\D"
        menu.addItem(
            withTitle: NSLocalizedString("\\s : any whitespace character", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\s"
        menu.addItem(
            withTitle: NSLocalizedString("\\S : any non-whitespace character", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\S"
        menu.addItem(
            withTitle: NSLocalizedString("\\w : any alphanumeric character", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\w"
        menu.addItem(
            withTitle: NSLocalizedString("\\W : any non-alphanumeric character", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\W"

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: NSLocalizedString("* : zero or more of the preceding block", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "*"
        menu.addItem(
            withTitle: NSLocalizedString("*? : zero or more of the preceding block (non-greedy)", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "*?"
        menu.addItem(
            withTitle: NSLocalizedString("+ : one or more of the preceding block", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "+"
        menu.addItem(
            withTitle: NSLocalizedString("+? : one or more of the preceding block (non-greedy)", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "+?"
        menu.addItem(
            withTitle: NSLocalizedString("? : zero or one of the preceding block", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "?"
        menu.addItem(
            withTitle: NSLocalizedString("?? : zero or one of the preceding block (non-greedy)", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "??"
        menu.addItem(
            withTitle: NSLocalizedString("{m} : exactly 'm' copies of the preceding block", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "{m}"
        menu.addItem(
            withTitle: NSLocalizedString("{m,n} : 'm' to 'n' copies of the preceding block", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "{m,n}"
        menu.addItem(
            withTitle: NSLocalizedString("{m,n}? : 'm' to 'n' copies of the preceding block (non-greedy)", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "{m,n}?"

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: NSLocalizedString("^ : beginning of line", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "^"
        menu.addItem(
            withTitle: NSLocalizedString("$ : end of line", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "$"
        menu.addItem(
            withTitle: NSLocalizedString("\\b : the beginning or end of a word", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\b"
        menu.addItem(
            withTitle: NSLocalizedString("\\B : anything BUT the beginning or end of a word", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\B"
        menu.addItem(
            withTitle: NSLocalizedString("\\A : beginning of the string", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "\\A"

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: NSLocalizedString("(...) : group", comment: ""),
            action: #selector(insertRegExp),
            keyEquivalent: ""
        )
        .representedObject = "(...)"

        return menu
    }
}
