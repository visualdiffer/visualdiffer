//
//  PopUpButtonURL.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/03/17.
//  Copyright (c) 2017 visualdiffer.com
//

class PopUpButtonURL: NSPopUpButton {
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

    func fill(_ documentURLs: [URL]) {
        let dict = uniq(documentURLs: documentURLs)

        // iterate documentURLs instead of the dictionary because dictionary order is not preserved
        for url in documentURLs {
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

    func clear() {
        // keep the button title and remove all other menu items
        for i in stride(from: numberOfItems - 1, through: 1, by: -1) {
            removeItem(at: i)
        }
    }

    // menu labels contain the last URL path component
    // it can appear multiple times for the same filename in different folders
    // so group by the last path component
    private func uniq(documentURLs: [URL]) -> [String: [URL]] {
        var dict = [String: [URL]]()

        for url in documentURLs {
            let key = url.lastPathComponent
            var arr = dict[key] ?? []
            arr.append(url)
            dict[key] = arr
        }
        return dict
    }
}
