//
//  NSAlert+StopLongRunningOperation.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/09/26.
//  Copyright (c) 2026 visualdiffer.com
//

extension NSAlert {
    static func showModalStopLongRunningOperation() -> Bool {
        NSAlert.showModalConfirm(
            messageText: NSLocalizedString("Are you sure to stop the operation?", comment: ""),
            informativeText: NSLocalizedString("If the operation takes a long time to run, you can stop it, but the results could be inaccurate", comment: ""),
            suppressPropertyName: CommonPrefs.Name.confirmStopLongOperation.rawValue
        )
    }
}
