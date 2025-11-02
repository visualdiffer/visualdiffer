//
//  NSAlert+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/01/13.
//  Copyright (c) 2013 visualdiffer.com
//

@objc extension NSAlert {
    static func showModalConfirm(
        messageText: String,
        informativeText: String,
        suppressPropertyName: String? = nil,
        yesText: String? = nil,
        noText: String? = nil
    ) -> Bool {
        let defaults = UserDefaults.standard

        if let suppressPropertyName {
            if defaults.bool(forKey: suppressPropertyName) {
                return true
            }
        }
        let alert = Self()

        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.showsSuppressionButton = suppressPropertyName != nil
        alert.addButton(withTitle: yesText ?? NSLocalizedString("Yes", comment: ""))
        alert.addButton(withTitle: noText ?? NSLocalizedString("No", comment: ""))
        alert.buttons[1].keyEquivalent = KeyEquivalent.escape

        let result = alert.runModal() == .alertFirstButtonReturn

        if result,
           let suppressPropertyName,
           let button = alert.suppressionButton,
           button.state == .on {
            defaults.setValue(true, forKey: suppressPropertyName)
        }

        return result
    }

    static func showModalInfo(
        messageText: String,
        informativeText: String,
        suppressPropertyName: String?
    ) {
        let defaults = UserDefaults.standard

        if let suppressPropertyName {
            if defaults.bool(forKey: suppressPropertyName) {
                return
            }
        }
        let alert = Self()

        alert.messageText = messageText
        alert.alertStyle = .informational
        alert.informativeText = informativeText
        alert.showsSuppressionButton = suppressPropertyName != nil

        alert.runModal()

        if let suppressPropertyName,
           let button = alert.suppressionButton,
           button.state == .on {
            defaults.setValue(true, forKey: suppressPropertyName)
        }
    }
}
