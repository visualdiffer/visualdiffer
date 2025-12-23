//
//  FiltersPredicateEditor.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation

// swiftlint:disable multiline_arguments
class FiltersPredicateEditor: NSPredicateEditor {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        rowHeight = 25.0
        autoresizingMask = [.width, .height]
        canRemoveAllRows = false
        nestingMode = .compound

        rowTemplates = [
            NSPredicateEditorRowTemplate(compoundTypes: nsNumberArray([
                NSCompoundPredicate.LogicalType.and.rawValue,
                NSCompoundPredicate.LogicalType.or.rawValue,
            ])),

            // File Name Ignore Case
            TitlePredicateEditorRowTemplate(
                keyPathDisplayNames: ["fileName": NSLocalizedString("Name (Ignore Case)", comment: "")],
                leftKeyPath: "fileName",
                rightExpressionAttributeType: .stringAttributeType,
                caseInsensitive: true,
                operators: comparisonPredicateMap([
                    .contains,
                    .beginsWith,
                    .endsWith,
                    .equalTo,
                    .notEqualTo,
                    .like,
                ], attributeType: .stringAttributeType)
            ),

            // File Name Case Sensitive
            TitlePredicateEditorRowTemplate(
                keyPathDisplayNames: ["fileName": NSLocalizedString("Name", comment: "")],
                leftKeyPath: "fileName",
                rightExpressionAttributeType: .stringAttributeType,
                caseInsensitive: false,
                operators: comparisonPredicateMap([
                    .contains,
                    .beginsWith,
                    .endsWith,
                    .equalTo,
                    .notEqualTo,
                    .like,
                ], attributeType: .stringAttributeType)
            ),

            // Path Ignore Case
            TitlePredicateEditorRowTemplate(
                keyPathDisplayNames: ["pathRelativeToRoot": NSLocalizedString("Path (Ignore Case)", comment: "")],
                leftKeyPath: "pathRelativeToRoot",
                rightExpressionAttributeType: .stringAttributeType,
                caseInsensitive: true,
                operators: comparisonPredicateMap([
                    .contains,
                    .equalTo,
                    .endsWith,
                ], attributeType: .stringAttributeType)
            ),
            // Path Case Sensitive
            TitlePredicateEditorRowTemplate(
                keyPathDisplayNames: ["pathRelativeToRoot": NSLocalizedString("Path", comment: "")],
                leftKeyPath: "pathRelativeToRoot",
                rightExpressionAttributeType: .stringAttributeType,
                caseInsensitive: false,
                operators: comparisonPredicateMap([
                    .contains,
                    .equalTo,
                    .endsWith,
                ], attributeType: .stringAttributeType)
            ),

            // Size
            TOPFileSizePredicateEditorRowTemplate(
                keyPathDisplayNames: ["fileSize": NSLocalizedString("File Size", comment: "")],
                leftKeyPath: "fileSize",
                rightExpressionAttributeType: .floatAttributeType,
                caseInsensitive: false,
                operators: comparisonPredicateMap([
                    .equalTo,
                    .notEqualTo,
                    .lessThan,
                    .greaterThan,
                ], attributeType: .floatAttributeType)
            ),

            // Date
            TOPTimestampPredicateEditorRowTemplate(
                keyPathDisplayNames: ["fileObjectModificationDate": NSLocalizedString("File Modification Date", comment: "")],
                leftKeyPath: "fileObjectModificationDate",
                rightExpressionAttributeType: .dateAttributeType,
                caseInsensitive: false,
                operators: comparisonPredicateMap([
                    .equalTo,
                    .notEqualTo,
                    .lessThan,
                    .greaterThan,
                ], attributeType: .dateAttributeType)
            ),
        ]
        resizeRows(200)
    }

    private func nsNumberArray(_ array: [UInt]) -> [NSNumber] {
        array.map { NSNumber(value: $0) }
    }

    private func comparisonPredicateMap(
        _ array: [NSComparisonPredicate.Operator],
        attributeType: NSAttributeType
    ) -> [[NSNumber: String]] {
        array.map { [NSNumber(value: $0.rawValue): operatorString($0, attributeType: attributeType)] }
    }

    private func operatorString(
        _ comparisonOperator: NSComparisonPredicate.Operator,
        attributeType: NSAttributeType
    ) -> String {
        if attributeType == .floatAttributeType {
            return switch comparisonOperator {
            case .equalTo: NSLocalizedString("equals", comment: "")
            case .notEqualTo: NSLocalizedString("is not", comment: "")
            case .lessThan: NSLocalizedString("is less than", comment: "")
            case .greaterThan: NSLocalizedString("is greater than", comment: "")
            default: fatalError("Unsupported operator \(comparisonOperator)")
            }
        }

        if attributeType == .dateAttributeType {
            return switch comparisonOperator {
            case .equalTo: NSLocalizedString("exactly", comment: "")
            case .notEqualTo: NSLocalizedString("is not", comment: "")
            case .lessThan: NSLocalizedString("before", comment: "")
            case .greaterThan: NSLocalizedString("after", comment: "")
            default: fatalError("Unsupported operator \(comparisonOperator)")
            }
        }

        if attributeType == .stringAttributeType {
            return switch comparisonOperator {
            case .beginsWith: NSLocalizedString("begins with", comment: "")
            case .contains: NSLocalizedString("contains", comment: "")
            case .endsWith: NSLocalizedString("ends with", comment: "")
            case .equalTo: NSLocalizedString("is", comment: "")
            case .greaterThan: NSLocalizedString("is greater than", comment: "")
            case .lessThan: NSLocalizedString("is less than", comment: "")
            case .like: NSLocalizedString("is like", comment: "")
            case .notEqualTo: NSLocalizedString("is not", comment: "")
            default: fatalError("Unsupported operator \(comparisonOperator)")
            }
        }
        fatalError("Unsupoorted attribute type \(attributeType)")
    }
}

// swiftlint:enable multiline_arguments
