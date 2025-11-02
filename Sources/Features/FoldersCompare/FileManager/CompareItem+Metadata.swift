//
//  CompareItem+Metadata.swift
//  VisualDiffer
//
//  Created by davide ficano on 15/12/21.
//  Copyright (c) 2021 visualdiffer.com
//

extension CompareItem {
    /**
     * update the metadata counters
     * @param parentCount the counter containing the parent values
     * @param fileObjectCount the counter for current prcessed CompareItem,
     * it's used only if CompareItem points to a file object
     */
    func updateMetadata(
        with parentCount: inout CompareSummary,
        fileObjectCount: inout CompareSummary
    ) {
        if isFile {
            addMismatchingTags(-mismatchingTags)
            addMismatchingLabels(-mismatchingLabels)

            parentCount.mismatchingTags += fileObjectCount.mismatchingTags
            parentCount.mismatchingLabels += fileObjectCount.mismatchingLabels
            fileObjectCount.mismatchingTags = 0
            fileObjectCount.mismatchingLabels = 0
        } else {
            if summary.hasMetadataTags {
                parentCount.mismatchingTags += 1
            }
            if summary.hasMetadataLabels {
                parentCount.mismatchingLabels += 1
            }
            setMismatchingFolderMetadataTags(false)
            setMismatchingFolderMetadataLabels(false)
            addMismatchingTags(-mismatchingTags)
            addMismatchingLabels(-mismatchingLabels)
        }
    }

    func copyMetadata(toPath destPath: inout URL) throws {
        guard let url = toUrl() else {
            return
        }

        if summary.hasMetadataTags {
            try url.copyTags(to: &destPath)
        }
        if summary.hasMetadataLabels {
            try url.copyLabel(to: &destPath)
        }
    }
}
