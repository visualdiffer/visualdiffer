//
//  FileDropView+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/05/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

extension FileDropView {
    @MainActor
    static func create(
        title: String,
        delegate: FileDropImageViewDelegate
    ) -> FileDropView {
        let view = FileDropView(frame: .zero)

        view.delegate = delegate
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(frame: .zero)

        label.stringValue = title
        label.isBordered = false
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.topAnchor, constant: -10),
        ])

        return view
    }
}
