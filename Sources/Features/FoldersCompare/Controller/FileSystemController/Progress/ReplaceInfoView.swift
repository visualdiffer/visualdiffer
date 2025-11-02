//
//  ReplaceInfoView.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class ReplaceInfoView: NSStackView {
    let label: NSTextField
    let text: NSTextField

    init(label labelText: String, labelWidth: CGFloat) {
        label = NSTextField.hintWithTitle(labelText)
        label.font = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        label.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true

        text = NSTextField.hintWithTitle("")

        super.init(frame: .zero)

        addArrangedSubviews([
            label,
            text,
        ])
        orientation = .horizontal
        spacing = 4
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
