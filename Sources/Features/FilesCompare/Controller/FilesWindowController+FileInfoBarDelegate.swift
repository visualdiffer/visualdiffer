//
//  FilesWindowController+FileInfoBarDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController: @preconcurrency FileInfoBarDelegate {
    func fileInfoBar(_: FileInfoBar, changedEncoding _: String.Encoding) {}

    func fileInfoBar(_ fileInfoBar: FileInfoBar, changedEOL eol: EndOfLine) {
        if fileInfoBar === leftPanelView.fileInfoBar {
            diffResult?.leftSide.eol = eol
        } else if fileInfoBar === rightPanelView.fileInfoBar {
            diffResult?.rightSide.eol = eol
        }
    }
}
