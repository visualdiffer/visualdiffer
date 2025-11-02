//
//  IntegerFormatter.swift
//  VisualDiffer
//
//  Created by davide ficano on 07/03/13.
//  Copyright (c) 2013 visualdiffer.com
//

class IntegerFormatter: NumberFormatter, @unchecked Sendable {
    override open func isPartialStringValid(
        _ partialString: String,
        newEditingString _: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        if partialString.isEmpty {
            return true
        }

        // it is valid if contains only decimal digits
        return partialString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
