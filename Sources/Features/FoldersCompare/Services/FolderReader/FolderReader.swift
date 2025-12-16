//
//  FolderReader.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/04/13.
//  Copyright (c) 2013 visualdiffer.com
//

public class FolderReader: @unchecked Sendable {
    private let fileManager = FileManager.default

    var comparator: ItemComparator

    // delegate is strong
    var delegate: FolderReaderDelegate
    var refreshInfo: RefreshInfo

    private(set) var leftRoot: CompareItem?
    private(set) var rightRoot: CompareItem?

    var filterConfig: FilterConfig

    private var isRunning: Bool {
        delegate.isRunning(self)
    }

    init(
        with delegate: FolderReaderDelegate,
        comparator: ItemComparator,
        filterConfig: FilterConfig,
        refreshInfo: RefreshInfo
    ) {
        self.delegate = delegate
        self.comparator = comparator
        self.filterConfig = filterConfig
        self.refreshInfo = refreshInfo
    }

    public func start(
        withLeftRoot leftRoot: CompareItem?,
        rightRoot: CompareItem?,
        leftPath: URL,
        rightPath: URL
    ) {
        self.leftRoot = leftRoot
        self.rightRoot = rightRoot

        let startTime = Date()
        delegate.progress(self, status: .will(startAt: startTime))
        readFolders(
            leftItem: leftRoot,
            rightItem: self.rightRoot,
            leftPath: leftPath,
            rightPath: rightPath
        )
        let endTime = Date()
        delegate.progress(self, status: .did(endAt: endTime, startedAt: startTime))
    }

    private func readFolders(
        leftItem l: CompareItem?,
        rightItem r: CompareItem?,
        leftPath: URL?,
        rightPath: URL?
    ) {
        if !isRunning {
            return
        }

        var leftItem = l
        var rightItem = r

        if leftRoot != nil {
            if refreshInfo.refreshFolders {
                readFolder(
                    atPath: leftPath,
                    parent: leftItem,
                    recursive: false
                )

                readFolder(
                    atPath: rightPath,
                    parent: rightItem,
                    recursive: false
                )
            }
        } else {
            leftRoot = readFolder(
                atPath: leftPath,
                parent: nil,
                recursive: false
            )

            rightRoot = readFolder(
                atPath: rightPath,
                parent: nil,
                recursive: false
            )
            leftItem = leftRoot
            rightItem = rightRoot
        }

        guard let leftItem else {
            return
        }
        guard let rightItem else {
            return
        }

        leftItem.linkedItem = rightItem
        rightItem.linkedItem = leftItem

        if refreshInfo.realign {
            let alignConfig = AlignConfig(
                recursive: false,
                followSymLinks: filterConfig.followSymLinks
            )
            comparator.alignItem(
                leftItem,
                rightRoot: rightItem,
                alignConfig: alignConfig
            )
        }

        leftItem.applyComparison(
            fileFilters: filterConfig.predicate,
            comparator: refreshInfo.refreshComparison && isRunning ? comparator : nil,
            recursive: false
        )

        leftItem.filterVisibleItems(
            showFilteredFiles: filterConfig.showFilteredFiles,
            hideEmptyFolders: false,
            recursive: false
        )

        if leftItem.parent == nil {
            var folders = 0
            for item in leftItem.children where item.isFolder {
                folders += 1
            }
            delegate.progress(self, status: .rootFoldersDidRead(folders))
        }

        var leftSummary = CompareSummary()
        var rightSummary = CompareSummary()

        if leftItem.isFolder {
            leftSummary.mismatchingFolderMetadata = leftItem.mismatchingFolderMetadata
            rightSummary.mismatchingFolderMetadata = rightItem.mismatchingFolderMetadata
        }

        let traversalOrder = folderTraversalOrder(leftItem)

        for item in traversalOrder {
            if isRunning {
                process(item: item)
            }
            guard let li = item.linkedItem else {
                continue
            }

            // do not exit from loop without updating correctly the counters
            leftSummary += item.summary
            rightSummary += li.summary
            leftSummary.subfoldersSize += item.fileSize
            rightSummary.subfoldersSize += li.fileSize
            if item.isOrphanFolder {
                item.addOrphanFolders(1)
            } else if li.isOrphanFolder {
                li.addOrphanFolders(1)
            }
        }

        leftItem.setSummary(leftSummary)
        rightItem.setSummary(rightSummary)

        // store the current value to be used inside the block because leftItem can change
        let capturedItem = leftItem
        capturedItem.removeVisibleItems(filterConfig: filterConfig)

        if let parent = capturedItem.parent, parent.parent == nil {
            delegate.progress(self, status: .didTraverse(capturedItem))
        }
    }

    @discardableResult
    func readFolder(
        atPath parentPath: URL?,
        parent: CompareItem?,
        recursive: Bool
    ) -> CompareItem? {
        if let parent {
            if parent.path == nil {
                return parent
            }
            if !filterConfig.traverseFilteredFolders, parent.isFiltered {
                return nil
            }
            // don't traverse symbolic links
            if !filterConfig.followSymLinks, parent.isSymbolicLink {
                return parent
            }

            if filterConfig.skipPackages, parent.isPackage {
                return parent
            }
        }

        guard let parentPath else {
            return nil
        }
        do {
            // symlink root must be traversed so allocate it after checking for symlink
            let root = try createParentIfNil(path: parentPath, parent: parent)
            let list = try contentsOfSandboxedDirectory(atPath: parentPath.path)

            for entry in list where isRunning {
                addEntryFile(entry: entry, root: root, parentPath: parentPath, recursive: recursive)
            }
            root.sortChildren {
                $0.compare(forList: $1, followSymLinks: self.filterConfig.followSymLinks)
            }
            return root
        } catch {
            delegate.folderReader(self, handleError: error, forPath: parentPath)
            return nil
        }
    }

    /// Reads the contents of a directory, handling symbolic links outside the sandbox.
    ///
    /// If the path is a symbolic link to an inaccessible destination within the sandbox,
    /// the function attempts to gain access via security-scoped bookmark.
    ///
    /// - Parameter path: The absolute path of the directory to read
    /// - Returns: Array of file and folder names contained in the directory
    /// - Throws: `NSFileReadNoPermissionError` if the symlink points outside the sandbox
    ///           without a valid bookmark in 'Trusted Paths'
    /// - Throws: Other `FileManager` errors if reading fails for different reasons
    private func contentsOfSandboxedDirectory(atPath path: String) throws -> [String] {
        do {
            return try fileManager.contentsOfDirectory(atPath: path)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
            error.code == NSFileReadNoPermissionError {
            guard let destination = try? fileManager.destinationOfSymbolicLink(atPath: path) else {
                throw error
            }

            let secureUrl = SecureBookmark.shared.secure(
                fromBookmark: URL(filePath: destination),
                startSecured: true
            )

            defer {
                SecureBookmark.shared.stopAccessing(url: secureUrl)
            }

            return try fileManager.contentsOfDirectory(atPath: path)
        }
    }

    private func addEntryFile(entry: String, root: CompareItem, parentPath: URL, recursive: Bool) {
        do {
            let fullPath = parentPath.appending(path: entry)
            let attrs = try FileManager.default.attributesOfItem(atPath: fullPath.osPath)

            let newItem = CompareItem(
                path: fullPath.osPath,
                attrs: attrs,
                fileExtraOptions: filterConfig.fileExtraOptions,
                parent: root
            )

            if newItem.isFolder {
                if isFolderFiltered(newItem) {
                    newItem.isFiltered = true
                } else {
                    // protect against recursive loops due to symbolic links to folders
                    if try symbolicLinkToParent(newItem, attributes: attrs) != nil {
                        throw FileError.symlinkLoop(path: root.path ?? "Unknown")
                    }
                }

                if recursive {
                    readFolder(atPath: fullPath, parent: newItem, recursive: recursive)
                }
            }
            root.add(child: newItem)
        } catch {
            delegate.folderReader(self, handleError: error, forPath: parentPath)
        }
    }

    private func symbolicLinkToParent(
        _ item: CompareItem,
        attributes attrs: [FileAttributeKey: Any]
    ) throws -> CompareItem? {
        if !item.isSymbolicLink {
            return nil
        }
        var parent = item.parent

        while let p = parent {
            if let path = p.path {
                let parentAttrs = try FileManager.default.attributesOfItem(atPath: path)
                if
                    let parentSystemFileNumber = parentAttrs[.systemFileNumber] as? NSNumber,
                    let parentSystemNumber = parentAttrs[.systemNumber] as? NSNumber,
                    let currentSystemFileNumber = attrs[.systemFileNumber] as? NSNumber,
                    let currentSystemNumber = attrs[.systemNumber] as? NSNumber,
                    currentSystemFileNumber.isEqual(to: parentSystemFileNumber),
                    currentSystemNumber.isEqual(to: parentSystemNumber) {
                    return p
                }
            } else {
                return nil
            }
            parent = p.parent
        }

        return nil
    }

    private func createParentIfNil(path: URL, parent: CompareItem?) throws -> CompareItem {
        if let parent {
            return parent
        }
        let osPath = path.osPath
        let attrs = try FileManager.default.attributesOfItem(atPath: osPath)
        return CompareItem(
            path: osPath,
            attrs: attrs,
            fileExtraOptions: filterConfig.fileExtraOptions,
            parent: nil
        )
    }

    private func process(item: CompareItem) {
        if item.isFolder {
            delegate.progress(self, status: .willTraverse(item))
            if let li = item.linkedItem {
                readFolders(
                    leftItem: item,
                    rightItem: li,
                    leftPath: item.toUrl(),
                    rightPath: li.toUrl()
                )
            }
        }
        item.removeVisibleItems(filterConfig: filterConfig)
    }

    private func folderTraversalOrder(_ leftItem: CompareItem) -> [CompareItem] {
        // the list is traversed from top to bottom so the user can see the folders while expanding
        // but the order can change from a different sort in the delegate
        // so we get the current order and use it to traverse the folders
        var traversalOrder = [CompareItem]()
        if let visibleItem = leftItem.visibleItem {
            for vi in visibleItem.children {
                traversalOrder.append(vi.item)
            }
        }

        // Only VisibleItems are ordered so filtered elements are not present inside the array
        // We must iterate also the not filtered items to correctly update folders informations like the subfolders size
        // We add the missing CompareItem to the end, this is correct because they are not visible
        for item in leftItem.children where !traversalOrder.contains(where: { $0 == item }) {
            traversalOrder.append(item)
        }

        return traversalOrder
    }

    private func isFolderFiltered(_ item: CompareItem) -> Bool {
        if !item.isFolder {
            return false
        }
        if filterConfig.traverseFilteredFolders {
            return false
        }
        if let predicate = filterConfig.predicate {
            return item.evaluate(filter: predicate)
        }
        return false
    }
}
