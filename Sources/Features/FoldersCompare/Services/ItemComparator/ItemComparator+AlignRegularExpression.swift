//
//  ItemComparator+AlignRegularExpression.swift
//  VisualDiffer
//
//  Created by davide ficano on 29/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

import Foundation

private struct LeftRuleMatches {
    let leftChild: CompareItem
    let ruleMatches: [AlignRuleMatch]
}

extension ItemComparator {
    func alignByRegularExpression(
        _ context: AlignContext,
        position: inout AlignPosition
    ) -> ComparisonResult {
        let rules = fileNameAlignments ?? []
        let leftChild = position.leftChild(in: context)
        let rightChild = position.rightChild(in: context)
        let followSymLinks = context.config.followSymLinks
        let ruleMatches = if let leftName = leftChild.fileName {
            context.ruleMatchCache.matches(
                for: leftName,
                rules: rules
            )
        } else {
            [AlignRuleMatch]()
        }

        // a current rule match must yield the right to a later left
        // that matches it by exact file name
        if matchesByRegularExpression(
            leftChild: leftChild,
            rightChild: rightChild,
            followSymLinks: followSymLinks,
            ruleMatches: ruleMatches
        ),
            !rightReservedForLaterLeftFileName(
                rightChild: rightChild,
                context: context,
                position: position
            ) {
            return .orderedSame
        }

        if matchesByFileName(
            leftChild: leftChild,
            rightChild: rightChild,
            followSymLinks: followSymLinks
        ) {
            return .orderedSame
        }

        if let matchingRightIndex = findMatchingRightIndex(
            leftChild: leftChild,
            context: context,
            position: position,
            ruleMatches: ruleMatches
        ) {
            moveRightChild(
                from: matchingRightIndex,
                to: position.rightIndex,
                context: context
            )
            return .orderedSame
        }

        let laterRuleMatches = laterLeftRuleMatches(
            context: context,
            position: position,
            rules: rules
        )

        let rightHeldByRule = rightMatchesLaterLeftRegularExpression(
            rightChild: rightChild,
            context: context,
            leftMatches: laterRuleMatches
        )
        let rightHeldByName = rightReservedForLaterLeftFileName(
            rightChild: rightChild,
            context: context,
            position: position
        )

        if rightHeldByRule || rightHeldByName {
            if let matchingRightIndex = findMatchingFileNameRightIndex(
                leftChild: leftChild,
                context: context,
                position: position,
                leftMatches: laterRuleMatches
            ) {
                moveRightChild(
                    from: matchingRightIndex,
                    to: position.rightIndex,
                    context: context
                )
                return .orderedSame
            }
            return .orderedAscending
        }

        return alignByFileName(
            context,
            position: &position
        )
    }

    private func findMatchingRightIndex(
        leftChild: CompareItem,
        context: AlignContext,
        position: AlignPosition,
        ruleMatches: [AlignRuleMatch]
    ) -> Int? {
        guard !ruleMatches.isEmpty else {
            return nil
        }

        return firstRightIndex(after: position, context: context) { rightChild in
            guard matchesByRegularExpression(
                leftChild: leftChild,
                rightChild: rightChild,
                followSymLinks: context.config.followSymLinks,
                ruleMatches: ruleMatches
            ) else {
                return false
            }

            // a right matched only by rule must not be stolen from a later left
            // that matches it by exact file name
            return !rightReservedForLaterLeftFileName(
                rightChild: rightChild,
                context: context,
                position: position
            )
        }
    }

    private func matchesByRegularExpression(
        leftChild: CompareItem,
        rightChild: CompareItem,
        followSymLinks: Bool,
        ruleMatches: [AlignRuleMatch]
    ) -> Bool {
        matchesByRegularExpression(
            leftChild: leftChild,
            rightChild: rightChild,
            followSymLinks: followSymLinks
        ) { _, rhsName in
            ruleMatches.contains {
                $0.matches(rightName: rhsName)
            }
        }
    }

    private func matchesByRegularExpression(
        leftChild: CompareItem,
        rightChild: CompareItem,
        followSymLinks: Bool,
        matcher: (String, String) -> Bool
    ) -> Bool {
        leftChild.compare(
            rightChild,
            followSymLinks: followSymLinks
        ) { lhs, rhs in
            guard let lhsName = lhs.fileName,
                  let rhsName = rhs.fileName else {
                return .orderedAscending
            }

            if matcher(lhsName, rhsName) {
                return .orderedSame
            }
            return .orderedAscending
        } == .orderedSame
    }

    private func matchesByFileName(
        leftChild: CompareItem,
        rightChild: CompareItem,
        followSymLinks: Bool
    ) -> Bool {
        let insensitiveCompare = !isLeftCaseSensitive && !isRightCaseSensitive
        return leftChild.compare(
            forAlign: rightChild,
            followSymLinks: followSymLinks,
            insensitiveCompare: insensitiveCompare
        ) == .orderedSame
    }

    private func findMatchingFileNameRightIndex(
        leftChild: CompareItem,
        context: AlignContext,
        position: AlignPosition,
        leftMatches: [LeftRuleMatches]
    ) -> Int? {
        firstRightIndex(after: position, context: context) { rightChild in
            if rightMatchesLaterLeftRegularExpression(
                rightChild: rightChild,
                context: context,
                leftMatches: leftMatches
            ) {
                return false
            }

            return matchesByFileName(
                leftChild: leftChild,
                rightChild: rightChild,
                followSymLinks: context.config.followSymLinks
            )
        }
    }

    private func rightMatchesLaterLeftRegularExpression(
        rightChild: CompareItem,
        context: AlignContext,
        leftMatches: [LeftRuleMatches]
    ) -> Bool {
        for leftMatch in leftMatches where matchesByRegularExpression(
            leftChild: leftMatch.leftChild,
            rightChild: rightChild,
            followSymLinks: context.config.followSymLinks,
            ruleMatches: leftMatch.ruleMatches
        ) {
            return true
        }
        return false
    }

    private func laterLeftRuleMatches(
        context: AlignContext,
        position: AlignPosition,
        rules: [AlignRule]
    ) -> [LeftRuleMatches] {
        let nextLeftIndex = position.leftIndex + 1

        guard nextLeftIndex < context.leftRoot.children.count else {
            return []
        }

        var leftMatches = [LeftRuleMatches]()

        for leftIndex in nextLeftIndex ..< context.leftRoot.children.count {
            let leftChild = context.leftRoot.child(at: leftIndex)

            guard let leftName = leftChild.fileName else {
                continue
            }

            let ruleMatches = context.ruleMatchCache.matches(
                for: leftName,
                rules: rules
            )

            if !ruleMatches.isEmpty {
                leftMatches.append(LeftRuleMatches(
                    leftChild: leftChild,
                    ruleMatches: ruleMatches
                ))
            }
        }
        return leftMatches
    }

    private func moveRightChild(
        from sourceIndex: Int,
        to destinationIndex: Int,
        context: AlignContext
    ) {
        let child = context.rightRoot.child(at: sourceIndex)
        context.rightRoot.remove(child: child)
        context.rightRoot.insert(child: child, at: destinationIndex)
    }

    private func firstRightIndex(
        after position: AlignPosition,
        context: AlignContext,
        where predicate: (CompareItem) -> Bool
    ) -> Int? {
        let nextRightIndex = position.rightIndex + 1
        guard nextRightIndex < context.rightRoot.children.count else {
            return nil
        }

        for rightIndex in nextRightIndex ..< context.rightRoot.children.count
            where predicate(context.rightRoot.child(at: rightIndex)) {
            return rightIndex
        }
        return nil
    }

    // a right child is reserved when a later left matches it by exact file name,
    // so an earlier rule-only match must yield it to that more specific claimant
    private func rightReservedForLaterLeftFileName(
        rightChild: CompareItem,
        context: AlignContext,
        position: AlignPosition
    ) -> Bool {
        let nextLeftIndex = position.leftIndex + 1

        guard nextLeftIndex < context.leftRoot.children.count else {
            return false
        }

        for leftIndex in nextLeftIndex ..< context.leftRoot.children.count
            where matchesByFileName(
                leftChild: context.leftRoot.child(at: leftIndex),
                rightChild: rightChild,
                followSymLinks: context.config.followSymLinks
            ) {
            return true
        }
        return false
    }
}
