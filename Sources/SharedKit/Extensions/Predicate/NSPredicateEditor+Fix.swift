//
//  NSPredicateEditor+Fix.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/10/20.
//  Copyright (c) 2020 visualdiffer.com
//

extension NSPredicateEditor {
    /**
     * Resize editor input text
     */
    func resizeRows(_ width: CGFloat) {
        let rowTemplates = rowTemplates
        for row in rowTemplates {
            let views = row.templateViews
            for view in views {
                if let view = view as? NSTextField {
                    var r = view.frame
                    r.size.width = width
                    view.frame = r

                    break
                }
            }
        }
    }
}
