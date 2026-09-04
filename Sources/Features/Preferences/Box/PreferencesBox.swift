//
//  PreferencesBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class PreferencesBox: NSBox {
    static let minPopupWidth: CGFloat = 140

    private var defaultDelegate: StandardUserPreferencesBoxDataSource
    private var checkboxes: [CommonPrefs.Name: PreferencesCheckbox]

    var delegate: PreferencesBoxDataSource?

    init(title: String) {
        defaultDelegate = StandardUserPreferencesBoxDataSource()
        delegate = defaultDelegate
        checkboxes = [:]

        super.init(frame: .zero)

        self.title = title
        setupViews()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    private func setupViews() {
        titleFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        titlePosition = .atTop
        boxType = .primary
        translatesAutoresizingMaskIntoConstraints = false
    }

    func createCheckBox(
        title: String,
        prefName: CommonPrefs.Name,
        isNegated: Bool = false
    ) -> PreferencesCheckbox {
        let view = PreferencesCheckbox(title: title, prefName: prefName, isNegated: isNegated)

        setupCheckBox(view)

        return view
    }

    func setupCheckBox(_ checkbox: PreferencesCheckbox) {
        checkbox.target = self
        checkbox.action = #selector(toggleCheckbox)

        checkboxes[checkbox.prefName] = checkbox
    }

    @objc
    func toggleCheckbox(_ sender: PreferencesCheckbox) {
        let isOn = sender.state == .on

        delegate?.preferenceBox(self, setBool: isOn, forKey: sender.prefName)
    }

    @objc
    func reloadData() {
        guard let delegate else {
            return
        }

        for checkbox in checkboxes.values {
            let value = delegate.preferenceBox(self, boolForKey: checkbox.prefName)
            checkbox.state = value ? .on : .off
            checkbox.isEnabled = delegate.preferenceBox(self, isEnabled: checkbox.prefName)
        }
    }

    // a popup carries no minimum of its own, this is what makes the box declare the width it
    // needs, defaultHigh because NSTabView lays the panel out at 20 points while still detached
    // and a required minimum could not hold there
    func popupMinWidthConstraint(_ popup: NSPopUpButton) -> NSLayoutConstraint {
        let constraint = popup.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minPopupWidth)
        constraint.priority = .defaultHigh

        return constraint
    }
}
