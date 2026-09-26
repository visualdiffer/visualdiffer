//
//  FilePanelView+File.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilePanelView {
    func readFile(_ path: URL) throws -> String {
        fileInfoBar.encoding = CommonPrefs.shared.defaultEncoding
        fileInfoBar.fileAttrs = nil
        fileInfoBar.eol = .missing

        let secureURL = SecureBookmark.shared.secure(fromBookmark: path, startSecured: true)
        defer {
            if let secureURL {
                SecureBookmark.shared.stopAccessing(url: secureURL)
            }
        }

        fileInfoBar.fileAttrs = try FileManager.default.attributesOfItem(atPath: path.osPath)

        let content = try readContent(path)

        // the panel is showing this file only now, a read that threw earlier must leave
        // the flag alone or unsaved edits are discarded without asking
        treeView.isDirty = false

        return content
    }

    private func readContent(_ path: URL) throws -> String {
        // pessimistic lock
        treeView.isEditAllowed = false

        let result = try path.readStructuredContent(encoding: fileInfoBar.encoding ?? String.Encoding.utf8)
        let content = result.plainText
        let docType = result.contentType
        let encoding = result.encoding

        if content != nil,
           let docType {
            treeView.isEditAllowed = docType == .plainText
        }

        if let encoding {
            fileInfoBar.encoding = encoding
        }
        return content ?? ""
    }
}
