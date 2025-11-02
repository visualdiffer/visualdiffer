//
//  DisplayOptions.swift
//  VisualDiffer
//
//  Created by davide ficano on 27/10/10.
//  Copyright (c) 2010 visualdiffer.com
//

public struct DisplayOptions: OptionSet, Sendable {
    public let rawValue: Int

    public static let offset = DisplayOptions(rawValue: 0x100)
    public static let onlyMatches = DisplayOptions(rawValue: offset.rawValue | 1 << 0)
    public static let onlyLeftSideNewer = DisplayOptions(rawValue: offset.rawValue | 1 << 1)
    public static let onlyLeftSideOrphans = DisplayOptions(rawValue: offset.rawValue | 1 << 2)
    public static let onlyRightSideNewer = DisplayOptions(rawValue: offset.rawValue | 1 << 3)
    public static let onlyRightSideOrphans = DisplayOptions(rawValue: offset.rawValue | 1 << 4)
    public static let mismatchesButNoOrphans: DisplayOptions = [
        DisplayOptions(rawValue: 1 << 5),
        .offset,
        .onlyLeftSideNewer,
        .onlyRightSideNewer,
    ]

    public static let leftNewerAndLeftOrphans: DisplayOptions = [
        .onlyLeftSideNewer,
        .onlyLeftSideOrphans,
    ]
    public static let rightNewerAndRightOrphans: DisplayOptions = [
        .onlyRightSideNewer,
        .onlyRightSideOrphans,
    ]

    public static let onlyMismatches: DisplayOptions = [
        .leftNewerAndLeftOrphans,
        .rightNewerAndRightOrphans,
        .mismatchesButNoOrphans,
    ]
    public static let noOrphan: DisplayOptions = [
        .mismatchesButNoOrphans,
        .onlyMatches,
    ]
    public static let onlyOrphans: DisplayOptions = [
        .onlyLeftSideOrphans,
        .onlyRightSideOrphans,
    ]

    public static let showAll: DisplayOptions = [
        .noOrphan,
        .onlyOrphans,
    ]

    // Mask with all file flags
    public static let fileTypeMask: DisplayOptions = [
        .onlyMatches,
        .onlyLeftSideNewer,
        .onlyLeftSideOrphans,
        .onlyRightSideNewer,
        .onlyRightSideOrphans,
        .mismatchesButNoOrphans,
    ]

    public static let dontFollowSymlinks = DisplayOptions(rawValue: 0x200)
    public static let noOrphansFolders = DisplayOptions(rawValue: 1 << 10)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
