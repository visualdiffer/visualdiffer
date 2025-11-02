//
//  NSOpenPanel+Application.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/08/11.
//  Copyright (c) 2011 visualdiffer.com
//

extension NSOpenPanel {
    @objc func openApplication(title: String) -> NSOpenPanel {
        self.title = title
        // since 10.11 the title is no longer shown so we use the message property
        message = title
        allowsMultipleSelection = false
        allowedContentTypes = [
            .application,
            .applicationBundle,
            .executable,
        ]
        let paths = NSSearchPathForDirectoriesInDomains(
            .applicationDirectory,
            .localDomainMask,
            true
        )
        if !paths.isEmpty {
            directoryURL = URL(filePath: paths[0])
        }
        return self
    }
}
