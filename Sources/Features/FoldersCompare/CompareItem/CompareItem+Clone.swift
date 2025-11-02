//
//  CompareItem+Clone.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension CompareItem {
    func duplicate() -> CompareItem {
        let dup = CompareItem(
            path: path,
            attrs: nil,
            fileExtraOptions: [],
            parent: parent
        )

        dup.fileOptions = fileOptions

        dup.fileSize = fileSize
        dup.fileModificationDate = fileModificationDate

        dup.addOlderFiles(olderFiles)
        dup.addChangedFiles(changedFiles)
        dup.addOrphanFiles(orphanFiles)
        dup.addMatchedFiles(matchedFiles)
        dup.addSubfoldersSize(subfoldersSize)

        // attribute `file` can be null but it can represent a folder
        dup.linkedItemIsFolder(isFolder)
        dup.linkedItem = linkedItem

        return dup
    }

    func cloneValidFiles(_ parent: CompareItem?) -> CompareItem? {
        guard isValidFile else {
            return nil
        }

        let clone = duplicate()
        clone.parent = parent
        clone.linkedItem = nil

        for item in children where item.isValidFile {
            if item.isFolder {
                if let child = item.cloneValidFiles(clone) {
                    clone.add(child: child)
                }
            } else {
                let newItem = item.duplicate()
                newItem.parent = clone
                newItem.linkedItem = nil
                clone.add(child: newItem)
            }
        }

        return clone
    }

    func duplicateAsOrphan(
        withPath path: String,
        withParent parent: CompareItem?,
        fileExtraOptions: FileExtraOptions,
        recursive: Bool
    ) -> CompareItem {
        let dupItem = CompareItem(
            path: path,
            attrs: try? FileManager.default.attributesOfItem(atPath: path),
            fileExtraOptions: fileExtraOptions,
            parent: parent
        )
        let dupLinkedItem = CompareItem(
            path: nil,
            attrs: nil,
            fileExtraOptions: [],
            parent: parent?.linkedItem
        )
        dupItem.linkedItem = dupLinkedItem
        dupLinkedItem.linkedItem = dupItem

        dupLinkedItem.linkedItemIsFolder(dupItem.isFolder)

        var summary = CompareSummary()
        summary.orphanFiles = orphanFiles + matchedFiles + olderFiles + changedFiles
        dupItem.setSummary(summary)
        dupItem.addSubfoldersSize(subfoldersSize)

        if recursive {
            if let url = dupItem.toUrl() {
                for item in children where item.isValidFile {
                    if let fileName = item.fileName {
                        let childPath = url.appendingPathComponent(fileName).osPath
                        let child = item.duplicateAsOrphan(
                            withPath: childPath,
                            withParent: dupItem,
                            fileExtraOptions: fileExtraOptions,
                            recursive: true
                        )
                        dupItem.add(child: child)
                        if let dupLinkedItem = dupItem.linkedItem,
                           let childLinkedItem = child.linkedItem {
                            dupLinkedItem.add(child: childLinkedItem)
                        }
                    }
                }
            }
        }
        return dupItem
    }

    func mark(asOrphan recursive: Bool) {
        guard let linkedItem else {
            return
        }

        if isValidFile {
            var summary = CompareSummary()
            summary.orphanFiles = orphanFiles + matchedFiles + olderFiles + changedFiles
            summary.subfoldersSize = subfoldersSize
            setSummary(summary)

            linkedItem.path = nil
            linkedItem.setAttributes(nil, fileExtraOptions: [])

            linkedItem.linkedItemIsFolder(isFolder)
            linkedItem.addSubfoldersSize(-linkedItem.subfoldersSize)
        } else {
            parent?.remove(child: self)
            linkedItem.parent?.remove(child: linkedItem)

            if let vi = visibleItem {
                parent?.visibleItem?.remove(vi)
            }
            if let vi = linkedItem.visibleItem {
                linkedItem.visibleItem?.remove(vi)
            }
        }
        if recursive {
            for item in children.reversed() {
                item.mark(asOrphan: true)
            }
        }
    }
}
