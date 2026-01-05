//
//  CompareItem+Description.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension CompareItem {
    override public var description: String {
        String(
            format: "Path %@, isFileValid %d, isFolder %d, isFiltered %d, isDisp %d, subs , type %@, older %ld, changed %ld, orphan %ld, matched %ld, tags = %ld, labels = %ld, linkedItem %@",
            path ?? "",
            isValidFile,
            isFolder,
            isFiltered,
            isDisplayed,
            // self.mutableSubfolders,
            type.description,
            summary.olderFiles,
            summary.changedFiles,
            summary.orphanFiles,
            summary.matchedFiles,
            summary.mismatchingTags,
            summary.mismatchingLabels,
            linkedItem?.path ?? ""
        )
    }

    // periphery:ignore
    func shortDescription() -> String {
        String(
            format: "O %ld C%ld H%ld M%ld SB%ld %@ %@",
            olderFiles,
            changedFiles,
            orphanFiles,
            matchedFiles,
            children.count,
            type.description,
            fileName ?? ""
        )
    }
}
