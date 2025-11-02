//
//  PreferencesBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class PreferencesBox: NSBox {
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

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    @objc func toggleCheckbox(_ sender: PreferencesCheckbox) {
        let isOn = sender.state == .on

        delegate?.preferenceBox(self, setBool: isOn, forKey: sender.prefName)
    }

    @objc func reloadData() {
        guard let delegate else {
            return
        }
        for checkbox in checkboxes.values {
            let value = delegate.preferenceBox(self, boolForKey: checkbox.prefName)
            checkbox.state = value ? .on : .off
            checkbox.isEnabled = delegate.preferenceBox(self, isEnabled: checkbox.prefName)
        }
    }
}
