//
//  FoldersOutlineView+ExternalApp.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/12/20.
//  Copyright (c) 2020 visualdiffer.com
//

extension FoldersOutlineView {
    func showSelectedInFinder() {
        var paths = [String]()
        var selectionHasNotVisibleFiles = false

        enumerateSelectedValidFiles { item, _ in
            if let path = item.path,
               let fileName = item.fileName {
                paths.append(path)
                if !selectionHasNotVisibleFiles, fileName.hasPrefix(".") {
                    selectionHasNotVisibleFiles = true
                }
            }
        }
        if selectionHasNotVisibleFiles {
            NSAlert.showModalInfo(
                messageText: NSLocalizedString("Some selected file(s) may not be visible in Finder", comment: ""),
                informativeText: NSLocalizedString("Finder doesn't show files starting with . (period) character", comment: ""),
                suppressPropertyName: CommonPrefs.Name.confirmShowInFinderNotVisibleFiles.rawValue
            )
        }
        NSWorkspace.shared.show(inFinder: paths)
    }

    @objc func openSelected(with application: URL) {
        do {
            let editor = OpenEditor(attributes: openEditorFromSelectedFiles())
            try editor.open(withApplication: application)
        } catch {
            if let window {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
    }

    @objc func openSelectedWithOther() {
        do {
            let editor = OpenEditor(attributes: openEditorFromSelectedFiles())
            try editor.browseApplicationAndLaunch()
        } catch {
            if let window {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
    }

    private func openEditorFromSelectedFiles() -> [OpenEditorAttribute] {
        var editorData = [OpenEditorAttribute]()

        enumerateSelectedValidFiles { item, _ in
            if item.isFile, let path = item.path {
                editorData.append(OpenEditorAttribute(path: path))
            }
        }

        return editorData
    }
}
