//
//  VisibleItem+QLPreviewItem.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

import Quartz

extension VisibleItem: QLPreviewItem {
    // swiftlint:disable:next implicitly_unwrapped_optional
    public var previewItemURL: URL! {
        item.toUrl()
    }
}
