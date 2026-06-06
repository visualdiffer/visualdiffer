//
//  FoldersWindowControllerTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import AppKit
import Testing
@testable import VisualDiffer

private final class FolderSelectionDataSource: NSObject, NSOutlineViewDataSource {
    let root: VisibleItem

    init(root: VisibleItem) {
        self.root = root
    }

    func outlineView(
        _: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        let parent = item as? VisibleItem ?? root
        return parent.children.count
    }

    func outlineView(
        _: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        let parent = item as? VisibleItem ?? root
        return parent.children[index]
    }

    func outlineView(
        _: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        guard let item = item as? VisibleItem else {
            return false
        }

        return !item.children.isEmpty
    }
}

final class FoldersWindowControllerTests: BaseTests {
    // this creates a test case to generate the error trapped on
    // [FoldersWindowController (id)outlineView: outlineView child: (NSInteger)index ofItem: (id)item]
    @Test
    func savedFromArrayOutOfBound() throws {
        try removeItem("l")
        try removeItem("r")

        // create folders
        try createFolder("l/empty_folder1")
        try createFolder("r/empty_folder1")
        try createFolder("l/empty_folder2")
        try createFolder("r/folder_one_file_inside")

        // create files
        try createFile("r/folder_one_file_inside/AppDelegate.m", "12345")
    }

    @Test("This isn't a test but a way to prepare the folders for the test")
    func excludingByName() throws {
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: [.contentTimestamp],
            delegate: comparatorDelegate,
            bufferSize: 8192
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: false,
            hideEmptyFolders: false,
            followSymLinks: false,
            skipPackages: false,
            traverseFilteredFolders: false,
            predicate: defaultPredicate,
            fileExtraOptions: [],
            displayOptions: .showAll
        )
        let folderReaderDelegate = MockFolderReaderDelegate(isRunning: true)
        let folderReader = FolderReader(
            with: folderReaderDelegate,
            comparator: comparator,
            filterConfig: filterConfig,
            refreshInfo: RefreshInfo(initState: true)
        )

        try removeItem("l")
        try removeItem("r")

        // create folders
        try createFolder("l/folder1")
        try createFolder("r/folder1")
        try createFolder("l/folder1/folder2")
        try createFolder("r/folder1/folder2")

        // create files
        try createFile("l/folder1/folder2/file3.txt", "12345")
        try createFile("r/folder1/folder2/file3.txt", "12")
        try createFile("l/folder1/file2.txt", "12")

        folderReader.start(
            withLeftRoot: nil,
            rightRoot: nil,
            leftPath: appendFolder("l"),
            rightPath: appendFolder("r")
        )

        let rootL = try #require(folderReader.leftRoot)
        // let rootR = folderReader.rightRoot!

        let child1 = rootL.children[0] // l
        assertItem(child1, 0, 1, 1, 0, 2, "folder1", .orphan, 7)
        assertItem(child1.linkedItem, 0, 1, 0, 0, 2, "folder1", .orphan, 2)

        let child2 = child1.children[0] // folder1
        assertItem(child2, 0, 1, 0, 0, 1, "folder2", .orphan, 5)
        assertItem(child2.linkedItem, 0, 1, 0, 0, 1, "folder2", .orphan, 2)

        let child3 = child2.children[0] // folder2
        assertItem(child3, 0, 1, 0, 0, 0, "file3.txt", .changed, 5)
        assertItem(child3.linkedItem, 0, 1, 0, 0, 0, "file3.txt", .changed, 2)

        let child4 = child1.children[1] // folder1
        assertItem(child4, 0, 0, 1, 0, 0, "file2.txt", .orphan, 2)
        assertItem(child4.linkedItem, 0, 0, 0, 0, 0, nil, .orphan, 0)
    }

    @Test
    @MainActor
    func captureSelectionForRestoreClearsPreviousPaths() {
        let view = FoldersOutlineView(frame: .zero)
        view.selectionRestorePaths = ["/tmp/previous"]

        view.captureSelectionForRestore(preserveExistingWhenEmpty: false)

        #expect(view.selectionRestorePaths.isEmpty)
    }

    @Test
    @MainActor
    func captureSelectionForRestorePreservesPreviousPathsWhenEmpty() {
        let view = FoldersOutlineView(frame: .zero)
        let previousPaths = ["/tmp/previous"]
        view.selectionRestorePaths = previousPaths

        view.captureSelectionForRestore(preserveExistingWhenEmpty: true)

        #expect(view.selectionRestorePaths == previousPaths)
    }

    @Test
    @MainActor
    func restoringSelectionDoesNotSelectLinkedViewRows() {
        let leftPath = "/tmp/left/item"
        let rightPath = "/tmp/right/item"
        let leftDataSource = FolderSelectionDataSource(
            root: Self.makeVisibleRoot(path: "/tmp/left", childPath: leftPath)
        )
        let rightDataSource = FolderSelectionDataSource(
            root: Self.makeVisibleRoot(path: "/tmp/right", childPath: rightPath)
        )
        let leftView = FoldersOutlineView(frame: .zero)
        let rightView = FoldersOutlineView(frame: .zero)
        Self.prepare(leftView, dataSource: leftDataSource)
        Self.prepare(rightView, dataSource: rightDataSource)
        leftView.linkedView = rightView
        leftView.selectionRestorePaths = [leftPath]

        leftView.restoreCapturedSelection()

        #expect(leftView.selectedRowIndexes == IndexSet(integer: 0))
        #expect(rightView.selectedRowIndexes.isEmpty)
    }

    @MainActor
    private static func prepare(
        _ view: FoldersOutlineView,
        dataSource: FolderSelectionDataSource
    ) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("item"))
        view.addTableColumn(column)
        view.outlineTableColumn = column
        view.dataSource = dataSource
        view.reloadData()
    }

    private static func makeVisibleRoot(
        path: String,
        childPath: String
    ) -> VisibleItem {
        let root = makeVisibleItem(leftPath: path, rightPath: path)
        let child = makeVisibleItem(leftPath: childPath, rightPath: childPath)
        root.add(child)
        if let linkedChild = child.linkedItem {
            root.linkedItem?.add(linkedChild)
        }
        return root
    }

    private static func makeVisibleItem(
        leftPath: String,
        rightPath: String
    ) -> VisibleItem {
        let leftItem = CompareItem(
            path: leftPath,
            attrs: nil,
            fileExtraOptions: [],
            parent: nil
        )
        let rightItem = CompareItem(
            path: rightPath,
            attrs: nil,
            fileExtraOptions: [],
            parent: nil
        )
        leftItem.linkedItem = rightItem
        rightItem.linkedItem = leftItem
        return VisibleItem.createLinked(leftItem)
    }
}
