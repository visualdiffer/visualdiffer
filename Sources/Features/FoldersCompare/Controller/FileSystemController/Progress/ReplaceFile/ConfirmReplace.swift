//
//  ConfirmReplace.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class ConfirmReplace {
    let yesToAll: Bool
    let noToAll: Bool
    let confirmHandler: (ConfirmReplace, [ReplaceFileAttributeKey: Any]) -> Bool

    init(
        yesToAll: Bool,
        noToAll: Bool,
        confirmHandler: @escaping (ConfirmReplace, [ReplaceFileAttributeKey: Any]) -> Bool
    ) {
        self.yesToAll = yesToAll
        self.noToAll = noToAll
        self.confirmHandler = confirmHandler
    }

    func canReplace(
        fromPath: String,
        fromAttrs: [FileAttributeKey: Any]?,
        toPath: String,
        toAttrs: [FileAttributeKey: Any]?
    ) -> Bool {
        if yesToAll {
            return true
        }

        var localFromAttrs = fromAttrs
        var localToAttrs = toAttrs

        do {
            if localToAttrs == nil {
                localToAttrs = try FileManager.default.attributesOfItem(atPath: toPath)
            }
        } catch let error as NSError {
            // file doesn't exist
            if error.code == NSFileReadNoSuchFileError {
                return true
            }
        }

        if localFromAttrs == nil {
            localFromAttrs = try? FileManager.default.attributesOfItem(atPath: fromPath)
        }

        let toDate = localToAttrs?[.modificationDate] as? Date
        let fromDate = localFromAttrs?[.modificationDate] as? Date

        if let toDate,
           let fromDate,
           fromDate.compare(toDate) != .orderedAscending {
            return true
        }

        if noToAll {
            return false
        }

        var replaceInfo = [ReplaceFileAttributeKey: Any]()
        replaceInfo[.toPath] = toPath
        replaceInfo[.fromPath] = fromPath

        if let toDate {
            replaceInfo[.toDate] = toDate
        }
        if let size = localToAttrs?[.size] {
            replaceInfo[.toSize] = size
        }
        if let fromDate {
            replaceInfo[.fromDate] = fromDate
        }
        if let size = localFromAttrs?[.size] {
            replaceInfo[.fromSize] = size
        }

        return confirmHandler(self, replaceInfo)
    }
}
