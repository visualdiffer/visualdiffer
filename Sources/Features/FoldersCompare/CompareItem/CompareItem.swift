//
//  CompareItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

typealias CompareItemComparison = (CompareItem, CompareItem) -> ComparisonResult

// swiftlint:disable file_length
public class CompareItem: NSObject {
    struct FileOptions: OptionSet {
        var rawValue: Int

        static let isFile = FileOptions(rawValue: 1 << 0)
        static let isFolder = FileOptions(rawValue: 1 << 1)
        static let isSymbolicLink = FileOptions(rawValue: 1 << 2)
        static let isPackage = FileOptions(rawValue: 1 << 3)
        static let isResourceFork = FileOptions(rawValue: 1 << 4)
        static let isLocked = FileOptions(rawValue: 1 << 5)
        static let isValidFile = FileOptions(rawValue: 1 << 6)

        subscript(option: FileOptions) -> Bool {
            get {
                contains(option)
            }

            set {
                if newValue {
                    insert(option)
                } else {
                    remove(option)
                }
            }
        }
    }

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

    var fileOptions: FileOptions = []

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
        attrs: [FileAttributeKey: Any]?,
        fileExtraOptions: FileExtraOptions,
        parent: CompareItem?
    ) {
        self.path = path
        self.parent = parent
        type = .orphan

        super.init()

        setAttributes(attrs, fileExtraOptions: fileExtraOptions)
        summary = CompareSummary()
    }

    func setAttributes(
        _ input: [FileAttributeKey: Any]?,
        fileExtraOptions: FileExtraOptions
    ) {
        guard let input else {
            fileOptions = []

            summary = CompareSummary()
            type = .orphan

            fileSize = 0
            fileModificationDate = nil

            return
        }

        let fileType = input.fileAttributeType

        // if the object is a symlink then we use the destination file attributes
        // so we refer to destFileAttrs instead of the original input
        var destFileAttrs = input
        fileOptions[.isLocked] = (input[.immutable] as? NSNumber)?.boolValue ?? false
        fileOptions[.isSymbolicLink] = fileType == .typeSymbolicLink

        let url: URL? = if let path {
            // at this time we don't know if path is a directory or file, so force .notDirectory
            URL(filePath: path, directoryHint: .notDirectory)
        } else {
            nil
        }

        if fileOptions[.isSymbolicLink] {
            let fileManager = FileManager.default
            if let symLinkDest = url?.resolvingSymlinksInPath().osPath,
               let symLinkAttrs = try? fileManager.attributesOfItem(atPath: symLinkDest) {
                let symLinkFileType = symLinkAttrs.fileAttributeType
                fileOptions[.isFolder] = symLinkFileType == .typeDirectory
                destFileAttrs = symLinkAttrs
            }
        } else {
            fileOptions[.isFolder] = fileType == .typeDirectory
        }
        fileOptions[.isFile] = !fileOptions[.isFolder]
        fileModificationDate = destFileAttrs[.modificationDate] as? Date
        if fileOptions[.isFolder] {
            // this is necessary because the returned value can be > 0 also for directories
            // but we don't care about its real internal size
            fileSize = 0

            if let path {
                fileOptions[.isPackage] = NSWorkspace.shared.isFilePackage(atPath: path)
            } else {
                fileOptions[.isPackage] = false
            }
            fileOptions[.isResourceFork] = false
        } else {
            fileOptions[.isResourceFork] = false
            var forkSize: Int64 = 0
            if fileExtraOptions.contains(.resourceFork),
               let size = try? url?.resourceForkSize() {
                forkSize = Int64(size)
                fileOptions[.isResourceFork] = true
            }
            if fileOptions[.isResourceFork] {
                fileSize = forkSize
            } else {
                fileSize = destFileAttrs[.size] as? Int64 ?? 0
            }

            fileOptions[.isPackage] = false
        }
        fileOptions[.isValidFile] = true
    }

    // The linked item on other side represent a folder
    // this allows to treat this object as a folder when necessary for example when items are expanded
    // If set to YES isFolderObject will return YES
    func linkedItemIsFolder(_ isFolder: Bool) {
        fileOptions[.isFolder] = isFolder
        fileOptions[.isFile] = !isFolder
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

    // periphery:ignore
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
        setAttributes(nil, fileExtraOptions: [])
        type = .orphan
        isFiltered = false
    }
}

// swiftlint:enable file_length
