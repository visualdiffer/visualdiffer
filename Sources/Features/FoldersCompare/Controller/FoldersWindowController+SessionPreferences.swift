//
//  FoldersWindowController+SessionPreferences.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController {
    @objc func openSessionSettingsSheet(_: AnyObject) {
        guard let window else {
            return
        }
        sessionPreferencesSheet.beginSheet(
            window,
            sessionDiff: sessionDiff,
            selectedTab: .comparison
        ) {
            self.updateSessionPreferences($0)
        }
    }

    @objc func openFileFilters(_: AnyObject) {
        guard let window else {
            return
        }
        sessionPreferencesSheet.beginSheet(
            window,
            sessionDiff: sessionDiff,
            selectedTab: .filters
        ) {
            self.updateSessionPreferences($0)
        }
    }

    private func updateSessionPreferences(_ returnCode: NSApplication.ModalResponse) {
        if returnCode == .OK {
            sessionPreferencesSheet.updateSessionDiff(sessionDiff)
            updateScopeBar()
            reloadAll(RefreshInfo(
                initState: true,
                expandAllFolders: sessionDiff.expandAllFolders
            ))
        }
    }
}
