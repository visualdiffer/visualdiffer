//
//  FilePreviewView.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Quartz

class FilePreviewView: NSView {
    // the Quick Look view initializer is failable, when it fails the pane stays empty
    private let previewView = QLPreviewView(frame: .zero, style: .normal)

    init(menu: NSMenu) {
        super.init(frame: .zero)
        setupViews(menu: menu)
    }

    @available(*, unavailable, message: "use init(menu:)")
    required init?(coder _: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.textBackgroundColor.setFill()
        bounds.fill()
    }

    // a nil item leaves the pane empty, this side has no file to preview
    func show(_ item: QLPreviewItem?) {
        // assigning the same item again makes Quick Look render it from scratch
        if let previewView, previewView.previewItem !== item {
            previewView.previewItem = item
        }
    }

    private func setupViews(menu: NSMenu) {
        // the contextual menu must be shared with the preview because it is hit first
        self.menu = menu

        guard let previewView else {
            return
        }

        previewView.menu = menu
        previewView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewView)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}
