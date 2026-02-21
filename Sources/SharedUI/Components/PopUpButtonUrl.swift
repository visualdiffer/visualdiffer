//
//  PopUpButtonUrl.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/03/17.
//  Copyright (c) 2017 visualdiffer.com
//

class PopUpButtonUrl: NSPopUpButton {
    init(
        title: String,
        target: AnyObject?,
        action: Selector?,
        delegate: NSMenuDelegate?
    ) {
        super.init(frame: .zero, pullsDown: true)

        let menu = NSMenu(title: title)
        menu.delegate = delegate
        menu.addItem(
            withTitle: title,
            action: nil,
            keyEquivalent: ""
        )

        bezelStyle = .texturedRounded
        setButtonType(.momentaryPushIn)
        alignment = .center
        self.target = target
        self.action = action
        self.menu = menu
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func fill(_ documentUrls: [URL]) {
        let dict = uniq(documentUrls: documentUrls)

        // iterate documentURLs instead of dictionary because order is not preserved in dictionary
        for url in documentUrls {
            let key = url.lastPathComponent
            guard let arr = dict[key] else {
                continue
            }

            if arr.count == 1 {
                addItem(withTitle: key)
                lastItem?.representedObject = url
            } else {
                for dup in arr {
                    let components = dup.pathComponents
                    if components.count >= 2 {
                        addItem(withTitle: String(format: "% - %", key, components[components.count - 2]))
                    } else {
                        addItem(withTitle: key)
                    }
                    lastItem?.representedObject = url
                }
            }
        }
    }

    @objc
    func clear() {
        // leave the button title and remove all other menu items
        for i in stride(from: numberOfItems - 1, through: 1, by: -1) {
            removeItem(at: i)
        }
    }

    // menu label contains the last URL path component
    // It would be present more times (same filename in different disk folders)
    // so we group by last path component
    private func uniq(documentUrls: [URL]) -> [String: [URL]] {
        var dict = [String: [URL]]()

        for url in documentUrls {
            let key = url.lastPathComponent
            var arr = dict[key] ?? []
            arr.append(url)
            dict[key] = arr
        }
        return dict
    }
}
