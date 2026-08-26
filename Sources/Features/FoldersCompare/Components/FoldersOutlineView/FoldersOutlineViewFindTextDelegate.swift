//
//  FoldersOutlineViewFindTextDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/11/20.
//  Copyright (c) 2020 visualdiffer.com
//

@MainActor
class FoldersOutlineViewFindTextDelegate: @preconcurrency FindTextDelegate {
    let view: FoldersOutlineView
    private var fileNames: [VisibleItem]

    init(view: FoldersOutlineView) {
        fileNames = []
        self.view = view
    }

    func find(findText _: FindText, moveToMatchIndex index: Int) -> Bool {
        let vi = fileNames[index]
        view.expandParents(of: vi)

        if view.select(visibleItems: [vi], scrollToFirst: true, center: true, selectLinked: true) {
            return true
        }
        fileNames.remove(at: index)
        return false
    }

    func find(findText: FindText, searchPattern pattern: String) -> Bool {
        let options = findText.findOptions

        guard let matcher = options.matcher(for: pattern),
              let firstChild = view.dataSource?.outlineView?(view, child: 0, ofItem: nil) as? VisibleItem,
              let rootVisibleItem = firstChild.item.parent?.visibleItem else {
            return false
        }

        let filter = FileNameFilter(
            matches: matcher,
            includesFiles: options.matchFiles,
            includesFolders: options.matchFolders
        )

        fileNames = rootVisibleItem.findItems(matching: filter)

        return true
    }

    func numberOfMatches(in _: FindText) -> Int {
        fileNames.count
    }

    func clearMatches(in _: FindText) {
        fileNames.removeAll()
    }

    func selectAllMatches(in _: FindText, side: DisplaySide) {
        var expandedParents = Set<ObjectIdentifier>()

        // expand every parent first because the rows to select are known only when all matches are visible
        for vi in fileNames {
            // items sharing the parent share the whole ancestor chain, expanding it once is enough
            guard let parent = vi.item.parent,
                  expandedParents.insert(ObjectIdentifier(parent)).inserted else {
                continue
            }

            view.expandParents(of: vi)
        }

        // the matches belong to the tree of view, the rows of the two sides are aligned
        let target = side == view.side ? view : view.linkedView

        target?.select(rows: view.rows(forItems: fileNames), scrollToFirst: true, center: true)
    }
}
