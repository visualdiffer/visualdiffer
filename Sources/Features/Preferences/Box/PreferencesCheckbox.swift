//
//  PreferencesCheckbox.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class PreferencesCheckbox: NSButton {
    private(set) var prefName: CommonPrefs.Name
    private(set) var isNegated = false

    init(
        title: String,
        prefName: CommonPrefs.Name,
        isNegated: Bool = false
    ) {
        self.prefName = prefName
        self.isNegated = isNegated
        super.init(frame: .zero)

        self.title = title
        setButtonType(.switch)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var state: NSControl.StateValue {
        get {
            var isChecked = super.state == .on
            if isNegated {
                isChecked.toggle()
            }
            return isChecked ? .on : .off
        }

        set {
            var isChecked = newValue == .on
            if isNegated {
                isChecked.toggle()
            }
            super.state = isChecked ? .on : .off
        }
    }
}
