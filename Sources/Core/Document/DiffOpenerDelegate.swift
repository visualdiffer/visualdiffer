//
//  DiffOpenerDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/09/15.
//  Copyright (c) 2015 visualdiffer.com
//

public typealias DiffOpenerDelegateBlock = (String?, String?) -> Bool

///
/// Who start comparison, generally a folder view controller opening a file comparison document
///
@MainActor
public protocol DiffOpenerDelegate: AnyObject {
    func addChildDocument(_ document: VDDocument)
    func removeChildDocument(_ document: VDDocument)

    ///
    /// Open the successive file listed on opener window
    /// Parameters:
    /// - leftPath: the left path to search
    /// - ritghtPath:the right path to search
    /// - block: return true if the passed paths are used, false otherwise.
    /// If paths are not found both `leftPath` and `rightPath` are nil
    func nextDifferenceFiles(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock)

    func prevDifferenceFiles(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock)
}
