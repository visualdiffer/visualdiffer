//
//  CommonAncestorPathTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/03/26.
//  Copyright (c) 2026 visualdiffer.com
//

import Testing
@testable import VisualDiffer

final class CommonAncestorPathTests: BaseTests {
    func makeTree() -> CompareItem {
        let root = folder("/l", parent: nil)
        let dir = folder("/l/dir", parent: root)
        let deeper = folder("/l/dir/deeper", parent: dir)
        let level2 = folder("/l/dir/deeper/level2", parent: deeper)
        let level1 = folder("/l/level1", parent: root)
        let lv2 = folder("/l/level1/level2", parent: level1)

        deeper.add(child: file("/l/dir/deeper/file5.txt", parent: deeper))
        deeper.add(child: level2)
        level2.add(child: file("/l/dir/deeper/level2/level2-file5.txt", parent: level2))

        dir.add(child: deeper)
        dir.add(child: file("/l/dir/file3.txt", parent: dir))
        dir.add(child: file("/l/dir/file4.txt", parent: dir))

        level1.add(child: file("/l/level1/file1-1.txt", parent: level1))
        level1.add(child: lv2)
        lv2.add(child: file("/l/level1/level2/file2-1.txt", parent: lv2))
        lv2.add(child: file("/l/level1/level2/file2-2.txt", parent: lv2))

        root.add(child: dir)
        root.add(child: file("/l/file1.txt", parent: root))
        root.add(child: file("/l/file2.txt", parent: root))
        root.add(child: level1)

        return root
    }

    // MARK: - Tests

    @Test
    func singleItemReturnsParentPath() {
        let root = makeTree()
        let file5 = root.child(at: 0).child(at: 0).child(at: 0)
        #expect(CompareItem.commonAncestorPath([file5]) == "/l/dir/deeper")
    }

    @Test
    func siblingsInSameFolderReturnsParent() {
        let root = makeTree()
        let dir = root.child(at: 0)
        let file3 = dir.child(at: 1)
        let file4 = dir.child(at: 2)
        #expect(CompareItem.commonAncestorPath([file3, file4]) == "/l/dir")
    }

    @Test
    func filesInDifferentSubfoldersReturnsCommonAncestor() {
        let root = makeTree()
        let file5 = root.child(at: 0).child(at: 0).child(at: 0)
        let lv2file = root.child(at: 0).child(at: 0).child(at: 1).child(at: 0)
        #expect(CompareItem.commonAncestorPath([file5, lv2file]) == "/l/dir/deeper")
    }

    @Test
    func filesInCompletelyDifferentBranchesReturnsRoot() {
        let root = makeTree()
        let file3 = root.child(at: 0).child(at: 1)
        let file1_1 = root.child(at: 3).child(at: 0)
        #expect(CompareItem.commonAncestorPath([file3, file1_1]) == "/l")
    }

    @Test
    func allLeafFilesReturnsRoot() {
        let root = makeTree()
        let file1 = root.child(at: 1)
        let file2 = root.child(at: 2)
        let file3 = root.child(at: 0).child(at: 1)
        #expect(CompareItem.commonAncestorPath([file1, file2, file3]) == "/l")
    }

    @Test
    func deepNestingReturnsCorrectAncestor() {
        let root = makeTree()
        let file2_1 = root.child(at: 3).child(at: 1).child(at: 0)
        let file2_2 = root.child(at: 3).child(at: 1).child(at: 1)
        #expect(CompareItem.commonAncestorPath([file2_1, file2_2]) == "/l/level1/level2")
    }

    @Test
    func itemWithNilParentReturnsNil() {
        let root = makeTree()
        let file1 = root.child(at: 1)
        let noParent = CompareItem(path: "/some/path", attrs: nil, fileExtraOptions: [], parent: nil)
        #expect(CompareItem.commonAncestorPath([file1, noParent]) == nil)
    }

    @Test
    func emptyListReturnsNil() {
        #expect(CompareItem.commonAncestorPath([]) == nil)
    }
}
