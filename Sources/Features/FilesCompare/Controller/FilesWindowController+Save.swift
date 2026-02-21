//
//  FilesWindowController+Save.swift
//  VisualDiffer
//
//  Created by davide ficano on 24/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc
    func alertSaveDirtyFiles() -> Bool {
        if !leftView.isDirty, !rightView.isDirty {
            return true
        }

        let returnCode = NSAlert()
            .saveFiles(isLeftDirty: leftView.isDirty, isRightDirty: rightView.isDirty)

        do {
            switch returnCode {
            case .saveDontSave:
                return true
            case .cancel:
                return false
            case .saveBoth:
                try saveView(leftView)
                try saveView(rightView)
                return true
            case .saveOnlyLeft:
                try saveView(leftView)
                return true
            case .saveOnlyRight:
                try saveView(rightView)
                return true
            default:
                return true
            }
        } catch {
            NSAlert(error: error).runModal()
            return false
        }
    }

    func saveView(_ view: FilesTableView) throws {
        guard let diffResult else {
            return
        }
        var path: URL?
        var diffSide: DiffSide

        let isLeftView = view.side == .left

        if isLeftView {
            path = resolvedLeftPath
            // view.lineData could be different from diffResult so we use it directly
            diffSide = diffResult.leftSide
        } else {
            path = resolvedRightPath
            diffSide = diffResult.rightSide
        }
        var secureURL: URL?
        defer {
            if let secureURL {
                SecureBookmark.shared.stopAccessing(url: secureURL)
            }
        }

        if let path {
            secureURL = SecureBookmark.shared.secure(fromBookmark: path, startSecured: true)
            try checkFile(path, side: view.side)
        } else {
            if let url = choosePath() {
                path = url
                if isLeftView {
                    resolvedLeftPath = url
                    sessionDiff.leftPath = url.osPath
                } else {
                    resolvedRightPath = url
                    sessionDiff.rightPath = url.osPath
                }
            }
        }

        guard let path else {
            return
        }

        let fileInfoBar = isLeftView ? leftPanelView.fileInfoBar : rightPanelView.fileInfoBar
        try diffSide.write(path: path, encoding: fileInfoBar.encoding ?? String.Encoding.utf8)

        fileInfoBar.fileAttrs = try FileManager.default.attributesOfItem(atPath: path.osPath)
        view.isDirty = false

        setSliderMaxValue()
        fileThumbnail.needsDisplay = true
        window?.toolbar?.validateVisibleItems()

        // userInfo contains the modified file paths, here only one path is added
        let position: FileSavedKey = isLeftView ? .leftPath : .rightPath
        let userInfo = [
            position: path.osPath,
        ]
        NotificationCenter.default.post(
            name: .fileSaved,
            object: nil,
            userInfo: userInfo
        )
    }

    private func choosePath() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.title = NSLocalizedString("Save File As", comment: "")
        // since 10.11 the title is no longer shown so we use the message property
        savePanel.message = NSLocalizedString("Save File As", comment: "")

        if savePanel.runModal() == .OK {
            return savePanel.url
        }

        return nil
    }

    private func checkFile(_ path: URL, side: DisplaySide) throws {
        // Check if file exists otherwise shows a comprehensive message because Cocoa doesn't
        if FileManager.default.fileExists(atPath: path.osPath) {
            return
        }
        throw FileError.fileNotExists(path: path, side: side)
    }
}
