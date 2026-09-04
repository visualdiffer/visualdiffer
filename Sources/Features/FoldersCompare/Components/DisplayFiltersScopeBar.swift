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

private let showFilteredID = "FilteredId"
private let showEmptyFoldersID = "EmptyFoldersId"
private let showNoOrphansFoldersID = "NoOrphansFoldersId"

private enum ScopeGroupOptions: Int {
    case displayFilters
    case displayFolders
    case displayFlags
}

class DisplayFiltersScopeBar: ScopeBarView {
    weak var actionDelegate: DisplayFiltersScopeBarDelegate?

    let findView = FindText(frame: .zero)

    func initScopeBar(_ actionDelegate: DisplayFiltersScopeBarDelegate) {
        self.actionDelegate = actionDelegate
        findView.placeholder = NSLocalizedString("Find File Name <⌘F>", comment: "")
        findView.showsFileFilters = true
        accessoryView = findView

        reload(groups: [
            ScopeBarGroup(
                selectionMode: .radio,
                items: [
                    item(String(format: "%ld", DisplayOptions.showAll.rawValue), NSLocalizedString("All", comment: "")),
                    item(String(format: "%ld", DisplayOptions.onlyMismatches.rawValue), NSLocalizedString("Only Mismatches", comment: "")),
                    item(String(format: "%ld", DisplayOptions.onlyMatches.rawValue), NSLocalizedString("Only Matches", comment: "")),
                    item(String(format: "%ld", DisplayOptions.noOrphan.rawValue), NSLocalizedString("No Orphans", comment: "")),
                    item(String(format: "%ld", DisplayOptions.onlyOrphans.rawValue), NSLocalizedString("Only Orphans", comment: "")),
                ]
            ),
            // folders related group
            ScopeBarGroup(
                selectionMode: .selectAny,
                items: [
                    item(showEmptyFoldersID, NSLocalizedString("Empty", comment: "")),
                    item(showNoOrphansFoldersID, NSLocalizedString("No Orphans", comment: "")),
                ],
                label: NSLocalizedString("Folders:", comment: ""),
                showsSeparator: true
            ),
            // filtered group
            ScopeBarGroup(
                selectionMode: .multiple,
                items: [
                    item(showFilteredID, NSLocalizedString("Filtered", comment: "")),
                ],
                showsSeparator: true
            ),
        ])
    }

    override func itemSelectionChanged(_: Bool, identifier: String, groupIndex: Int) {
        guard let actionDelegate,
              let group = ScopeGroupOptions(rawValue: groupIndex) else {
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
            if identifier == showFilteredID {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .showFiltered,
                    options: nil
                )
            }
        case .displayFolders:
            if identifier == showNoOrphansFoldersID {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .showNoOrphansFolders,
                    options: nil
                )
            } else if identifier == showEmptyFoldersID {
                actionDelegate.displayFiltersScopeBar(
                    self,
                    action: .showEmptyFolders,
                    options: nil
                )
            }
        }
    }

    // MARK: - Actions

    func hideEmptyFolders(_ hideEmptyFolders: Bool, informDelegate _: Bool) {
        // the logic to select the 'empty folders' button is inverted, so we pass the negated value
        setSelected(
            !hideEmptyFolders,
            forItem: showEmptyFoldersID,
            informDelegate: false
        )
    }

    func showFilteredFiles(_ showFilteredFiles: Bool, informDelegate: Bool) {
        setSelected(
            showFilteredFiles,
            forItem: showFilteredID,
            informDelegate: informDelegate
        )
    }

    func select(_ displayOptions: DisplayOptions, informDelegate: Bool) {
        setSelected(
            true,
            forItem: String(format: "%ld", displayOptions.onlyMethodFlags.rawValue),
            informDelegate: informDelegate
        )
    }

    func noOrphansFolders(_ noOrphansFolders: Bool, informDelegate: Bool) {
        setSelected(
            noOrphansFolders,
            forItem: showNoOrphansFoldersID,
            informDelegate: informDelegate
        )
    }
}
