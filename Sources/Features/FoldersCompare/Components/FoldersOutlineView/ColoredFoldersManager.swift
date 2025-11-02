//
//  ColoredFoldersManager.swift
//  VisualDiffer
//
//  Created by davide ficano on 21/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ColoredFoldersManager: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.visualdiffer.colored.folders", attributes: .concurrent)
    private var foldersColors: [String: NSImage]

    @objc static let shared = ColoredFoldersManager()

    override private init() {
        foldersColors = Self.buildColoredFolders()
    }

    func iconName(
        _ item: CompareItem,
        isExpanded: Bool,
        hideEmptyFolders: Bool
    ) -> String {
        let openSuffix = isExpanded ? "-open" : ""
        return String(format: "folder-%03d%@", icon(sequenceFor: item, hideEmptyFolders: hideEmptyFolders), openSuffix)
    }

    func icon(
        forFolder item: CompareItem,
        size _: CGFloat,
        isExpanded: Bool,
        hideEmptyFolders: Bool
    ) -> NSImage? {
        let imageFileName = iconName(item, isExpanded: isExpanded, hideEmptyFolders: hideEmptyFolders)
        return icon(folderName: imageFileName)
    }

    @objc func refresh() {
        queue.async(flags: .barrier) {
            self.foldersColors = Self.buildColoredFolders()
        }
    }

    private func icon(folderName: String) -> NSImage? {
        queue.sync {
            foldersColors[folderName]
        }
    }

    private static func buildColoredFolders() -> [String: NSImage] {
        let prefs = CommonPrefs.shared
        guard let changedColor = prefs.changeTypeColor(.changed)?.text,
              let olderColor = prefs.changeTypeColor(.old)?.text,
              let sameColor = prefs.changeTypeColor(.same)?.text,
              let newerColor = prefs.changeTypeColor(.newer)?.text,
              let orphanColor = prefs.changeTypeColor(.orphan)?.text,
              let filteredColor = prefs.changeTypeColor(.filtered)?.text,
              let mismatchingTagsColor = prefs.changeTypeColor(.mismatchingTags)?.text,
              let mismatchingLabelsColor = prefs.changeTypeColor(.mismatchingLabels)?.text else {
            fatalError("Unable to get colors for colored folders")
        }

        guard let maskFull = NSImage(named: "mask-full"),
              let maskBackWhite = NSImage(named: "mask-back-white"),
              let maskBack = NSImage(named: "mask-back"),
              let maskFront = NSImage(named: "mask-front"),
              let maskMiddle = NSImage(named: "mask-middle") else {
            fatalError("Unable to build colored folders")
        }

        let size = NSSize(width: 16.0, height: 16.0)

        let useSoftwareRenderer = false

        return [
            "folder-000-open": maskedWithFront(maskFront.tintImage(sameColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-000": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(sameColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-001-open": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-001": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-010-open": maskedWithFront(maskFront.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-010": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-080-open": maskedWithFront(maskFront.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-080": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-100-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-100": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-101-open": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-101": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-011-open": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-011": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-110-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-110": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-111-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-111": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(changedColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-180-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-180": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-999-open": maskedWithFront(maskFront.tintImage(filteredColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-999": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(filteredColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-888-open": maskedWithFront(maskFront.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-888": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-020-open": maskedWithFront(maskFront.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-020": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-030-open": maskedWithFront(maskFront.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBackWhite, size: size),
            "folder-030": maskedWithFront(nil, middle: nil, back: maskFull.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-021-open": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-021": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-031-open": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-031": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-081-open": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-081": maskedWithFront(maskFront.tintImage(olderColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-120-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-120": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-130-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-130": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-121-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-121": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(mismatchingTagsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-131-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-131": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(mismatchingLabelsColor, useSoftwareRenderer: useSoftwareRenderer), size: size),

            "folder-181-open": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: maskMiddle.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), back: maskBackWhite, size: size),
            "folder-181": maskedWithFront(maskFront.tintImage(orphanColor, useSoftwareRenderer: useSoftwareRenderer), middle: nil, back: maskBack.tintImage(newerColor, useSoftwareRenderer: useSoftwareRenderer), size: size),
        ]
    }

    private static func maskedWithFront(
        _ frontImage: NSImage?,
        middle middleImage: NSImage?,
        back backImage: NSImage?,
        size: NSSize
    ) -> NSImage {
        var composedImage: NSImage

        if let frontImage, let backImage {
            composedImage = backImage.overImage(frontImage)

            if let middleImage {
                let middleTintImage = middleImage
                composedImage = composedImage.overImage(middleTintImage)
            }
        } else if let backImage {
            composedImage = backImage
        } else {
            fatalError("Invalid Image combination frontImage \(String(describing: frontImage)), middleImage \(String(describing: middleImage)), backImage \(String(describing: backImage))")
        }
        composedImage.size = size

        return composedImage
    }

    private func icon(
        sequenceFor item: CompareItem,
        hideEmptyFolders: Bool
    ) -> Int {
        if item.isFiltered {
            return 999
        }
        if item.isOrphanFolder {
            return 100
        }

        let hasOrphanFolders = hideEmptyFolders ? true : item.orphanFolders == 0
        let hasTags = item.summary.hasMetadataTags || item.mismatchingTags != 0
        let hasLabels = item.summary.hasMetadataLabels || item.mismatchingLabels != 0
        let hasNewerFiles = item.changedFiles != 0 && (item.linkedItem?.olderFiles ?? 0) != 0

        let changed = if hasNewerFiles {
            80
        } else if item.changedFiles != 0 {
            10
        } else if hasTags {
            20
        } else if hasLabels {
            30
        } else {
            0
        }

        return (item.orphanFiles == 0 && hasOrphanFolders ? 0 : 100)
            + changed
            + (item.olderFiles == 0 ? 0 : 1)
    }
}
