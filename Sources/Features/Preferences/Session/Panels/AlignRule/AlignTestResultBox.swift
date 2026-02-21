//
//  AlignTestResultBox.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

class AlignTestResultBox: NSBox, NSTextFieldDelegate {
    private let fileNameTitle: NSTextField
    private let fileName: NSTextField
    private let outputTitle: NSTextField
    private let output: NSTextField
    private let errorMessage: NSTextField

    @objc var leftExpression: String
    @objc var rightExpression: String
    @objc var regularExpressionOptions: NSRegularExpression.Options

    @objc
    convenience init(title: String) {
        self.init(frame: .zero)

        self.title = title
        titleFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        titlePosition = .atTop
        boxType = .primary
        translatesAutoresizingMaskIntoConstraints = false
    }

    override init(frame frameRect: NSRect) {
        fileNameTitle = NSTextField.labelWithTitle(NSLocalizedString("File name", comment: ""))
        fileName = NSTextField(frame: .zero)
        outputTitle = NSTextField.labelWithTitle(NSLocalizedString("Result", comment: ""))
        output = NSTextField(frame: .zero)
        errorMessage = NSTextField.labelWithTitle("")

        leftExpression = ""
        rightExpression = ""
        regularExpressionOptions = []

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        fileNameTitle.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        fileName.placeholderString = NSLocalizedString("Enter a file name to test the rule", comment: "")
        fileName.translatesAutoresizingMaskIntoConstraints = false
        fileName.delegate = self

        outputTitle.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        output.translatesAutoresizingMaskIntoConstraints = false

        errorMessage.placeholderString = NSLocalizedString("No errors.", comment: "")
        errorMessage.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        errorMessage.translatesAutoresizingMaskIntoConstraints = false

        if let contentView {
            contentView.addSubview(fileNameTitle)
            contentView.addSubview(fileName)

            contentView.addSubview(outputTitle)
            contentView.addSubview(output)

            contentView.addSubview(errorMessage)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView else {
            return
        }

        NSLayoutConstraint.activate([
            fileNameTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            fileNameTitle.topAnchor.constraint(equalTo: contentView.topAnchor),
            fileNameTitle.widthAnchor.constraint(equalToConstant: 60),

            fileName.leadingAnchor.constraint(equalTo: fileNameTitle.trailingAnchor, constant: 5),
            fileName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            fileName.topAnchor.constraint(equalTo: fileNameTitle.topAnchor),

            outputTitle.leadingAnchor.constraint(equalTo: fileNameTitle.leadingAnchor),
            outputTitle.topAnchor.constraint(equalTo: fileNameTitle.bottomAnchor, constant: 10),
            outputTitle.widthAnchor.constraint(equalToConstant: 60),

            output.leadingAnchor.constraint(equalTo: outputTitle.trailingAnchor, constant: 5),
            output.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            output.topAnchor.constraint(equalTo: outputTitle.topAnchor),

            errorMessage.leadingAnchor.constraint(equalTo: fileNameTitle.leadingAnchor),
            errorMessage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            errorMessage.topAnchor.constraint(equalTo: output.bottomAnchor, constant: 5),
        ])
    }

    func controlTextDidChange(_: Notification) {
        reloadData()
    }

    @objc
    func reloadData() {
        output.stringValue = ""
        errorMessage.stringValue = ""

        if leftExpression.isEmpty, rightExpression.isEmpty {
            return
        }

        do {
            let re = try NSRegularExpression(
                pattern: leftExpression,
                options: regularExpressionOptions
            )
            let result = re.firstMatch(
                in: fileName.stringValue,
                options: [],
                range: NSRange(location: 0, length: fileName.stringValue.count)
            )
            if let result {
                let rightExpr = rightExpression
                output.stringValue = fileName.stringValue.replace(
                    template: rightExpr,
                    result: result
                )
            }
        } catch {
            errorMessage.stringValue = String(format: NSLocalizedString("Regexp error: %@", comment: ""), error.localizedDescription)
            return
        }
    }

    @objc
    func clear() {
        fileName.stringValue = ""
        output.stringValue = ""
    }
}
