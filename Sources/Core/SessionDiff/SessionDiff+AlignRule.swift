//
//  SessionDiff+AlignRule.swift
//  VisualDiffer
//
//  Created by davide ficano on 28/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension SessionDiff {
    var fileNameAlignments: [AlignRule]? {
        get {
            guard let fileNameAlignmentsData else {
                return nil
            }
            let allowedClasses: [AnyClass] = [
                NSArray.self,
                NSMutableDictionary.self,
                NSString.self,
                NSNumber.self,
            ]
            do {
                let data = try NSKeyedUnarchiver.unarchivedObject(
                    ofClasses: allowedClasses,
                    from: fileNameAlignmentsData
                )
                return (data as? [[String: Any]])?.compactMap { AlignRule($0) }
            } catch {
                NSLog("Unable to unarchive file name alignments array \(error)")

                return nil
            }
        }

        set {
            if let newValue, !newValue.isEmpty {
                let list = newValue.map { $0.toDictionary() }
                do {
                    fileNameAlignmentsData = try NSKeyedArchiver.archivedData(
                        withRootObject: list,
                        requiringSecureCoding: false
                    )
                } catch {
                    NSLog("Unable to save file name alignments array \(error)")
                    fileNameAlignmentsData = nil
                }
            } else {
                fileNameAlignmentsData = nil
            }
        }
    }
}
