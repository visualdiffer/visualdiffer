//
//  OperationSummaryView.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

class OperationSummaryView: NSStackView {
    lazy var icon: NSImageView = createIcon()

    init() {
        super.init(frame: .zero)

        orientation = .horizontal
        spacing = 4
        translatesAutoresizingMaskIntoConstraints = false

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addArrangedSubview(icon)
    }

    private func createIcon() -> NSImageView {
        let view = NSImageView()

        view.alignment = .left
        view.imageScaling = .scaleNone
        view.imageAlignment = .alignCenter
        view.translatesAutoresizingMaskIntoConstraints = false

        view.widthAnchor.constraint(equalToConstant: 90).isActive = true

        return view
    }
}
