//
//  ScopeBarView.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/07/26.
//  Copyright (c) 2026 visualdiffer.com
//

struct ScopeBarItemModel {
    let identifier: String
    let title: String
}

struct ScopeBarGroup {
    enum SelectionMode {
        case radio
        case selectAny
        case multiple
    }

    let label: String?
    let selectionMode: SelectionMode
    let showsSeparator: Bool
    let items: [ScopeBarItemModel]

    init(
        selectionMode: SelectionMode,
        items: [ScopeBarItemModel],
        label: String? = nil,
        showsSeparator: Bool = false
    ) {
        self.label = label
        self.selectionMode = selectionMode
        self.showsSeparator = showsSeparator
        self.items = items
    }
}

class ScopeBarView: NSView {
    private enum Metrics {
        static let horizontalInset: CGFloat = 8
        static let groupSpacing: CGFloat = 8
        static let separatorWidth: CGFloat = 1
        static let separatorHeight: CGFloat = 14
    }

    private struct ItemControl {
        let groupIndex: Int
        let control: NSControl
        let segment: Int?
    }

    private let itemsStack = NSStackView()
    private var itemControls = [String: ItemControl]()
    // groupIndex -> currently selected identifier for radio groups
    private var radioSelections = [Int: String]()
    private var groups = [ScopeBarGroup]()

    // view shown at the trailing edge of the bar, e.g. a find field
    var accessoryView: NSView? {
        didSet {
            oldValue?.removeFromSuperview()
            setupAccessoryView()
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setupScopeBarViews()
    }

    @available(*, unavailable, message: "use init(frame:)")
    required init?(coder _: NSCoder) {
        nil
    }

    private func setupScopeBarViews() {
        itemsStack.orientation = .horizontal
        itemsStack.alignment = .centerY
        itemsStack.spacing = Metrics.groupSpacing
        itemsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(itemsStack)

        NSLayoutConstraint.activate([
            itemsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalInset),
            itemsStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            itemsStack.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor,
                constant: -Metrics.horizontalInset
            ),
        ])
    }

    func reload(groups: [ScopeBarGroup]) {
        self.groups = groups
        itemControls.removeAll()
        radioSelections.removeAll()

        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (groupIndex, group) in groups.enumerated() {
            if group.showsSeparator, groupIndex > 0 {
                itemsStack.addArrangedSubview(makeSeparator())
            }
            if let label = group.label {
                itemsStack.addArrangedSubview(makeGroupLabel(label))
            }

            switch group.selectionMode {
            case .radio:
                addSegmentedControl(group, groupIndex: groupIndex, trackingMode: .selectOne)
            case .selectAny:
                addSegmentedControl(group, groupIndex: groupIndex, trackingMode: .selectAny)
            case .multiple:
                addToggleButtons(group, groupIndex: groupIndex)
            }
        }
    }

    func setSelected(_ selected: Bool, forItem identifier: String, informDelegate: Bool) {
        guard let item = itemControls[identifier] else {
            return
        }

        if let segment = item.segment, let control = item.control as? NSSegmentedControl {
            if groups[item.groupIndex].selectionMode == .selectAny {
                control.setSelected(selected, forSegment: segment)
                if informDelegate {
                    itemSelectionChanged(selected, identifier: identifier, groupIndex: item.groupIndex)
                }
                return
            }
            // radio groups ignore deselection and reselection requests, matching the old MGScopeBar behavior
            guard selected, radioSelections[item.groupIndex] != identifier else {
                return
            }

            control.selectedSegment = segment
            radioSelections[item.groupIndex] = identifier
            if informDelegate {
                itemSelectionChanged(true, identifier: identifier, groupIndex: item.groupIndex)
            }
        } else if let button = item.control as? NSButton {
            button.state = selected ? .on : .off
            if informDelegate {
                itemSelectionChanged(selected, identifier: identifier, groupIndex: item.groupIndex)
            }
        }
    }

    func setEnabledAllGroups(_ enabled: Bool) {
        for item in itemControls.values {
            item.control.isEnabled = enabled
        }
    }

    func itemSelectionChanged(_: Bool, identifier _: String, groupIndex _: Int) {
        // subclasses override to react to selection changes
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        accessoryView?.becomeFirstResponder() ?? false
    }

    private func makeSeparator() -> NSBox {
        let box = NSBox()

        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: Metrics.separatorWidth),
            box.heightAnchor.constraint(equalToConstant: Metrics.separatorHeight),
        ])

        return box
    }

    private func makeGroupLabel(_ label: String) -> NSTextField {
        let view = NSTextField(labelWithString: label)

        view.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        view.textColor = .secondaryLabelColor

        return view
    }

    private func addSegmentedControl(
        _ group: ScopeBarGroup,
        groupIndex: Int,
        trackingMode: NSSegmentedControl.SwitchTracking
    ) {
        let control = NSSegmentedControl(
            labels: group.items.map(\.title),
            trackingMode: trackingMode,
            target: self,
            action: #selector(segmentSelectionChanged)
        )

        control.segmentStyle = .roundRect
        control.controlSize = .small
        control.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        control.tag = groupIndex

        for (segment, item) in group.items.enumerated() {
            itemControls[item.identifier] = ItemControl(groupIndex: groupIndex, control: control, segment: segment)
        }

        itemsStack.addArrangedSubview(control)
    }

    private func addToggleButtons(_ group: ScopeBarGroup, groupIndex: Int) {
        for item in group.items {
            let button = NSButton(title: item.title, target: self, action: #selector(toggleSelectionChanged))

            button.setButtonType(.pushOnPushOff)
            button.bezelStyle = .accessoryBar
            button.controlSize = .small
            button.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
            button.identifier = NSUserInterfaceItemIdentifier(item.identifier)
            button.tag = groupIndex

            itemControls[item.identifier] = ItemControl(groupIndex: groupIndex, control: button, segment: nil)
            itemsStack.addArrangedSubview(button)
        }
    }

    @objc
    private func segmentSelectionChanged(_ sender: NSSegmentedControl) {
        let groupIndex = sender.tag
        let segment = sender.selectedSegment
        guard segment >= 0 else {
            return
        }

        let identifier = groups[groupIndex].items[segment].identifier

        switch groups[groupIndex].selectionMode {
        case .radio:
            // clicking the already selected segment must not notify, matching the old MGScopeBar behavior
            if radioSelections[groupIndex] == identifier {
                return
            }
            radioSelections[groupIndex] = identifier
            itemSelectionChanged(true, identifier: identifier, groupIndex: groupIndex)
        case .selectAny:
            itemSelectionChanged(sender.isSelected(forSegment: segment), identifier: identifier, groupIndex: groupIndex)
        case .multiple:
            break
        }
    }

    @objc
    private func toggleSelectionChanged(_ sender: NSButton) {
        guard let identifier = sender.identifier?.rawValue else {
            return
        }

        itemSelectionChanged(sender.state == .on, identifier: identifier, groupIndex: sender.tag)
    }

    func item(_ identifier: String, _ name: String) -> ScopeBarItemModel {
        ScopeBarItemModel(identifier: identifier, title: name)
    }

    private func setupAccessoryView() {
        guard let accessoryView else {
            return
        }

        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accessoryView)

        NSLayoutConstraint.activate([
            itemsStack.trailingAnchor.constraint(
                lessThanOrEqualTo: accessoryView.leadingAnchor,
                constant: -Metrics.groupSpacing
            ),
            accessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalInset),
            accessoryView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
