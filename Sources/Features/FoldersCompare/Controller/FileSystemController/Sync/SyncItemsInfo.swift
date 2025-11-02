//
//  SyncItemsInfo.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class SyncItemsInfo: NSObject {
    @objc var totalSize: Int64 = 0
    @objc var nodes: DescriptionOutlineNode?
    @objc var emptyFoldersNodes: DescriptionOutlineNode?
    @objc var linkedInfo: SyncItemsInfo?

    @objc func removeAll() {
        nodes?.children.removeAll()
    }

    @objc func add(_ syncNode: DescriptionOutlineNode) {
        guard let syncDataSource = syncNode.items,
              let nodes else {
            return
        }
        if !syncDataSource.isEmpty {
            nodes.children.append(syncNode)
        }
    }
}
