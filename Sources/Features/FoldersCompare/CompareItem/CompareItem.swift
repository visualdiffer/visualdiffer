//
//  CompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

typealias CompareItemComparison = (CompareItem, CompareItem) -> ComparisonResult

public class CompareItem: NSObject {
    var linkedItem: CompareItem?
    var visibleItem: VisibleItem?
    var parent: CompareItem?

    var fileModificationDate: Date?
    var fileSize: Int64 = 0
    var type: CompareChangeType

    private(set) var children = [CompareItem]()
    private(set) var orphanFolders: Int = 0

    // MARK: - Path

    @objc var path: String? {
        didSet {
            cachedFileName = nil
        }
    }

    private var cachedFileName: String?

    var fileName: String? {
        if cachedFileName == nil,
           let path {
            let url = URL(filePath: path, directoryHint: isFolder ? .isDirectory : .notDirectory)
            cachedFileName = url.lastPathComponent
        }
        return cachedFileName
    }

    private(set) var fileFlags: FileFlags = []

    var isFiltered: Bool = false
    var isDisplayed: Bool = false

    private(set) var summary: CompareSummary = .init()

    func setSummary(_ summary: CompareSummary) {
        self.summary = summary
        updateType()
    }

    // MARK: - init

    init(
        path: String?,
        attributes: ResolvedFileAttributes?,
        parent: CompareItem?
    ) {
        self.path = path
        self.parent = parent
        type = .orphan

        super.init()

        setAttributes(attributes)
        summary = CompareSummary()
    }

    func setAttributes(
        _ attributes: ResolvedFileAttributes?
    ) {
        guard let attributes else {
            fileFlags = []

            summary = CompareSummary()
            type = .orphan

            fileSize = 0
            fileModificationDate = nil

            return
        }

        fileFlags = attributes.flags
        fileSize = attributes.fileSize
        fileModificationDate = attributes.modificationDate
    }

    // The linked item on other side represent a folder
    // this allows to treat this object as a folder when necessary for example when items are expanded
    // If set to YES isFolderObject will return YES
    func linkedItemIsFolder(_ isFolder: Bool) {
        fileFlags[.isFolder] = isFolder
        fileFlags[.isFile] = !isFolder
    }

    // MARK: - Children access methods

    func add(child: CompareItem) {
        children.append(child)
    }

    func insert(child: CompareItem, at index: Int) {
        children.insert(child, at: index)
    }

    func remove(child: CompareItem) {
        if let index = children.firstIndex(where: { $0 === child }) {
            children.remove(at: index)
        }
    }

    func removeChild(at index: Int) {
        children.remove(at: index)
    }

    func replaceChild(at index: Int, with child: CompareItem) {
        children[index] = child
    }

    func child(at index: Int) -> CompareItem {
        children[index]
    }

    func sortChildren(using cmptr: CompareItemComparison) {
        children.sort {
            cmptr($0, $1) == .orderedAscending
        }
    }

    // MARK: - Counter setters

    private func updateType() {
        if isFile {
            if summary.olderFiles > 0 {
                type = .old
            } else if summary.changedFiles > 0 {
                type = .changed
            } else if summary.orphanFiles > 0 {
                type = .orphan
            } else {
                type = .same
            }
        } else if isFolder {
            if summary.hasMetadataTags {
                type = .mismatchingTags
            } else if summary.hasMetadataLabels {
                type = .mismatchingLabels
            } else {
                type = .orphan
            }
        }
    }

    func addOlderFiles(_ delta: Int) {
        if delta != 0 {
            // file can only have one count and it must be 1
            if isFile {
                summary.olderFiles = delta < 0 ? 0 : 1

                summary.changedFiles = 0
                summary.orphanFiles = 0
                summary.matchedFiles = 0
            } else {
                summary.olderFiles += delta
            }

            updateType()
        }
    }

    func addChangedFiles(_ delta: Int) {
        if delta != 0 {
            if isFile {
                summary.changedFiles = delta < 0 ? 0 : 1

                summary.olderFiles = 0
                summary.orphanFiles = 0
                summary.matchedFiles = 0
            } else {
                summary.changedFiles += delta
            }

            updateType()
        }
    }

    func addOrphanFiles(_ delta: Int) {
        if delta != 0 {
            if isFile {
                summary.orphanFiles = delta < 0 ? 0 : 1
                summary.olderFiles = 0
                summary.changedFiles = 0
                summary.matchedFiles = 0
            } else {
                summary.orphanFiles += delta
            }

            updateType()
        }
    }

    func addMatchedFiles(_ delta: Int) {
        if delta != 0 {
            if isFile {
                summary.matchedFiles = delta < 0 ? 0 : 1
                summary.olderFiles = 0
                summary.changedFiles = 0
                summary.orphanFiles = 0
            } else {
                summary.matchedFiles += delta
            }

            updateType()
        }
    }

    func addMismatchingTags(_ delta: Int) {
        if delta != 0 {
            if isFile {
                summary.mismatchingTags = delta < 0 ? 0 : 1
            } else {
                summary.mismatchingTags += delta
            }

            updateType()
        }
    }

    func addMismatchingLabels(_ delta: Int) {
        if delta != 0 {
            if isFile {
                summary.mismatchingLabels = delta < 0 ? 0 : 1
            } else {
                summary.mismatchingLabels += delta
            }

            updateType()
        }
    }

    func setMismatchingFolderMetadataTags(_ hasMetadata: Bool) {
        if hasMetadata {
            summary.mismatchingFolderMetadata.insert(.tags)
        } else {
            summary.mismatchingFolderMetadata.remove(.tags)
        }
        updateType()
    }

    func setMismatchingFolderMetadataLabels(_ hasMetadata: Bool) {
        if hasMetadata {
            summary.mismatchingFolderMetadata.insert(.labels)
        } else {
            summary.mismatchingFolderMetadata.remove(.labels)
        }
        updateType()
    }

    func addSubfoldersSize(_ delta: Int64) {
        summary.subfoldersSize += delta
    }

    func addOrphanFolders(_ delta: Int) {
        guard delta != 0 else {
            return
        }

        var parent: CompareItem? = parent

        while let p = parent {
            p.orphanFolders += delta
            parent = p.parent
        }
    }

    // MARK: Counter computing

    func computeCounts(_ countHolder: inout CompareSummary, filteredSummary: inout CompareSummary) {
        guard isValidFile else {
            return
        }

        let updateFilteredCount = isFiltered || !isDisplayed
        var counter = CompareSummary()

        if isFile {
            let total = summary.olderFiles + summary.changedFiles + summary.orphanFiles + summary.matchedFiles

            // Filtered files have all count set to zero, not displayed files have count set correctly
            // so we determine how to increment the usedCounter
            if total == 0 {
                counter.orphanFiles += 1
            } else {
                counter += summary
            }
            counter.subfoldersSize += fileSize
        } else {
            counter.folders += 1
            for subfolder in children {
                subfolder.computeCounts(&countHolder, filteredSummary: &filteredSummary)
            }
        }

        if updateFilteredCount {
            filteredSummary += counter
        } else {
            countHolder += counter
        }
    }

    func invalidate() {
        path = nil
        setAttributes(nil)
        type = .orphan
        isFiltered = false
    }
}
