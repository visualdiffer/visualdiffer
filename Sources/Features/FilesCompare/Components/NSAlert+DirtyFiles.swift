//
//  NSAlert+DirtyFiles.swift
//  VisualDiffer
//
//  Created by davide ficano on 23/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension NSApplication.ModalResponse {
    static let saveOnlyLeft = NSApplication.ModalResponse(rawValue: 2000)
    static let saveOnlyRight = NSApplication.ModalResponse(rawValue: 2001)
    static let saveBoth = NSApplication.ModalResponse(rawValue: 2002)
    static let saveDontSave = NSApplication.ModalResponse(rawValue: 2003)
}

extension NSAlert {
    func saveFiles(isLeftDirty: Bool, isRightDirty: Bool) -> NSApplication.ModalResponse {
        if isLeftDirty, isRightDirty {
            addButton(withTitle: NSLocalizedString("Save Checked", comment: "")).tag = NSApplication.ModalResponse.OK.rawValue
            addButton(withTitle: NSLocalizedString("Cancel", comment: "")).tag = NSApplication.ModalResponse.cancel.rawValue
            addButton(withTitle: NSLocalizedString("Don't Save", comment: "")).tag = NSApplication.ModalResponse.saveDontSave.rawValue

            messageText = NSLocalizedString("Save Modified Files?", comment: "")
            accessoryView = SaveFileAccessoryView(withLeftChecked: true, rightChecked: true)
        } else if isLeftDirty {
            addButton(withTitle: NSLocalizedString("Yes", comment: "")).tag = NSApplication.ModalResponse.saveOnlyLeft.rawValue

            let button = addButton(withTitle: NSLocalizedString("No", comment: ""))
            button.keyEquivalentModifierMask = .command
            button.keyEquivalent = NSLocalizedString("d", comment: "The key equivalent for No")
            button.tag = NSApplication.ModalResponse.saveDontSave.rawValue

            addButton(withTitle: NSLocalizedString("Cancel", comment: "")).tag = NSApplication.ModalResponse.cancel.rawValue

            messageText = NSLocalizedString("Save Left File?", comment: "")
        } else if isRightDirty {
            addButton(withTitle: NSLocalizedString("Yes", comment: "")).tag = NSApplication.ModalResponse.saveOnlyRight.rawValue

            let button = addButton(withTitle: NSLocalizedString("No", comment: ""))
            button.keyEquivalentModifierMask = .command
            button.keyEquivalent = NSLocalizedString("d", comment: "The key equivalent for No")
            button.tag = NSApplication.ModalResponse.saveDontSave.rawValue

            addButton(withTitle: NSLocalizedString("Cancel", comment: "")).tag = NSApplication.ModalResponse.cancel.rawValue

            messageText = NSLocalizedString("Save Right File?", comment: "")
        } else {
            return .saveDontSave
        }

        alertStyle = .warning
        let returnCode = runModal()

        if returnCode == .OK {
            if let accessoryView = accessoryView as? SaveFileAccessoryView {
                if accessoryView.saveLeft, accessoryView.saveRight {
                    return .saveBoth
                }
                if accessoryView.saveLeft {
                    return .saveOnlyLeft
                }
                if accessoryView.saveRight {
                    return .saveOnlyRight
                }
            }
            // both sides are not selected
            return .saveDontSave
        }

        return returnCode
    }
}
