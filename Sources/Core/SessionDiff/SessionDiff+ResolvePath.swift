//
//  SessionDiff+ResolvePath.swift
//  VisualDiffer
//
//  Created by davide ficano on 08/12/20.
//  Copyright (c) 2020 visualdiffer.com
//

extension SessionDiff {
    /**
     * Return the left or right path, if necessary resolve the symlink or choose path if not sandboxed
     * If the selected path is different from the current one update self.leftPath or self.rightPath
     * @param side the path side
     * @param fileType the file type to select using open panel
     * @param alwaysResolveSymlinks determine if symlinks must be resolved
     * @return the selected path
     */
    @MainActor
    func resolvePath(
        for side: Side,
        chooseFileType fileType: ItemType,
        alwaysResolveSymlinks: Bool
    ) -> URL? {
        let resolveLeft = side == .left
        let resolvePath = resolveLeft ? leftPath : rightPath

        // if path is empty we are comparing a single file
        // so it isn't necessary to verify the path
        guard let resolvePath,
              !resolvePath.isEmpty else {
            return nil
        }

        let resolvedInfo = URL(filePath: resolvePath)
            .resolveSymLinksAndAliases(
                chooseFiles: fileType == .file,
                chooseDirectories: fileType == .folder,
                panelTitle: side.panelTitle(chooseFileType: fileType),
                alwaysResolveSymlinks: alwaysResolveSymlinks
            )
        // assign to sessionDiff only if path differs otherwise the document is considered dirty
        guard let (resolvedUrl, selectedAnotherPath) = resolvedInfo else {
            return nil
        }

        if selectedAnotherPath {
            if resolveLeft {
                leftPath = resolvedUrl.osPath
            } else {
                rightPath = resolvedUrl.osPath
            }
        }

        return resolvedUrl
    }
}

extension SessionDiff.Side {
    func panelTitle(chooseFileType fileType: SessionDiff.ItemType) -> String {
        let sideText = (self == .left)
            ? NSLocalizedString("Left", comment: "Left")
            : NSLocalizedString("Right", comment: "Right")

        let typeText = (fileType == .folder)
            ? NSLocalizedString("Folder", comment: "Folder type")
            : NSLocalizedString("File", comment: "File type")

        let format = NSLocalizedString(
            "%@ %@ Not Accessible (Maybe required by sandbox)",
            comment: "Message when a folder or file is not accessible"
        )

        return String(format: format, sideText, typeText)
    }
}
