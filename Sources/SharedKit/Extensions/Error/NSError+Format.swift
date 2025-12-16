//
//  NSError+Format.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/08/11.
//  Copyright (c) 2011 visualdiffer.com
//

extension NSError {
    func format(withPath path: String) -> String {
        switch domain {
        case NSOSStatusErrorDomain:
            String(format: "%@: %@", path, self)
        case NSCocoaErrorDomain:
            if code == NSFileReadNoPermissionError,
               let attrs = try? FileManager.default.attributesOfItem(atPath: path).fileAttributeType,
               attrs == .typeSymbolicLink,
               let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
                String.localizedStringWithFormat(
                    NSLocalizedString("Permission denied: symbolic link at %@ points to destination %@. Add the destination to 'Trusted Paths' to allow access.", comment: ""),
                    path,
                    destination
                )
            } else {
                String(format: "%@: %@", path, localizedDescription)
            }
        default:
            String(format: "%@: %@", path, localizedDescription)
        }
    }
}
