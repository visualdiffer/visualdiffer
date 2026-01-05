//
//  ItemComparator+AlignRegularExpression.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension ItemComparator {
    func alignByRegularExpression(
        _ leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig,
        leftIndex: inout Int,
        rightIndex: inout Int
    ) -> ComparisonResult {
        let leftChild = leftRoot.child(at: leftIndex)
        let rightChild = rightRoot.child(at: rightIndex)

        var lIndex = leftIndex
        var rIndex = rightIndex

        let result = leftChild.compare(
            rightChild,
            followSymLinks: alignConfig.followSymLinks
        ) { self.compareByRegularExpression(
            lhs: $0,
            rhs: $1,
            leftRoot: leftRoot,
            rightRoot: rightRoot,
            alignConfig: alignConfig,
            leftIndex: &lIndex,
            rightIndex: &rIndex
        )
        }

        leftIndex = lIndex
        rightIndex = rIndex

        return result
    }

    // swiftlint:disable:next function_parameter_count
    private func compareByRegularExpression(
        lhs: CompareItem,
        rhs: CompareItem,
        leftRoot: CompareItem,
        rightRoot: CompareItem,
        alignConfig: AlignConfig,
        leftIndex: inout Int,
        rightIndex: inout Int
    ) -> ComparisonResult {
        guard let lhsName = lhs.fileName,
              let rhsName = rhs.fileName else {
            return .orderedSame
        }
        if let fileNameAlignments {
            for rule in fileNameAlignments where rule.matches(name: lhsName, with: rhsName) {
                return .orderedSame
            }
        }
        return alignByFileName(
            leftRoot,
            rightRoot: rightRoot,
            alignConfig: alignConfig,
            leftIndex: &leftIndex,
            rightIndex: &rightIndex
        )
    }
}
