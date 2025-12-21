//
//  FilesWindowController+FileInfoBarDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: @preconcurrency FileInfoBarDelegate {
    func fileInfoBar(_: FileInfoBar, changedEncoding _: String.Encoding) {}
}
