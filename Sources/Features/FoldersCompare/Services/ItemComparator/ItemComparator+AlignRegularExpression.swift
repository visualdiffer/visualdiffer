//
//  ItemComparator+AlignRegularExpression.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

extension ItemComparator {
    func alignByRegularExpression(
        _ context: AlignContext,
        position: inout AlignPosition
    ) -> ComparisonResult {
        let leftChild = position.leftChild(in: context)
        let rightChild = position.rightChild(in: context)

        return leftChild.compare(
            rightChild,
            followSymLinks: context.config.followSymLinks
        ) {
            self.compareByRegularExpression(
                lhs: $0,
                rhs: $1,
                context: context,
                position: &position
            )
        }
    }

    private func compareByRegularExpression(
        lhs: CompareItem,
        rhs: CompareItem,
        context: AlignContext,
        position: inout AlignPosition
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
            context,
            position: &position
        )
    }
}
