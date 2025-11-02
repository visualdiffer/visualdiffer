//
//  FoldersWindowController+Exclude.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension FoldersWindowController {
    @objc func excludeByName(_: AnyObject?) {
        var arr = [String]()

        if let exclusionFileFilters = sessionDiff.exclusionFileFilters,
           !exclusionFileFilters.isEmpty {
            arr.append(exclusionFileFilters)
        }

        let fsi = lastUsedView.selectionInfo
        let containsFolders = fsi.foldersCount > 0

        var predicateTemplate: NSPredicate
        var propertyKey: (CompareItem) -> String?
        if containsFolders {
            predicateTemplate = NSPredicate(format: "pathRelativeToRoot == $name")
            propertyKey = { $0.pathRelativeToRoot }
        } else {
            predicateTemplate = NSPredicate(format: "fileName LIKE $name")
            propertyKey = { $0.fileName }
        }
        lastUsedView.enumerateSelectedValidFiles { item, _ in
            if let value = propertyKey(item) {
                let bindVariables = ["name": value]
                let result = predicateTemplate.withSubstitutionVariables(bindVariables)
                arr.append(result.description)
            }
        }
        sessionDiff.exclusionFileFilters = arr.joined(separator: " OR ")
        reloadAll(RefreshInfo(initState: false))
    }

    @objc func excludeByExt(_: AnyObject?) {
        var arr = [String]()

        if let exclusionFileFilters = sessionDiff.exclusionFileFilters,
           !exclusionFileFilters.isEmpty {
            arr.append(exclusionFileFilters)
        }
        let predicateTemplate = NSPredicate(format: "fileName ENDSWITH $name")
        lastUsedView.enumerateSelectedValidFiles { item, _ in
            // use extension
            if let path = item.toUrl() {
                let pathExtension = String(format: ".%@", path.pathExtension)
                let bindVariables = ["name": pathExtension]
                let result = predicateTemplate.withSubstitutionVariables(bindVariables)
                arr.append(result.description)
            }
        }
        sessionDiff.exclusionFileFilters = arr.joined(separator: " OR ")
        reloadAll(RefreshInfo(initState: false))
    }
}
