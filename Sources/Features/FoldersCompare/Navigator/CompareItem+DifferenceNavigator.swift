//
//  CompareItem+DifferenceNavigator.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

@objc
extension CompareItem {
    var hasDifferences: Bool {
        !isValidFile ||
            isOrphanFolder ||
            isOrphanFile ||
            orphanFiles > 0 ||
            changedFiles > 0 ||
            olderFiles > 0
    }
}
