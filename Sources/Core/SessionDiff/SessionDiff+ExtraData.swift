//
//  SessionDiff+ExtraData.swift
//  VisualDiffer
//
//  Created by davide ficano on 16/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

struct ExtraData {
    private enum Keys {
        static let diffResultOptions = "diffResultOptions"
    }

    var diffResultOptions: DiffResult.Options = []

    init() {}

    init(dictionary: [String: Any]) {
        if let options = dictionary[Keys.diffResultOptions] as? Int {
            diffResultOptions = DiffResult.Options(rawValue: options)
        }
    }

    func toDictionary() -> [String: Any] {
        [
            Keys.diffResultOptions: diffResultOptions.rawValue,
        ]
    }

    static func fromUserDefaults() -> ExtraData {
        let options: [(CommonPrefs.Name, DiffResult.Options)] = [
            (.ignoreLineEndings, .ignoreLineEndings),
            (.ignoreLeadingWhitespaces, .ignoreLeadingWhitespaces),
            (.ignoreTrailingWhitespaces, .ignoreTrailingWhitespaces),
            (.ignoreInternalWhitespaces, .ignoreInternalWhitespaces),
        ]

        var data = ExtraData()

        for (prefName, option) in options {
            data.diffResultOptions.setValue(CommonPrefs.shared.bool(forKey: prefName), element: option)
        }

        return data
    }
}

extension SessionDiff {
    @NSManaged public var extraDataJSON: Data?

    var extraData: ExtraData {
        get {
            guard let data = extraDataJSON,
                  let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return ExtraData()
            }
            return ExtraData(dictionary: dictionary)
        }
        set {
            extraDataJSON = try? JSONSerialization.data(withJSONObject: newValue.toDictionary())
        }
    }
}
