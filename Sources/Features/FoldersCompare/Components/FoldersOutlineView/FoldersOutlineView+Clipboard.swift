//
//  FoldersOutlineView+Clipboard.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/12/20.
//  Copyright (c) 2020 visualdiffer.com
//

@objc extension FoldersOutlineView {
    func copySelectedAsFileNames() {
        var paths = [String]()

        enumerateSelectedValidFiles { item, _ in
            if let fileName = item.fileName {
                paths.append(fileName)
            }
        }
        if !paths.isEmpty {
            paths.append("")
        }

        NSPasteboard.general.copy(lines: paths)
    }

    func copySelectedAsFullPaths() {
        var paths = [String]()

        enumerateSelectedValidFiles { item, _ in
            if let path = item.path {
                paths.append(path)
            }
        }
        if !paths.isEmpty {
            paths.append("")
        }

        NSPasteboard.general.copy(lines: paths)
    }

    func copySelectedAsUrls() {
        var urls = [URL]()

        enumerateSelectedValidFiles { item, _ in
            if let path = item.toUrl() {
                urls.append(path)
            }
        }

        NSPasteboard.general.copy(urls: urls)
    }
}
