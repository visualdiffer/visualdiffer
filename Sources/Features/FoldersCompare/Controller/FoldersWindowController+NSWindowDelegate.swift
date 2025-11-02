//
//  FoldersWindowController+NSWindowDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FoldersWindowController: NSWindowDelegate {
    public func windowDidBecomeMain(_: Notification) {
        Self.switchMenu()
    }

    public func windowWillClose(_: Notification) {
        // release previously started bookmarks
        SecureBookmark.shared.stopAccessing(url: leftSecureURL)
        SecureBookmark.shared.stopAccessing(url: rightSecureURL)

        removeObservers()

        removeAllChildrenDocuments()
    }

    public func window(_: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        [proposedOptions, .autoHideToolbar]
    }
}
