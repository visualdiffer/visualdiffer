//
//  QLPreviewPanel.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/07/11.
//  Copyright (c) 2011 visualdiffer.com
//

import Quartz

extension QLPreviewPanel {
    @objc static func toggle() {
        if sharedPreviewPanelExists(), shared().isVisible {
            shared().orderOut(nil)
        } else {
            shared().makeKeyAndOrderFront(nil)
        }
    }
}
