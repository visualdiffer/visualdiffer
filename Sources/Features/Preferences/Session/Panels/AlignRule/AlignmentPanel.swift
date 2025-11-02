//
//  AlignmentPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/08/13.
//  Copyright (c) 2013 visualdiffer.com
//

class AlignmentPanel: NSView, PreferencesPanelDataSource {
    var delegate: PreferencesBoxDataSource? {
        didSet {
            fileNameCaseAlignmentBox.delegate = delegate
            userDefinedAlignRulesBox.delegate = delegate
        }
    }

    private var fileNameCaseAlignmentBox: FileNameCaseBox
    private var userDefinedAlignRulesBox: UserDefinedRulesBox

    override init(frame frameRect: NSRect) {
        fileNameCaseAlignmentBox = FileNameCaseBox(
            title: NSLocalizedString("File Name Case Alignment", comment: "")
        )
        userDefinedAlignRulesBox = UserDefinedRulesBox(
            title: NSLocalizedString("User Defined Alignment Rules", comment: "")
        )

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(fileNameCaseAlignmentBox)
        addSubview(userDefinedAlignRulesBox)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fileNameCaseAlignmentBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            fileNameCaseAlignmentBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            fileNameCaseAlignmentBox.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            fileNameCaseAlignmentBox.heightAnchor.constraint(equalToConstant: 55),

            userDefinedAlignRulesBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            userDefinedAlignRulesBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            userDefinedAlignRulesBox.topAnchor.constraint(equalTo: fileNameCaseAlignmentBox.bottomAnchor, constant: 4),
            userDefinedAlignRulesBox.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    // MARK: - Action Methods

    func reloadData() {
        fileNameCaseAlignmentBox.reloadData()
        userDefinedAlignRulesBox.reloadData()
    }
}
