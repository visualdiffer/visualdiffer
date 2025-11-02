//
//  Array+MoveIndexes.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/05/13.
//  Copyright (c) 2013 visualdiffer.com
//

extension Array {
    mutating func move(from indexes: IndexSet, to toIndex: Int) -> IndexSet {
        var toIndexBlock = toIndex
        var delta = 0

        for fromIdx in indexes {
            if fromIdx < toIndexBlock {
                let obj = self[fromIdx + delta]
                insert(obj, at: toIndexBlock)
                remove(at: fromIdx + delta)
                delta -= 1
            } else if fromIdx > toIndexBlock {
                let obj = self[fromIdx]
                remove(at: fromIdx)
                insert(obj, at: toIndexBlock)
                toIndexBlock += 1
            }
        }
        var movedIndexes = IndexSet()
        for i in 0 ..< indexes.count {
            movedIndexes.insert(toIndex + delta + i)
        }
        return movedIndexes
    }
}
