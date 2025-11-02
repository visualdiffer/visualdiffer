//
//  FoldersWindowController+Navigation.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController {
    @objc func previousDifference(_: AnyObject) {
        let options: DifferenceNavigator = [.previous, CommonPrefs.shared.folderDifferenceNavigatorOptions]
        var didWrap = false

        if lastUsedView.moveToDifference(options: options, didWrap: &didWrap) != nil, didWrap {
            scopeBar.findView.showWrapWindow()
        }
    }

    @objc func nextDifference(_: AnyObject) {
        let options: DifferenceNavigator = [.next, CommonPrefs.shared.folderDifferenceNavigatorOptions]
        var didWrap = false

        if lastUsedView.moveToDifference(options: options, didWrap: &didWrap) != nil, didWrap {
            scopeBar.findView.showWrapWindow()
        }
    }
}
