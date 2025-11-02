//
//  HistoryEntityTableCellView.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/07/20.
//  Copyright (c) 2020 visualdiffer.com
//

class HistoryEntityTableCellView: NSTableCellView {
    var pattern: String? {
        didSet {
            if let pattern {
                leftPath.update(pattern: pattern)
                rightPath.update(pattern: pattern)
            }
        }
    }

    private lazy var leftPath: FilePathTableCellView = createFilePathTableCellView()
    private lazy var rightPath: FilePathTableCellView = createFilePathTableCellView()
    private lazy var timeDescription: NSTextField = createTimeDescription()

    convenience init(identifier: NSUserInterfaceItemIdentifier) {
        self.init(frame: .zero)
        self.identifier = identifier
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Method not implemented")
    }

    func setup() {
        addSubview(leftPath)
        addSubview(rightPath)
        addSubview(timeDescription)

        setupConstraints()
    }

    private func createFilePathTableCellView() -> FilePathTableCellView {
        let view = FilePathTableCellView(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.textField?.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)

        return view
    }

    private func createTimeDescription() -> NSTextField {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "ddMMyyyyHHmmss",
            options: 0,
            locale: Locale.current
        )

        let view = NSTextField(frame: .zero)

        view.isBordered = false
        view.isBezeled = false
        view.drawsBackground = false
        view.isEditable = false
        view.isSelectable = false
        view.formatter = dateFormatter
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func setupConstraints() {
        guard let leftText = leftPath.textField else {
            fatalError("Can't happen")
        }
        NSLayoutConstraint.activate([
            leftPath.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            leftPath.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 4),
            leftPath.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            leftPath.heightAnchor.constraint(equalToConstant: 24),

            rightPath.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            rightPath.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightPath.topAnchor.constraint(equalTo: leftPath.bottomAnchor),
            rightPath.heightAnchor.constraint(equalToConstant: 24),

            timeDescription.leadingAnchor.constraint(equalTo: leftText.leadingAnchor),
            timeDescription.trailingAnchor.constraint(equalTo: trailingAnchor),
            timeDescription.topAnchor.constraint(equalTo: rightPath.bottomAnchor),
        ])
    }

    func setupCell(entity: HistoryEntity?) {
        guard let entity,
              let entityLeftPath = entity.leftPath,
              let entityRightPath = entity.rightPath else {
            leftPath.textField?.stringValue = ""
            rightPath.textField?.stringValue = ""
            timeDescription.stringValue = ""
            return
        }
        leftPath.update(path: entityLeftPath)
        rightPath.update(path: entityRightPath)

        timeDescription.objectValue = entity.updateTime
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            // The timeDescription color (gray) is ugly when the row is selected
            // so we change it
            if backgroundStyle == .emphasized {
                timeDescription.textColor = NSColor.controlTextColor
            } else {
                timeDescription.textColor = NSColor.secondaryLabelColor
            }
        }
    }
}
