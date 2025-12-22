//
//  NSWorkspace+Finder.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/11/14.
//  Copyright (c) 2014 visualdiffer.com
//

let suppressShowInFinder = "suppressShowInFinder"
let maxFoldersToShowWithoutAlert = 8

extension NSWorkspace {
    /**
     * @paths array containing absolute file path strings
     * Show the paths on Finder
     */
    @MainActor @objc func show(inFinder paths: [String]) {
        if paths.count > maxFoldersToShowWithoutAlert {
            let confirmOpen = NSAlert.showModalConfirm(
                messageText: String(format: NSLocalizedString("Are you sure you want to open %lu Finder windows?", comment: ""), paths.count),
                informativeText: NSLocalizedString("You have chosen to open a large number of windows. This can take a long time", comment: ""),
                suppressPropertyName: suppressShowInFinder,
                yesText: nil,
                noText: nil
            )
            if !confirmOpen {
                return
            }
        }

        if !paths.isEmpty {
            var urls = [URL]()
            // Get secure urls to avoid the warning
            // __CFPasteboardIssueSandboxExtensionForPath: error for [/path/to/folder]

            var secureURLs = [URL]()

            for p in paths {
                let pUrl = URL(filePath: p)
                urls.append(pUrl)
                if let secureURL = SecureBookmark.shared.secure(fromBookmark: pUrl, startSecured: true) {
                    secureURLs.append(secureURL)
                }
            }
            NSWorkspace.shared.activateFileViewerSelecting(urls)

            for url in secureURLs {
                SecureBookmark.shared.stopAccessing(url: url)
            }
        }
    }
}
