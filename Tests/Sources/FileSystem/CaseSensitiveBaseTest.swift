//
//  CaseSensitiveBaseTest.swift
//  VisualDiffer
//
//  Created by davide ficano on 17/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Foundation
import Testing

open class CaseSensitiveBaseTest: BaseTests {
    static let serialQueue = DispatchQueue(label: "com.visualdiffer.volume.testQueue")

    let volumeName = "VDTestsMatchCase_Swift"
    let volumePath: URL

    override public init(rootDir _: URL) {
        volumePath = URL(filePath: "/Volumes/\(volumeName)/")
        super.init(rootDir: volumePath)

        mountVolume()
    }

    public func mountVolume() {
        Self.serialQueue.sync {
            // create the case sensitive ram disk if necessary
            if !FileManager.default.fileExists(atPath: volumePath.osPath) {
                let process = Process()
                process.executableURL = URL(filePath: "/bin/sh")
                process.arguments = ["-c", "diskutil erasevolume 'Case-sensitive HFS+' '\(volumeName)' `hdiutil attach -nomount ram://1048576`"]
                do {
                    try process.run()
                } catch {
                    Issue.record("Failed to create volume \(volumeName) \(error)")
                }
                process.waitUntilExit()
            }
        }
    }
}

extension CaseSensitiveBaseTest {
    func assertVolumeMounted(sourceLocation: SourceLocation = #_sourceLocation) throws {
        try #require(
            fm.fileExists(atPath: rootDir.deletingLastPathComponent().osPath),
            "Unable to find the case sensitive disk, test can't be executed",
            sourceLocation: sourceLocation
        )
    }
}
