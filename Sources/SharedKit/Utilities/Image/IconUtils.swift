//
//  IconUtils.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/01/12.
//  Converted to Swift by davide ficano on 02/05/25.
//  Copyright (c) 2010 visualdiffer.com

import Cocoa
import UniformTypeIdentifiers

/**
 Is @unchecked Sendable because icons are modified only inside the lock so it's thread safe
 */
public class IconUtils: @unchecked Sendable {
    static let shared = IconUtils()

    // the cached image is resized to the requested size, so the size belongs to the key,
    // otherwise the first caller decides the size for every other one
    private struct IconKey: Hashable {
        let name: String
        let size: CGFloat
    }

    private let lock = NSLock()
    private var icons = [IconKey: NSImage]()

    private init() {}

    public func badge(_ badge: NSImage, icon: NSImage, size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()
        icon.draw(
            in: NSRect(x: 0, y: 0, width: size, height: size),
            from: NSRect.zero,
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: nil
        )
        badge.draw(
            in: NSRect(x: 0, y: 0, width: size, height: size),
            from: NSRect.zero,
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: nil
        )
        image.unlockFocus()

        return image
    }

    public func icon(forType type: UTType, size: CGFloat) -> NSImage {
        cachedIcon(for: type.identifier, size: size) {
            NSWorkspace.shared.icon(for: type)
        }
    }

    public func icon(forFile url: URL, size: CGFloat) -> NSImage {
        let fullPath = url.osPath

        return cachedIcon(for: fullPath, size: size) {
            NSWorkspace.shared.icon(forFile: fullPath)
        }
    }

    public func icon(forEmptyPath size: CGFloat) -> NSImage {
        cachedIcon(for: VDSymbol.Asset.emptyPath.rawValue, size: size) {
            VDSymbol.Asset.emptyPath.image()
        }
    }

    private func iconNamed(_ name: String, size: CGFloat) -> NSImage {
        cachedIcon(for: name, size: size) {
            guard let icon = NSImage(named: name) else {
                fatalError("Unable to find icon \(name)")
            }

            return icon
        }
    }

    private func cachedIcon(
        for name: String,
        size: CGFloat,
        createIcon: () -> NSImage
    ) -> NSImage {
        lock.lock()
        defer { lock.unlock() }

        let key = IconKey(name: name, size: size)

        if let icon = icons[key] {
            return icon
        }

        let icon = createIcon()

        // cache only images size x size
        let reps = icon.representations
        for rep in reps where rep.pixelsHigh != Int(size) {
            if reps.count > 1 {
                icon.removeRepresentation(rep)
            }
        }

        icon.size = NSSize(width: size, height: size)
        icons[key] = icon

        return icon
    }

    // /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AliasBadgeIcon.icns
    func symbolicLinkBadge(size: CGFloat) -> NSImage {
        iconNamed("aliasbadge", size: size)
    }

    // /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/LockedBadgeIcon.icns
    func lockedBadge(size: CGFloat) -> NSImage {
        iconNamed("lockedbadge", size: size)
    }

    func refresh() {
        lock.lock()
        defer { lock.unlock() }

        icons.removeAll(keepingCapacity: true)
    }

    public func badge(
        forName name: String,
        source: NSImage,
        icon badgeImage: NSImage,
        size: CGFloat
    ) -> NSImage {
        guard let badgeName = badgeImage.name() else {
            fatalError("Unable to get icon name for \(name) and icon \(badgeImage)")
        }

        let cacheName = "\(name)/\(badgeName)"
        return cachedIcon(for: cacheName, size: size) {
            badge(badgeImage, icon: source, size: size)
        }
    }
}
