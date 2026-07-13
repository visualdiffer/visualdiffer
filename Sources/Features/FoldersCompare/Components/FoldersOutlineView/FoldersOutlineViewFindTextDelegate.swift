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

    func find(findText _: FindText, searchPattern pathPattern: String) -> Bool {
        // use the search pattern exactly as entered because path normalization changes
        // components such as the current and parent directories and can turn a bare file
        // name into an absolute path
        let globPattern = pathPattern.convertGlobMetaCharsToRegexpMetaChars()
        let re = try? NSRegularExpression(
            pattern: globPattern,
            options: .caseInsensitive
        )

        guard let re,
              let firstChild = view.dataSource?.outlineView?(view, child: 0, ofItem: nil) as? VisibleItem,
              let rootVisibleItem = firstChild.item.parent?.visibleItem else {
            return false
        }

        // enable the search full path if the pattern contains a path separator
        let searchFullPath = pathPattern.contains("/")
        rootVisibleItem.findFileName(regex: re, searchFullPath: searchFullPath, items: &fileNames)

        return true
    }

    func numberOfMatches(in _: FindText) -> Int {
        fileNames.count
    }

    func clearMatches(in _: FindText) {
        fileNames.removeAll()
    }
}
