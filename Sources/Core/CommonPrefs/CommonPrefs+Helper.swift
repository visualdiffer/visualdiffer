//
//  CommonPrefs+Helper.swift
//  VisualDiffer
//
//  Created by davide ficano on 09/09/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension CommonPrefs {
    func number(forKey: CommonPrefs.Name, _ defaultValue: Bool) -> NSNumber {
        object(forKey: forKey) as? NSNumber ?? NSNumber(value: defaultValue)
    }

    func number(forKey: CommonPrefs.Name, _ defaultValue: Int) -> NSNumber {
        object(forKey: forKey) as? NSNumber ?? NSNumber(value: defaultValue)
    }

    func bool(forKey key: CommonPrefs.Name) -> Bool {
        UserDefaults.standard.bool(forKey: key.rawValue)
    }

    func string(forKey key: CommonPrefs.Name) -> String? {
        UserDefaults.standard.string(forKey: key.rawValue)
    }

    func set(_ value: some Any, forKey key: CommonPrefs.Name) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    func integer(forKey key: CommonPrefs.Name) -> Int {
        UserDefaults.standard.integer(forKey: key.rawValue)
    }

    func object(forKey key: CommonPrefs.Name) -> Any? {
        UserDefaults.standard.object(forKey: key.rawValue)
    }

    func removeObject(forKey key: CommonPrefs.Name) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
}
