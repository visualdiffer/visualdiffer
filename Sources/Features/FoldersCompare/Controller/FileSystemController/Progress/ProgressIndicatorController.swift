//
//  ProgressIndicatorController.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/01/11.
//  Copyright (c) 2011 visualdiffer.com
//

class ProgressIndicatorController: NSWindowController {
    var sizeLeft: Int64 = 0 {
        didSet {
            updateSizeLeftDisplay()
        }
    }

    var isSizeLeftHidden: Bool {
        get {
            sizeLeftView.isHidden
        }

        set {
            sizeLeftView.isHidden = newValue
        }
    }

    var operationOnSingleItem = false

    var operationDescription: String {
        get { descriptionTitle.stringValue }
        set { descriptionTitle.stringValue = newValue }
    }

    var fileOpCompleted = false
    var fileOpCancelled = false

    var errors: [NSError] {
        errorView.errors
    }

    private var yesToAll = false
    private var noToAll = false

    // waitPause must block the worker thread, not the main thread
    private nonisolated(unsafe) var isPaused = false
    private nonisolated let pauseCondition = NSCondition()

    // isRunning is polled once per item, it must not hop to the main thread
    private nonisolated(unsafe) var running = false
    private nonisolated let runningLock = NSLock()

    // MARK: - Views

    private let errorView = ErrorsView(frame: .zero)

    private lazy var descriptionTitle: NSTextField = {
        let label = NSTextField.labelWithTitle("")
        label.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        return label
    }()

    private lazy var itemPath: NSTextField = {
        let view = NSTextField.hintWithTitle("")
        view.lineBreakMode = .byTruncatingMiddle

        // Make sure it doesn't grow based on content
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return view
    }()

    private lazy var mainStack: NSStackView = {
        let stack = NSStackView(views: [
            descriptionTitle,
            itemPath,
            completionIndicator,
            processingItemsIndicator,
            itemsLeftView,
            sizeLeftView,
        ])
        stack.orientation = .vertical
        stack.spacing = 1
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.setCustomSpacing(14, after: itemPath)
        stack.setCustomSpacing(4, after: processingItemsIndicator)

        return stack
    }()

    private let itemsLeftView = ReplaceInfoView(
        label: NSLocalizedString("Items left", comment: ""),
        labelWidth: 60
    )
    private let sizeLeftView = ReplaceInfoView(
        label: NSLocalizedString("Size left", comment: ""),
        labelWidth: 60
    )

    private let completionIndicator = CompletionIndicator()
    private let processingItemsIndicator = NSProgressIndicator.bar()

    private lazy var stopButton: NSButton = .cancelButton(
        title: NSLocalizedString("Stop", comment: ""),
        target: self,
        action: #selector(stop)
    )

    init() {
        super.init(window: Self.createWindow())

        setupViews()
    }

    @available(*, unavailable, message: "use init()")
    required init?(coder _: NSCoder) {
        nil
    }

    private func setupViews() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        itemsLeftView.text.formatter = formatter

        completionIndicator.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        completionIndicator.heightAnchor.constraint(equalToConstant: 30).isActive = true

        if let contentView = window?.contentView {
            contentView.addSubview(mainStack)
            contentView.addSubview(errorView)
            contentView.addSubview(stopButton)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        guard let contentView = window?.contentView else {
            return
        }

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),

            errorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            errorView.topAnchor.constraint(equalTo: mainStack.bottomAnchor, constant: 4),
            errorView.bottomAnchor.constraint(equalTo: stopButton.topAnchor, constant: -20),

            stopButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stopButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            stopButton.widthAnchor.constraint(equalToConstant: 100),
        ])
    }

    private static func createWindow() -> NSWindow {
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

    // MARK: - Sheet

    func beginSheetModal(
        for callerWindow: NSWindow,
        processingItemsCount: Int,
        totalSize: Int64,
        singleItem: Bool
    ) {
        setProcessingItemsCount(processingItemsCount)
        sizeLeft = totalSize
        operationOnSingleItem = singleItem

        if let window {
            callerWindow.beginSheet(window, completionHandler: nil)
        }
    }

    func endSheet() {
        // call orderOut only if the sheet wasn't already closed
        if let window,
           window.isVisible {
            window.sheetParent?.endSheet(window)
        }
        stopRun()
    }

    // MARK: - Start/Stop, wait and running

    @objc
    func stop(_ sender: AnyObject) {
        if !isRunning() {
            closeSheet(sender)
            return
        }
        // the lock must not be held across the alert, otherwise the worker
        // blocks the main thread while the modal run loop drains the main queue
        pauseCondition.lock()
        isPaused = true
        pauseCondition.unlock()

        // the worker must be resumed on every exit path
        defer {
            pauseCondition.lock()
            isPaused = false
            pauseCondition.broadcast()
            pauseCondition.unlock()
        }

        let retVal = NSAlert.showModalStopLongRunningOperation()

        // the operation can complete while the alert is on screen, the
        // completion path has already chosen whether to keep the sheet open
        guard isRunning() else {
            return
        }

        if retVal {
            stopButton.isEnabled = false
            stopRun()
        }
    }

    private func closeSheet(_ sender: AnyObject) {
        window?.orderOut(sender)
    }

    func startRun() {
        runningLock.withLock { running = true }
    }

    func stopRun() {
        runningLock.withLock { running = false }
        fileOpCancelled = true
    }

    nonisolated func isRunning() -> Bool {
        runningLock.withLock { running }
    }

    nonisolated func waitPause() {
        pauseCondition.lock()
        while isPaused {
            pauseCondition.wait()
        }
        pauseCondition.unlock()
    }

    // MARK: - UI progression components update

    func updateItem(path: String) {
        itemPath.stringValue = path
    }

    func updateItem(
        path: String,
        isFile: Bool,
        fileSize: Int64
    ) {
        updateItem(path: path)
        incrementProcessingItems()
        if isFile {
            sizeLeft -= fileSize
        }
    }

    func update(
        completedBytes: Int64,
        totalBytes: Int64,
        throughput: Int64
    ) {
        completionIndicator.update(
            completedBytes: completedBytes,
            totalBytes: totalBytes,
            throughput: throughput
        )
    }

    // MARK: - File replace cornfirmation code

    func canReplace(
        fromPath: String,
        fromAttrs: [FileAttributeKey: Any]?,
        toPath: String,
        toAttrs: [FileAttributeKey: Any]?
    ) -> Bool {
        let confirmReplace = ConfirmReplace(
            yesToAll: yesToAll,
            noToAll: noToAll,
            confirmHandler: replaceHandler
        )
        return confirmReplace.canReplace(
            fromPath: fromPath,
            fromAttrs: fromAttrs,
            toPath: toPath,
            toAttrs: toAttrs
        )
    }

    func replaceHandler(
        confirmReplace _: ConfirmReplace,
        replaceInfo: [ReplaceFileAttributeKey: Any]
    ) -> Bool {
        let alert = NSAlert()
        alert.replaceFile(
            from: replaceInfo,
            operationOnSingleItem: operationOnSingleItem
        )

        switch alert.runModal().replaceFile {
        case .cancel:
            stopRun()
            return false
        case .noToAll:
            fileOpCancelled = true
            noToAll = true
            return false
        case .no:
            fileOpCancelled = true
            return false
        case .yesToAll:
            yesToAll = true
            return true
        case .yes:
            return true
        default:
            return false
        }
    }

    func prepare(with fileSize: Int64) {
        fileOpCompleted = false
        fileOpCancelled = false

        completionIndicator.reset(maxValue: Double(fileSize))
    }

    func turnButtonToClose() {
        stopRun()
        stopButton.title = NSLocalizedString("Close", comment: "")
        stopButton.isEnabled = true
    }

    func endSheetAfterCompletion() {
        if errors.isEmpty {
            endSheet()
        } else {
            turnButtonToClose()
        }
    }

    // MARK: - Error Helpers

    func add(error: NSError, forPath path: String) {
        errorView.addError(error, forPath: path)
    }

    // MARK: - Text Helpers

    func resetProcessingItems() {
        processingItemsIndicator.doubleValue = 0
    }

    func incrementProcessingItems() {
        let newValue = processingItemsIndicator.doubleValue + 1
        processingItemsIndicator.doubleValue = newValue
        itemsLeftView.text.stringValue = String(format: "%ld", Int(processingItemsIndicator.maxValue - newValue))
    }

    func setProcessingItemsCount(_ newValue: Int) {
        processingItemsIndicator.maxValue = Double(newValue)
        itemsLeftView.text.stringValue = String(format: "%ld", newValue)
    }

    private func updateSizeLeftDisplay() {
        sizeLeftView.text.stringValue = sizeLeft > 0
            ? FileSizeFormatter.default.string(from: NSNumber(value: sizeLeft)) ?? "0"
            : "0"
    }
}
