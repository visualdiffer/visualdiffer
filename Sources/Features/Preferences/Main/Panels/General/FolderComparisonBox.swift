//
//  FolderComparisonBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FolderComparisonBox: PreferencesBox {
    private lazy var comparisonPopup: NSPopUpButton = createComparisonPopup()

    private lazy var displayFiltersPopup: NSPopUpButton = createDisplayFiltersPopup()

    private lazy var finderLabelCheckButton: PreferencesCheckbox = {
        let view = PreferencesCheckbox(
            title: NSLocalizedString("Compare Finder Label", comment: ""),
            prefName: .virtualFinderLabel
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var finderTagsCheckButton: PreferencesCheckbox = {
        let view = PreferencesCheckbox(
            title: NSLocalizedString("Compare Finder Tags", comment: ""),
            prefName: .virtualFinderTags
        )
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var timeToleranceView: TimeToleranceView = {
        let view = TimeToleranceView(frame: .zero)

        view.onTextChanged = { (sender: TimeToleranceView) in
            self.delegate?.preferenceBox(
                self,
                setInteger: sender.tolerance,
                forKey: .timestampToleranceSeconds
            )
        }

        return view
    }()

    private lazy var stackView: NSStackView = .preferences(with: [
        comparisonPopup,
        finderLabelCheckButton,
        finderTagsCheckButton,
        timeToleranceView,
        displayFiltersPopup,
    ])

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        setupCheckBox(finderTagsCheckButton)
        setupCheckBox(finderLabelCheckButton)

        contentView?.addSubview(stackView)

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // setting bottomAnchor isn't necessary to explicitly setting heightAnchor
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        for view in stackView.views {
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        }

        timeToleranceView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    private func createComparisonPopup() -> NSPopUpButton {
        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.cell = ComparatorPopUpButtonCell(textCell: "")
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(updateComparatorFlags)

        return view
    }

    private func createDisplayFiltersPopup() -> NSPopUpButton {
        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.cell = DisplayFiltersPopUpButtonCell(textCell: "")
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(updateDisplayFilters)

        return view
    }

    @objc
    func updateComparatorFlags(_: AnyObject) {
        guard let comparatorFlags = comparisonPopup.selectedItem?.tag else {
            return
        }
        delegate?.preferenceBox(
            self,
            setInteger: comparatorFlags,
            forKey: .virtualComparatorWithoutMethod
        )
        updateTolerance(comparatorFlags, makeFirstResponder: true)
    }

    @objc
    func updateDisplayFilters(_: AnyObject) {
        guard let tag = displayFiltersPopup.selectedItem?.tag else {
            return
        }
        delegate?.preferenceBox(
            self,
            setInteger: tag,
            forKey: .virtualDisplayFiltersWithoutMethod
        )
    }

    @objc
    override func toggleCheckbox(_ sender: PreferencesCheckbox) {
        super.toggleCheckbox(sender)

        if sender.prefName == .virtualFinderLabel {
            // Disable tags
            finderTagsCheckButton.isEnabled = sender.state == .off
        } else if sender.prefName == .virtualFinderTags {
            // Disable label
            finderLabelCheckButton.isEnabled = sender.state == .off
        }
    }

    private func updateTolerance(
        _ comparatorOptions: Int,
        makeFirstResponder: Bool
    ) {
        let supportTolerance = ComparatorOptions(rawValue: comparatorOptions).contains(.timestamp)
        timeToleranceView.isHidden = !supportTolerance

        if supportTolerance, makeFirstResponder {
            timeToleranceView.becomeFirstResponder()
        }
    }

    override func reloadData() {
        super.reloadData()

        guard let delegate else {
            return
        }

        let comparatorOptions = delegate.preferenceBox(self, integerForKey: .virtualComparatorWithoutMethod)
        comparisonPopup.selectItem(withTag: comparatorOptions)
        updateTolerance(comparatorOptions, makeFirstResponder: false)

        let tag = delegate.preferenceBox(self, integerForKey: .virtualDisplayFiltersWithoutMethod)
        displayFiltersPopup.selectItem(withTag: tag)

        let tolerance = delegate.preferenceBox(self, integerForKey: .timestampToleranceSeconds)
        timeToleranceView.tolerance = tolerance
    }
}
