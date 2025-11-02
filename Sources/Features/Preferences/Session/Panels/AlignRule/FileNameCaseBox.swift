//
//  FileNameCaseBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class FileNameCaseBox: PreferencesBox {
    private lazy var alignPopup: NSPopUpButton = {
        let view = NSPopUpButton(frame: .zero, pullsDown: true)

        view.cell = AlignPopupButtonCell(textCell: "")
        view.translatesAutoresizingMaskIntoConstraints = false

        view.target = self
        view.action = #selector(comparisonAlignChange)

        return view
    }()

    override init(title: String) {
        super.init(title: title)

        setupViews()
    }

    private func setupViews() {
        contentView?.addSubview(alignPopup)

        setupConstraints()
    }

    func setupConstraints() {
        guard let contentView else {
            return
        }
        NSLayoutConstraint.activate([
            alignPopup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            alignPopup.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            alignPopup.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            alignPopup.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 4),
        ])
    }

    @objc func comparisonAlignChange(_: AnyObject) {
        guard let item = alignPopup.selectedItem else {
            return
        }
        let alignFlags = item.tag
        delegate?.preferenceBox(self, setInteger: alignFlags, forKey: .virtualAlignFlags)
    }

    override func reloadData() {
        alignPopup.selectItem(withTag: delegate?.preferenceBox(self, integerForKey: .virtualAlignFlags) ?? 0)
        super.reloadData()
    }
}
