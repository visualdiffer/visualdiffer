//
//  EquivalenceTable.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/08/26.
//  Copyright (c) 2026 visualdiffer.com
//

/// translates sequence elements into equivalence codes, so the comparison algorithm
/// only ever compares integers and never touches the original elements
///
/// The same table must encode both sequences, otherwise equal elements would get
/// different codes.
struct EquivalenceTable<Key: Hashable> {
    private var codes = [Key: Int]()
    // code 0 is never assigned, the comparison algorithm uses it as the unset marker
    private var nextCode = 1

    /// one more than the greatest assigned code
    var codeCount: Int {
        nextCode
    }

    mutating func encode(_ keys: [Key]) -> [Int] {
        keys.map { key in
            if let code = codes[key] {
                return code
            }
            let code = nextCode

            codes[key] = code
            nextCode += 1

            return code
        }
    }
}
