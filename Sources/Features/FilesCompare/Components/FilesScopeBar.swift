//
//  FilesScopeBar.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/10/11.
//  Copyright (c) 2011 visualdiffer.com
//

// items for scopebarFileGroupDisplayOptions
private let showWhitespacesID = "WhiteSpacesId"

// items for scopebarFileGroupFilterOptions
private let allID = "AllId"
private let differencesID = "JustDiffsId"
private let justMatchesID = "JustMatchesId"

protocol FilesScopeBarDelegate: AnyObject {
    func filesScopeBar(_ filesScopeBar: FilesScopeBar, action: FilesScopeBarAction)
}

enum FilesScopeBarAction: Int {
    case showWhitespaces
    case showAllLines
    case showJustMatchingLines
    case showJustDifferentLines
}

enum FileScopeGroupOptions: Int {
    case display
    case filter
}

class FilesScopeBar: ScopeBarView {
    var showLinesFilter: DiffLine.Visibility = .all {
        didSet {
            showLinesFilter.saveToUserDefaults()
        }
    }

    var showWhitespaces = false {
        didSet {
            CommonPrefs.shared.set(showWhitespaces, forKey: .FileScope.showWhitespaces)
        }
    }

    weak var actionDelegate: FilesScopeBarDelegate?

    let findView = FindText(frame: .zero)

    func initScopeBar(_ actionDelegate: FilesScopeBarDelegate) {
        showLinesFilter = DiffLine.Visibility.loadFromUserDefaults()
        showWhitespaces = CommonPrefs.shared.bool(forKey: .FileScope.showWhitespaces)
        self.actionDelegate = actionDelegate
        findView.placeholder = NSLocalizedString("Find Text <⌘F>", comment: "")
        accessoryView = findView

        reload(groups: [
            ScopeBarGroup(
                selectionMode: .multiple,
                items: [
                    item(showWhitespacesID, NSLocalizedString("Show Whitespace", comment: "")),
                ]
            ),
            ScopeBarGroup(
                selectionMode: .radio,
                items: [
                    item(allID, NSLocalizedString("All", comment: "")),
                    item(differencesID, NSLocalizedString("Just Differences", comment: "")),
                    item(justMatchesID, NSLocalizedString("Just Matches", comment: "")),
                ],
                showsSeparator: true
            ),
        ])
    }

    override func itemSelectionChanged(_ isSelected: Bool, identifier: String, groupIndex: Int) {
        guard let actionDelegate,
              let group = FileScopeGroupOptions(rawValue: groupIndex) else {
            return
        }

        switch group {
        case .display:
            if identifier == showWhitespacesID {
                showWhitespaces = isSelected
                actionDelegate.filesScopeBar(self, action: .showWhitespaces)
            }
        case .filter:
            if identifier == allID {
                showLinesFilter = .all
                actionDelegate.filesScopeBar(self, action: .showAllLines)
            } else if identifier == justMatchesID {
                showLinesFilter = .matches
                actionDelegate.filesScopeBar(self, action: .showJustMatchingLines)
            } else if identifier == differencesID {
                showLinesFilter = .differences
                actionDelegate.filesScopeBar(self, action: .showJustDifferentLines)
            }
        }
    }

    func showLineFilter(
        _ type: DiffLine.Visibility,
        informDelegate: Bool
    ) {
        showLinesFilter = type

        setSelected(
            true,
            forItem: showLinesFilter.identifier,
            informDelegate: informDelegate
        )
    }

    func showWhitespaces(
        _ show: Bool,
        informDelegate: Bool
    ) {
        showWhitespaces = show
        setSelected(
            show,
            forItem: showWhitespacesID,
            informDelegate: informDelegate
        )
    }
}

extension CommonPrefs.Name {
    enum FileScope {
        static let showWhitespaces = CommonPrefs.Name(rawValue: "showWhitespaces")
        static let showLinesFilterType = CommonPrefs.Name(rawValue: "showLinesFilterType")
    }
}

extension DiffLine.Visibility {
    static func loadFromUserDefaults() -> Self {
        DiffLine.Visibility(rawValue: CommonPrefs.shared.integer(forKey: .FileScope.showLinesFilterType)) ?? .all
    }

    func saveToUserDefaults() {
        CommonPrefs.shared.set(rawValue, forKey: .FileScope.showLinesFilterType)
    }

    var identifier: String {
        switch self {
        case .all:
            allID
        case .matches:
            justMatchesID
        case .differences:
            differencesID
        }
    }
}
