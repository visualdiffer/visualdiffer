//
//  FilesWindowController+SessionPreferences.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/11/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc
    func openSessionSettingsSheet(_: AnyObject) {
        guard let window else {
            return
        }
        sessionPreferencesSheet.beginSheet(
            window,
            preferences: preferences,
            selectedTab: .comparison
        ) {
            self.updateSessionPreferences($0)
        }
    }

    private func updateSessionPreferences(_ returnCode: NSApplication.ModalResponse) {
        if returnCode == .OK {
            preferences = sessionPreferencesSheet.preferences
            sessionDiff.extraData.diffResultOptions = preferences.diffResultOptions
            startComparison()
        }
    }
}
