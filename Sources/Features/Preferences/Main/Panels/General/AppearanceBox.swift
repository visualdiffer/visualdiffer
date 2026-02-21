//
//  AppearanceBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class AppearanceBox: PreferencesBox {
    private lazy var appearancePopup: NSPopUpButton = createAppearancePopup()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        contentView?.addSubview(appearancePopup)

        setupConstraints()
    }

    private func createAppearancePopup() -> NSPopUpButton {
        let menu = NSMenu()

        menu.addItem(withTitle: NSLocalizedString("System", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: NSLocalizedString("Light", comment: ""), action: nil, keyEquivalent: "").tag = 1
        menu.addItem(withTitle: NSLocalizedString("Dark", comment: ""), action: nil, keyEquivalent: "").tag = 2

        let view = NSPopUpButton(frame: .zero)
        view.menu = menu
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(updateAppearance)

        return view
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            appearancePopup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            appearancePopup.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            appearancePopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
        ])
    }

    @objc
    func updateAppearance(_: AnyObject) {
        if #available(macOS 10.14, *) {
            if !alertForCustomColorScheme() {
                // restore the previous selection
                appearancePopup.selectItem(withTag: UserDefaults.standard.integer(forKey: "appAppearance"))
                return
            }

            guard let tag = appearancePopup.selectedItem?.tag else {
                return
            }
            switch tag {
            case 0:
                if UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
                    NSApp.appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
                } else {
                    NSApp.appearance = nil
                }
                UserDefaults.standard.removeObject(forKey: "appAppearance")
            case 1:
                NSApp.appearance = NSAppearance(named: NSAppearance.Name.aqua)
                UserDefaults.standard.setValue(tag, forKey: "appAppearance")
            case 2:
                NSApp.appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
                UserDefaults.standard.setValue(tag, forKey: "appAppearance")
            default:
                break
            }
        }
    }

    private func alertForCustomColorScheme() -> Bool {
        if CommonPrefs.shared.colorsConfigPath == nil {
            return true
        }
        return NSAlert.showModalConfirm(
            messageText: NSLocalizedString("The app is using a custom color scheme that will continue to be used when changing appearance. Colors may not be suitable for the new appearance. Are you sure?", comment: ""),
            informativeText: ""
        )
    }

    override func reloadData() {
        if #available(macOS 10.14, *) {
            appearancePopup.selectItem(withTag: UserDefaults.standard.integer(forKey: "appAppearance"))
        } else {
            appearancePopup.isEnabled = false
        }
    }
}
