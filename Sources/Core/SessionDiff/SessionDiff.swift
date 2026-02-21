//
//  SessionDiff.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/11/10.
//  Copyright (c) 2010 visualdiffer.com
//

@objc(SessionDiff)
public class SessionDiff: NSManagedObject {
    // leftPath and rightPath are computed properties because they use custom validation
    @NSManaged var leftReadOnly: Bool
    @NSManaged var rightReadOnly: Bool

    // legacy fields exposed with computed properties and custom types
    @NSManaged private var comparatorFlags: Int32
    @NSManaged private var displayFilters: Int32
    @NSManaged private var differType: Int16
    @NSManaged private var fileInfoFlags: Int32

    @NSManaged var expandAllFolders: Bool
    @NSManaged var exclusionFileFilters: String?

    @NSManaged var followSymLinks: Bool
    @NSManaged var traverseFilteredFolders: Bool
    @NSManaged var timestampToleranceSeconds: Double

    @NSManaged var skipPackages: Bool
    @NSManaged var allowedPackages: String?

    @NSManaged var fileNameAlignmentsData: Data?

    // Not yet used
    // periphery:ignore
    @NSManaged private var ignoreDST: NSNumber?
    // periphery:ignore
    @NSManaged private var ignoreTimeZone: NSNumber?

    // Used only with ItemType == .folder
    // exposed with computed properties and custom types
    // periphery:ignore
    @NSManaged private var visibleColumns: NSNumber?
    @NSManaged private var sortColumn: Int32
    @NSManaged private var sortAscending: Bool
    @NSManaged private var sortSide: Int32

    // Only expand subfolders with differences
    // periphery:ignore
    @NSManaged private var expandOnlyWithDiffs: Bool
}

extension SessionDiff {
    static let entityName = "Session"

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<SessionDiff> {
        NSFetchRequest<SessionDiff>(entityName: entityName)
    }

    static func newObject(_ moc: NSManagedObjectContext) -> SessionDiff? {
        NSEntityDescription.insertNewObject(
            forEntityName: entityName,
            into: moc
        ) as? SessionDiff
    }

    override open func awakeFromInsert() {
        super.awakeFromInsert()

        let prefs = CommonPrefs.shared

        displayOptions = prefs.displayOptions
        comparatorOptions = prefs.comparatorOptions
        if let defaultFileFilters = prefs.defaultFileFilters {
            exclusionFileFilters = defaultFileFilters
        }
        followSymLinks = prefs.followSymLinks

        traverseFilteredFolders = prefs.bool(forKey: .traverseFilteredFolders)
        timestampToleranceSeconds = prefs.number(forKey: .timestampToleranceSeconds, 0).doubleValue
        skipPackages = prefs.bool(forKey: .skipPackages)
        fileExtraOptions = FileExtraOptions(rawValue: prefs.integer(forKey: .fileInfoFlags))
        expandAllFolders = prefs.bool(forKey: .expandAllFolders)

        extraData = ExtraData.fromUserDefaults()

        leftReadOnly = false
        rightReadOnly = false

        itemType = .folder
    }

    override open func awakeFromFetch() {
        super.awakeFromFetch()

        if let path = leftPath {
            leftPath = URL(filePath: path).standardizingPath
        }
        if let path = rightPath {
            rightPath = URL(filePath: path).standardizingPath
        }

        if timestampToleranceSeconds < 0 {
            timestampToleranceSeconds = 0
        }

        assignDefaultAlignFlags()
    }

    var exclusionFileFiltersPredicate: NSPredicate? {
        guard let exclusionFileFilters else {
            return nil
        }
        return NSPredicate(format: exclusionFileFilters)
    }

    var leftPath: String? {
        get { pathValue("leftPath") }
        set { setPathValue(forKey: "leftPath", path: newValue) }
    }

    var rightPath: String? {
        get { pathValue("rightPath") }
        set { setPathValue(forKey: "rightPath", path: newValue) }
    }

    private func pathValue(_ keyName: String) -> String? {
        willAccessValue(forKey: keyName)
        let value = primitiveValue(forKey: keyName) as? String
        didAccessValue(forKey: keyName)

        return value
    }

    private func setPathValue(forKey keyName: String, path: String?) {
        let value = path?.standardizingPath

        willChangeValue(forKey: keyName)
        setPrimitiveValue(value, forKey: keyName)
        didChangeValue(forKey: keyName)
    }

    // existing sessions may not have a valid default value for Align flag
    private func assignDefaultAlignFlags() {
        let options = comparatorOptions
        if options.onlyAlignFlags.isEmpty {
            let alignFlag = CommonPrefs.shared.comparatorOptions.onlyAlignFlags
            comparatorOptions = [options, alignFlag]
        }
    }

    var itemType: ItemType? {
        get { ItemType(rawValue: differType) }
        set {
            if let newValue {
                differType = newValue.rawValue
            } else {
                differType = 0
            }
        }
    }

    var comparatorOptions: ComparatorOptions {
        get { .init(rawValue: Int(comparatorFlags)) }
        set { comparatorFlags = Int32(newValue.rawValue) }
    }

    var displayOptions: DisplayOptions {
        get { .init(rawValue: Int(displayFilters)) }
        set { displayFilters = Int32(newValue.rawValue) }
    }

    var fileExtraOptions: FileExtraOptions {
        get { .init(rawValue: Int(fileInfoFlags)) }
        set { fileInfoFlags = Int32(newValue.rawValue) }
    }

    var isCurrentSortAscending: Bool {
        get { sortAscending }
        set { sortAscending = newValue }
    }

    var currentSortColumn: Column {
        get { Column(rawValue: Int(sortColumn)) ?? .name }
        set { sortColumn = Int32(newValue.rawValue) }
    }

    var currentSortSide: Side {
        get { Side(rawValue: Int(sortSide)) ?? .left }
        set { sortSide = Int32(newValue.rawValue) }
    }

    /// Returns the default file filters in CommonPrefs, if CommonPrefs doesn't contain any value
    /// then inspect the Session model default value
    static func defaultFileFilters() -> String? {
        if let defaultFilters = CommonPrefs.shared.defaultFileFilters {
            return defaultFilters
        }

        let model = NSManagedObjectModel.mergedModel(from: nil)
        let entity = model?.entitiesByName[entityName]
        let attribute = entity?.attributesByName["exclusionFileFilters"]
        return attribute?.defaultValue as? String
    }

    func observeComparatorOptions(_ closure: @escaping @Sendable (ComparatorOptions) -> Void) -> NSKeyValueObservation {
        observe(\.comparatorFlags, options: [.new]) { _, change in
            if let flags = change.newValue {
                closure(ComparatorOptions(rawValue: Int(flags)))
            }
        }
    }
}
