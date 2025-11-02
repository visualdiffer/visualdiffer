//
//  FileOperationManager.swift
//  VisualDiffer
//
//  Created by davide ficano on 02/04/16.
//  Copyright (c) 2016 visualdiffer.com
//

@objc protocol FileOperationManagerDelegate: AnyObject {
    func waitPause(for fileManager: FileOperationManager)
    func isRunning(_ fileManager: FileOperationManager) -> Bool
    func fileManager(
        _ fileManager: FileOperationManager,
        canReplaceFromPath fromPath: String,
        fromAttrs: [FileAttributeKey: Any]?,
        toPath: String,
        toAttrs: [FileAttributeKey: Any]?
    ) -> Bool
    func fileManager(_ fileManager: FileOperationManager, initForItem item: CompareItem)
    func fileManager(_ fileManager: FileOperationManager, updateForItem item: CompareItem)
    func fileManager(_ fileManager: FileOperationManager, addError error: any Error, forItem item: CompareItem)

    @objc func fileManager(_ fileManager: FileOperationManager, startBigFileOperationForItem item: CompareItem)
    @objc func isBigFileOperationCancelled(_ fileManager: FileOperationManager) -> Bool
    @objc func isBigFileOperationCompleted(_ fileManager: FileOperationManager) -> Bool
    @objc func fileManager(_ fileManager: FileOperationManager, setCancelled cancelled: Bool)
    @objc func fileManager(_ fileManager: FileOperationManager, setCompleted completed: Bool)
    @objc func fileManager(_ fileManager: FileOperationManager, updateBytesCompleted bytesCompleted: Double, totalBytes: Double, throughput: Double)
}

public protocol FileOperationManagerAction: AnyObject {
    func copy(_ srcRoot: CompareItem, srcBaseDir: String, destBaseDir: String)
    func move(
        _ srcRoot: CompareItem,
        srcBaseDir: String,
        destBaseDir: String
    )
    func delete(_ srcRoot: CompareItem, srcBaseDir: String)
    func touch(_ srcRoot: CompareItem, includeSubfolders: Bool, touch touchDate: Date?)
    func rename(_ srcRoot: CompareItem, toName: String)
}

@objc class FileOperationManager: NSObject, @unchecked Sendable {
    /**
     * Can be modified by callers, this allows file system operations to include filtered files while copying, moving
     * The filterConfig.showFilteredFiles is then used to correctly updated the UI
     */
    var includesFiltered: Bool

    let filterConfig: FilterConfig
    let comparator: ItemComparator
    @objc let delegate: FileOperationManagerDelegate

    init(
        filterConfig: FilterConfig,
        comparator: ItemComparator,
        delegate: FileOperationManagerDelegate,
        includesFiltered: Bool? = nil
    ) {
        self.includesFiltered = includesFiltered ?? filterConfig.showFilteredFiles
        self.filterConfig = filterConfig
        self.comparator = comparator
        self.delegate = delegate
    }
}
