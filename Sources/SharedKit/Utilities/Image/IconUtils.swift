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

    private let lock = NSLock()
    private var icons = [String: NSImage]()

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
        if let icon = icons[type.identifier] {
            return icon
        }

        let icon = NSWorkspace.shared.icon(for: type)
        addIconByName(type.identifier, icon: icon, size: size)

        return icon
    }

    public func icon(forFile url: URL, size: CGFloat) -> NSImage {
        let fullPath = url.osPath
        if let icon = icons[fullPath] {
            return icon
        }

        let icon = NSWorkspace.shared.icon(forFile: fullPath)
        addIconByName(fullPath, icon: icon, size: size)

        return icon
    }

    // /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AliasBadgeIcon.icns
    public func icon(forSymbolicLink url: URL, size: CGFloat) -> NSImage {
        badge(forPath: url, icon: iconNamed("aliasbadge", size: size), size: size)
    }

    // /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/LockedBadgeIcon.icns
    public func icon(forLockedFile url: URL, size: CGFloat) -> NSImage {
        badge(forPath: url, icon: iconNamed("lockedbadge", size: size), size: size)
    }

    public func badge(forPath url: URL, icon badgeImage: NSImage, size: CGFloat) -> NSImage {
        guard let iconName = badgeImage.name() else {
            fatalError("Unable to get icon name for \(url) and icon \(badgeImage)")
        }
        let name = url
            .appendingPathComponent(iconName)
            .osPath
        if let icon = icons[name] {
            return icon
        }

        let path = url.osPath
        let isAbsolute = path.hasPrefix("/")
        let fileIcon = isAbsolute ? icon(forFile: url, size: size) : iconNamed(path, size: size)
        let icon = badge(badgeImage, icon: fileIcon, size: size)

        addIconByName(name, icon: icon, size: size)

        return icon
    }

    private func addIconByName(_ name: String, icon: NSImage, size: CGFloat) {
        lock.lock()
        // Cache only images size x size
        let reps = icon.representations
        for rep in reps where rep.pixelsHigh != Int(size) {
            if reps.count > 1 {
                icon.removeRepresentation(rep)
            }
        }

        icon.size = NSSize(width: size, height: size)
        icons[name] = icon
        lock.unlock()
    }

    private func iconNamed(_ name: String, size: CGFloat) -> NSImage {
        if let icon = icons[name] {
            return icon
        }

        guard let icon = NSImage(named: name) else {
            fatalError("Unable to find icon \(name)")
        }
        addIconByName(name, icon: icon, size: size)

        return icon
    }
}
