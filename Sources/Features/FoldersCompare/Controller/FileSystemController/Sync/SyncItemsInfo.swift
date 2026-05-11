//
//  SyncItemsInfo.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class SyncItemsInfo: NSObject {
    var totalSize: Int64 = 0
    var nodes: DescriptionOutlineNode?
    var emptyFoldersNodes: DescriptionOutlineNode?
    var linkedInfo: SyncItemsInfo?

    func removeAll() {
        nodes?.children.removeAll()
    }

    func add(_ syncNode: DescriptionOutlineNode) {
        guard let syncDataSource = syncNode.items,
              let nodes else {
            return
        }

        if !syncDataSource.isEmpty {
            nodes.children.append(syncNode)
        }
    }
}
