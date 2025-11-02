//
//  URL+FileManager.swift
//  VisualDiffer
//
//  Created by davide ficano on 10/03/25.
//  Copyright (c) 2025 visualdiffer.com
//

public extension URL {
    func isFileDirectory() throws -> Bool {
        let resources = try resourceValues(forKeys: [.isDirectoryKey])

        if let isDirectory = resources.isDirectory {
            return isDirectory
        }

        return false
    }

    /**
     * URL appends "/" to the end but this causes problems with the symlink, so it is removed to get the correct result
     */
    func destinationOfSymbolicLink(directoryHint: DirectoryHint = .inferFromPath) throws -> URL {
        let realPath = try FileManager.default.destinationOfSymbolicLink(atPath: osPath)

        return URL(filePath: realPath, directoryHint: directoryHint)
    }

    func createSymbolicLink(withDestination destination: URL) throws {
        try FileManager.default.createSymbolicLink(atPath: osPath, withDestinationPath: destination.osPath)
    }
}
