//
//  CompletionIndicator.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class CompletionIndicator: NSStackView {
    lazy var progress: NSProgressIndicator = .bar()
    lazy var text: NSTextField = createCompletedText()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addArrangedSubviews([
            progress,
            text,
        ])
        orientation = .vertical
        spacing = 1
        alignment = .leading
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func createCompletedText() -> NSTextField {
        let view = NSTextField.hintWithTitle("")
        view.lineBreakMode = .byTruncatingHead

        // Make sure it doesn't grow based on content
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return view
    }

    func reset(maxValue: Double) {
        progress.doubleValue = 0.0
        progress.minValue = 0.0
        progress.maxValue = maxValue
        progress.displayIfNeeded()

        text.stringValue = ""
    }

    func update(
        completedBytes: Int64,
        totalBytes: Int64,
        throughput: Int64
    ) {
        progress.doubleValue = Double(completedBytes)

        guard completedBytes > 0 else {
            text.stringValue = ""
            return
        }

        let sizeFormatter = FileSizeFormatter.default
        let completeStr = sizeFormatter.string(from: NSNumber(value: completedBytes)) ?? "N/A"
        let totalStr = sizeFormatter.string(from: NSNumber(value: totalBytes)) ?? "N/A"

        text.stringValue = if throughput > 0 {
            String(
                format: NSLocalizedString("Copied %@ of %@ at %@/s", comment: ""),
                completeStr,
                totalStr,
                sizeFormatter.string(from: NSNumber(value: throughput)) ?? "N/A"
            )
        } else {
            String(
                format: NSLocalizedString("Copied %@ of %@", comment: ""),
                completeStr,
                totalStr
            )
        }
    }
}
