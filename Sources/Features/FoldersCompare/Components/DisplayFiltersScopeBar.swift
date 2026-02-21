//
//  DisplayFiltersScopeBar.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

enum DisplayFiltersScopeBarAttributeKey: String {
    case filterFlagsDisplayFilters = "filterFlags"
}

@objc
enum DisplayFiltersScopeBarAction: Int {
    case selectFilter
    case showFiltered
    case showEmptyFolders
    case showNoOrphansFolders
}

protocol DisplayFiltersScopeBarDelegate: AnyObject {
    func displayFiltersScopeBar(
        _ displayFiltersScopeBar: DisplayFiltersScopeBar,
        action: DisplayFiltersScopeBarAction,
        options: [DisplayFiltersScopeBarAttributeKey: Any]?
    )
}

private let showFilteredId = "FilteredId"
private let showEmptyFoldersId = "EmptyFoldersId"
private let showNoOrphansFoldersId = "NoOrphansFoldersId"

private enum ScopeGroupOptions: Int {
    case displayFilters
    case displayFolders
    case displayFlags
}

@objc
@MainActor
class DisplayFiltersScopeBar: MGScopeBar, @preconcurrency MGScopeBarDelegate {
    private var groupItems = [[ScopeBarGroupKey: Any]]()
    private var labels = [String: String]()

    var actionDelegate: DisplayFiltersScopeBarDelegate?
    @objc var findView: FindText

    override init(frame frameRect: NSRect) {
        findView = FindText(frame: NSRect(x: 0, y: 0, width: 400, height: 25))

        super.init(frame: frameRect)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        fontSize = 11.0
    }

    func initScopeBar(_ actionDelegate: DisplayFiltersScopeBarDelegate) {
        self.actionDelegate = actionDelegate
        delegate = self

        groupItems.removeAll()

        groupItems.append([
            .selectionMode: MGScopeBarGroupSelectionMode.radio,
            .items: [
                mkItem(String(format: "%ld", DisplayOptions.showAll.rawValue), NSLocalizedString("All", comment: "")),
                mkItem(String(format: "%ld", DisplayOptions.onlyMismatches.rawValue), NSLocalizedString("Only Mismatches", comment: "")),
                mkItem(String(format: "%ld", DisplayOptions.onlyMatches.rawValue), NSLocalizedString("Only Matches", comment: "")),
                mkItem(String(format: "%ld", DisplayOptions.noOrphan.rawValue), NSLocalizedString("No Orphans", comment: "")),
                mkItem(String(format: "%ld", DisplayOptions.onlyOrphans.rawValue), NSLocalizedString("Only Orphans", comment: "")),
            ],
        ])

        // Folders related group
        groupItems.append([
            .label: NSLocalizedString("Folders:", comment: ""),
            .separator: true,
            .selectionMode: MGScopeBarGroupSelectionMode.multiple,
            .items: [
                mkItem(showEmptyFoldersId, NSLocalizedString("Empty", comment: "")),
                mkItem(showNoOrphansFoldersId, NSLocalizedString("No Orphans", comment: "")),
            ],
        ])

        // Filtered group
        groupItems.append([
            .separator: true,
            .selectionMode: MGScopeBarGroupSelectionMode.multiple,
            .items: [
                mkItem(showFilteredId, NSLocalizedString("Filtered", comment: "")),
            ],
        ])

        // Dictionary doesn't preserve order so we can't use it to fill the array
        // So first fill the array then labels
        labels.removeAll()
        for group in groupItems {
            if let groupItems = group[.items] as? [[ScopeBarItem: String]] {
                for dict in groupItems {
                    if let identifier = dict[.identifier],
                       let name = dict[.name] {
                        labels[identifier] = name
                    }
                }
            }
        }

        // scopeBar automatically select first item and then we set selected but this causes unnecessary folder reload
        notifyDefaultSelections = false
        smartResizeEnabled = true

        reloadData()
    }

    private func mkItem(_ identifier: String, _ name: String) -> [ScopeBarItem: String] {
        [
            .identifier: identifier,
            .name: name,
        ]
    }

    // MARK: - MGScopeBarDelegate methods

    func numberOfGroups(in _: MGScopeBar) -> Int {
        groupItems.count
    }

    func scopeBar(_: MGScopeBar, itemIdentifiersForGroup groupNumber: Int) -> [Any] {
        guard let items = groupItems[groupNumber][.items],
              let itemIdentifiers = items as? [[ScopeBarItem: String]] else {
            fatalError("Unexpected data format in groupItems")
        }
        return itemIdentifiers.compactMap { $0[.identifier] }
    }

    func scopeBar(_: MGScopeBar, labelForGroup groupNumber: Int) -> String? {
        groupItems[groupNumber][.label] as? String // might be nil, which is fine (nil means no label).
    }

    func scopeBar(_: MGScopeBar, titleOfItem identifier: String, inGroup groupNumber: Int) -> String? {
        if groupItems[groupNumber][.items] != nil {
            return labels[identifier]
        }
        return nil
    }

    func scopeBar(_: MGScopeBar, selectionModeForGroup groupNumber: Int) -> MGScopeBarGroupSelectionMode {
        (groupItems[groupNumber][.selectionMode] as? MGScopeBarGroupSelectionMode) ?? .radio
    }

    func scopeBar(_: MGScopeBar, showSeparatorBeforeGroup groupNumber: Int) -> Bool {
        // Optional method. If not implemented, all groups except the first will have a separator before them.
        groupItems[groupNumber][.separator] as? Bool ?? false
    }

    func scopeBar(_: MGScopeBar, imageForItem _: String, inGroup _: Int) -> NSImage? {
        nil
    }

    func accessoryView(for _: MGScopeBar) -> NSView? {
        findView
    }

    func scopeBar(_: MGScopeBar, selectedStateChanged _: Bool, forItem identifier: String, inGroup groupNumber: Int) {
        guard let actionDelegate,
              let group = ScopeGroupOptions(rawValue: groupNumber) else {
            return
        }
        switch group {
        case .displayFilters:
            if let filterValue = Int(identifier) {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .selectFilter,
                    options: [.filterFlagsDisplayFilters: NSNumber(value: filterValue)]
                )
            }
        case .displayFlags:
            if identifier == showFilteredId {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .showFiltered,
                    options: nil
                )
            }
        case .displayFolders:
            if identifier == showNoOrphansFoldersId {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .showNoOrphansFolders,
                    options: nil
                )
            } else if identifier == showEmptyFoldersId {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .showEmptyFolders,
                    options: nil
                )
            }
        }
    }

    // MARK: - Actions

    @objc
    func hideEmptyFolders(_ hideEmptyFolders: Bool, informDelegate _: Bool) {
        // The logic to select the 'empty folders' button is inverted so we pass the negated value
        setSelected(
            !hideEmptyFolders,
            forItem: showEmptyFoldersId,
            inGroup: ScopeGroupOptions.displayFolders.rawValue,
            informDelegate: false
        )
    }

    @objc
    func showFilteredFiles(_ showFilteredFiles: Bool, informDelegate: Bool) {
        setSelected(
            showFilteredFiles,
            forItem: showFilteredId,
            inGroup: ScopeGroupOptions.displayFolders.rawValue,
            informDelegate: informDelegate
        )
    }

    func select(_ displayOptions: DisplayOptions, informDelegate: Bool) {
        setSelected(
            true,
            forItem: String(format: "%ld", displayOptions.onlyMethodFlags.rawValue),
            inGroup: ScopeGroupOptions.displayFilters.rawValue,
            informDelegate: informDelegate
        )
    }

    @objc
    func noOrphansFolders(_ noOrphansFolders: Bool, informDelegate: Bool) {
        setSelected(
            noOrphansFolders,
            forItem: showNoOrphansFoldersId,
            inGroup: ScopeGroupOptions.displayFolders.rawValue,
            informDelegate: informDelegate
        )
    }

    override func becomeFirstResponder() -> Bool {
        findView.becomeFirstResponder()
    }
}
