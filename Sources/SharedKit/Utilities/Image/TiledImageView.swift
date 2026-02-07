//
//  TiledImageView.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

final class TiledImageView: NSView {
    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool {
        false
    }

    override func draw(_ dirtyRect: NSRect) {
        NSBezierPath(rect: bounds).addClip()

        super.draw(dirtyRect)
        guard let img = image else {
            return
        }

        let tileSize = img.size
        guard tileSize.width > 0, tileSize.height > 0 else {
            return
        }

        var y: CGFloat = 0
        while y < bounds.height {
            var x: CGFloat = 0
            while x < bounds.width {
                img.draw(
                    in: NSRect(x: x, y: y, width: tileSize.width, height: tileSize.height),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1.0
                )
                x += tileSize.width
            }
            y += tileSize.height
        }
    }
}
