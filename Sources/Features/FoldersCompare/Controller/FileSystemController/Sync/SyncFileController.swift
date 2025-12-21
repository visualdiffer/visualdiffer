//
//  SyncFileController.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class SyncFileController: FileSystemController<SyncFileOperationExecutor> {
    private lazy var syncOptionsView: NSStackView = createOptionsView()

    private let operationDescription: NSTextField = {
        let view = NSTextField.labelWithTitle("")
        view.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        return view
    }()

    private lazy var checkboxUseSelection: NSButton = {
        let view = NSButton(
            checkboxWithTitle: NSLocalizedString("Use selection", comment: ""),
            target: self,
            action: #selector(updateCount)
        )
        view.state = .on

        return view
    }()

    private lazy var checkboxSyncBothSides: NSButton = .init(
        checkboxWithTitle: NSLocalizedString("Sync both sides", comment: ""),
        target: self,
        action: #selector(updateCount)
    )

    private lazy var scrollView: NSScrollView = createScrollView()
    private lazy var treeView: SyncOutlineView = .init(items: itemsToSync)

    private lazy var itemsToSync: SyncItemsInfo = {
        let view = SyncItemsInfo()
        view.nodes = DescriptionOutlineNode(text: "", isContainer: true)

        return view
    }()

    private var createEmptyFolders = false

    private var view: FoldersOutlineView
    private let root: CompareItem

    init(
        executor: SyncFileOperationExecutor,
        fileOperationManager: FileOperationManager,
        view: FoldersOutlineView,
        progressIndicatorController: ProgressIndicatorController
    ) {
        self.view = view

        guard let vi = view.dataSource?.outlineView?(view, child: 0, ofItem: nil) as? VisibleItem,
              let root = vi.item.parent else {
            fatalError("Unable to get root")
        }
        self.root = root

        createEmptyFolders = true
        super.init(
            executor: executor,
            fileOperationManager: fileOperationManager,
            view: view,
            progressIndicatorController: progressIndicatorController,
            filteredFileVisible: false
        )
    }

    override func createWindow() -> NSWindow {
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable]

        let view = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        view.hasShadow = true
        view.isRestorable = true
        view.minSize = NSSize(width: 480, height: 300)

        return view
    }

    override func setupStandardButtons() {
        super.setupStandardButtons()

        standardButtons.primaryButton.title = NSLocalizedString("Sync", comment: "")
    }

    override func setupOperationSummaryView() {
        operationSummary.addArrangedSubview(syncOptionsView)
    }

    override func setupMainStackView() {
        mainStackView.addArrangedSubviews([
            operationSummary,
            scrollView,
        ])

        mainStackView.orientation = .vertical
        mainStackView.alignment = .leading
        mainStackView.spacing = 10
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
    }

    override func setupConstraints() {
        guard let contentView = window?.contentView else {
            return
        }
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: standardButtons.topAnchor, constant: -20),

            standardButtons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            standardButtons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    private func createScrollView() -> NSScrollView {
        let view = NSScrollView(frame: .zero)

        view.borderType = .bezelBorder
        view.autohidesScrollers = true
        view.hasHorizontalScroller = true
        view.hasVerticalScroller = true
        view.horizontalLineScroll = 19
        view.horizontalPageScroll = 10
        view.verticalLineScroll = 19
        view.verticalPageScroll = 10
        view.usesPredominantAxisScrolling = false
        view.translatesAutoresizingMaskIntoConstraints = false

        view.documentView = treeView

        return view
    }

    private func createOptionsView() -> NSStackView {
        let view = NSStackView(views: [
            operationDescription,
            checkboxUseSelection,
            checkboxSyncBothSides,
        ])
        view.orientation = .vertical
        view.alignment = .leading
        view.spacing = 4
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    override func setupTitle() {
        let syncBothSides = checkboxSyncBothSides.state == .on

        if syncBothSides {
            operationSummary.icon.image = NSImage(named: VDImageNameSyncBoth)
            operationDescription.stringValue = NSLocalizedString("Copy newer and orphan files to other side", comment: "")
        } else {
            if view.side == .left {
                operationSummary.icon.image = NSImage(named: VDImageNameSyncRight)
                operationDescription.stringValue = NSLocalizedString("Copy newer and orphan files to right", comment: "")
            } else {
                operationSummary.icon.image = NSImage(named: VDImageNameSyncLeft)
                operationDescription.stringValue = NSLocalizedString("Copy newer and orphan files to left", comment: "")
            }
        }
    }

    override func setupViews() {
        super.setupViews()

        if !executor.hasSelectedItems {
            checkboxUseSelection.state = .off
            checkboxUseSelection.isEnabled = false
        }
    }

    @objc override func updateCount(_: AnyObject?) {
        setupTitle()
        fillItemsToSync()

        treeView.reloadData()
    }

    private func fillItemsToSync() {
        let useSelection = checkboxUseSelection.state == .on
        let syncBothSides = checkboxSyncBothSides.state == .on

        executor.prepareSyncItemsInfo(
            items: itemsToSync,
            withSelection: useSelection,
            syncBothSides: syncBothSides,
            createEmptyFolders: createEmptyFolders,
            view: view
        )
        guard let nodes = itemsToSync.nodes,
              nodes.children.isEmpty else {
            return
        }
        let text = if view.side == .left {
            NSLocalizedString("No files to copy on the right", comment: "")
        } else {
            NSLocalizedString("No files to copy on the left", comment: "")
        }

        nodes.children.append(DescriptionOutlineNode(text: text, isContainer: false))
    }

    override func prepareExecute() {
        guard let callerWindow else {
            fatalError("Caller window is nil")
        }

        executor.syncSelection = checkboxUseSelection.state == .on
        executor.syncBothSides = checkboxSyncBothSides.state == .on

        fileOperationManager.includesFiltered = false

        guard let progressIndicatorController else {
            return
        }
        progressIndicatorController.beginSheetModal(
            for: callerWindow,
            processingItemsCount: 0,
            totalSize: 0,
            singleItem: false
        )

        let itemsInfo = executor.itemsInfo
        progressIndicatorController.operationDescription = NSLocalizedString("Syncing", comment: "")
        progressIndicatorController.resetProcessingItems()
        progressIndicatorController.setProcessingItemsCount(itemsInfo.nodes?.items?.count ?? 0)
        progressIndicatorController.sizeLeft = itemsInfo.totalSize

        progressIndicatorController.startRun()
    }

    override func execute() {
        guard let rootPath = root.path,
              let rootLinkedPath = root.linkedItem?.path else {
            return
        }
        prepareExecute()

        let capturedManager = fileOperationManager
        DispatchQueue.global(qos: .userInitiated).async {
            self.performExecution(
                fileOperationManager: capturedManager,
                srcBaseDir: rootPath,
                destBaseDir: rootLinkedPath
            )

            DispatchQueue.main.async {
                self.updateUIAfterExecute()
            }
        }
    }

    nonisolated func performExecution(
        fileOperationManager: FileOperationManager,
        srcBaseDir: String,
        destBaseDir: String
    ) {
        sync(
            fileOperationManager: fileOperationManager,
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            copyDestFiles: false
        )

        if executor.syncBothSides {
            // pay attention src and dest are inverted because we are copying from dest versus src
            sync(
                fileOperationManager: fileOperationManager,
                srcBaseDir: destBaseDir,
                destBaseDir: srcBaseDir,
                copyDestFiles: true
            )
        }
    }

    nonisolated func sync(
        fileOperationManager: FileOperationManager,
        srcBaseDir: String,
        destBaseDir: String,
        copyDestFiles: Bool
    ) {
        let payload = SyncFileOperationExecutor.Payload(
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            copyDestFiles: copyDestFiles,
            copyEmptyFolders: false
        )
        executor.execute(fileOperationManager, payload: payload)

        let items = copyDestFiles ? executor.itemsInfo.linkedInfo : executor.itemsInfo
        let emptyFoldersCount = items?.emptyFoldersNodes?.items?.count ?? 0

        if emptyFoldersCount == 0 {
            return
        }
        DispatchQueue.main.async {
            if let progressIndicatorController = self.progressIndicatorController {
                progressIndicatorController.operationDescription = NSLocalizedString("Creating empty folders", comment: "")
                progressIndicatorController.resetProcessingItems()
                progressIndicatorController.setProcessingItemsCount(emptyFoldersCount)
                progressIndicatorController.sizeLeft = 0
            }
        }

        let emptyFoldersPayload = SyncFileOperationExecutor.Payload(
            srcBaseDir: srcBaseDir,
            destBaseDir: destBaseDir,
            copyDestFiles: copyDestFiles,
            copyEmptyFolders: true
        )
        executor.execute(fileOperationManager, payload: emptyFoldersPayload)
    }
}
