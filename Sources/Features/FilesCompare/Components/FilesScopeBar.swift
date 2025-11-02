//
//  FilesScopeBar.swift
//  VisualDiffer
//
//  Created by davide ficano on 26/10/11.
//  Copyright (c) 2011 visualdiffer.com
//

// Items for scopebarFileGroupDisplayOptions
private let showWhitespacesId = "WhiteSpacesId"

// Items for scopebarFileGroupFilterOptions
private let allId = "AllId"
private let differencesId = "JustDiffsId"
private let justMatchesId = "JustMatchesId"

@objc protocol FilesScopeBarDelegate: AnyObject {
    @objc func filesScopeBar(_ filesScopeBar: FilesScopeBar, action: FilesScopeBarAction)
}

@objc enum FilesScopeBarAction: Int {
    case showWhitespaces
    case showAllLines
    case showJustMatchingLines
    case showJustDifferentLines
}

enum FileScopeGroupOptions: Int {
    case display
    case filter
}

@MainActor class FilesScopeBar: MGScopeBar, @preconcurrency MGScopeBarDelegate {
    private var groupItems = [[ScopeBarGroupKey: Any]]()
    private var labels = [String: String]()

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

    var actionDelegate: FilesScopeBarDelegate?
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

    private func setupViews() {
        fontSize = 11.0
    }

    @objc func initScopeBar(_ actionDelegate: FilesScopeBarDelegate) {
        showLinesFilter = DiffLine.Visibility.loadFromUserDefaults()
        showWhitespaces = CommonPrefs.shared.bool(forKey: .FileScope.showWhitespaces)
        self.actionDelegate = actionDelegate
        delegate = self

        groupItems.removeAll()

        groupItems.append([
            .selectionMode: MGScopeBarGroupSelectionMode.multiple,
            .items: [
                mkItem(showWhitespacesId, NSLocalizedString("Show Whitespaces", comment: "")),
            ],
        ])

        groupItems.append([
            .separator: true,
            .selectionMode: MGScopeBarGroupSelectionMode.radio,
            .items: [
                mkItem(allId, NSLocalizedString("All", comment: "")),
                mkItem(differencesId, NSLocalizedString("Just Differences", comment: "")),
                mkItem(justMatchesId, NSLocalizedString("Just Matches", comment: "")),
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
              let group = FileScopeGroupOptions(rawValue: groupNumber) else {
            return
        }
        switch group {
        case .display:
            if identifier == showWhitespacesId {
                showWhitespaces.toggle()
                actionDelegate.filesScopeBar(self, action: .showWhitespaces)
            }
        case .filter:
            if identifier == allId {
                showLinesFilter = .all
                actionDelegate.filesScopeBar(self, action: .showAllLines)
            } else if identifier == justMatchesId {
                showLinesFilter = .matches
                actionDelegate.filesScopeBar(self, action: .showJustMatchingLines)
            } else if identifier == differencesId {
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
            inGroup: FileScopeGroupOptions.filter.rawValue,
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
            forItem: showWhitespacesId,
            inGroup: FileScopeGroupOptions.display.rawValue,
            informDelegate: informDelegate
        )
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        findView.becomeFirstResponder()
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
            allId
        case .matches:
            justMatchesId
        case .differences:
            differencesId
        }
    }
}
