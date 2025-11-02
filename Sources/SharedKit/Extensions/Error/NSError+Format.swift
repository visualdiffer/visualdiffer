//
//  NSError+Format.swift
//  VisualDiffer
//
//  Created by davide ficano on 31/08/11.
//  Copyright (c) 2011 visualdiffer.com
//

extension NSError {
    func format(withPath path: String) -> String {
        if domain == NSOSStatusErrorDomain {
            String(format: "%@: %@", path, self)
        } else {
            String(format: "%@: %@", path, localizedDescription)
        }
    }
}
