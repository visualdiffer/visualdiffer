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
    /// open the successive file listed on opener window
    /// Parameters:
    /// - leftPath: the left path to search
    /// - ritghtPath:the right path to search
    /// - block: return true if the passed paths are used, false otherwise.
    /// If paths are not found both `leftPath` and `rightPath` are nil
    func openNextDifference(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock)

    func openPreviousDifference(from leftPath: String?, rightPath: String?, block: DiffOpenerDelegateBlock)

    func hasNextDifference(from leftPath: String?, rightPath: String?) -> Bool
    func hasPreviousDifference(from leftPath: String?, rightPath: String?) -> Bool

    ///
    /// returns the parent paths of the two compared items
    /// if one of the passed paths is nil, the other is used to infer the missing parent.
    /// This is useful when no information is available for one path and it must be derived from the other
    /// Parameters:
    /// - leftPath: the left path, or nil when unknown
    /// - rightPath: the right path, or nil when unknown
    /// Returns: a tuple with both parent paths, or nil when neither path is available
    func parentPaths(from leftPath: String?, rightPath: String?) -> (leftParentPath: String, rightParentPath: String)?
}
