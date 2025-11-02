//
//  CommonPrefs+DifferenceNavigator.swift
//  VisualDiffer
//
//  Created by davide ficano on 13/02/21.
//  Copyright (c) 2021 visualdiffer.com
//

extension CommonPrefs.Name {
    enum Navigator {
        static let wrap = CommonPrefs.Name(rawValue: "foldersDifferenceNavigatorWrap")
        static let traverseFolders = CommonPrefs.Name(rawValue: "foldersDifferenceNavigatorTraverseFolders")
        static let centerInWindow = CommonPrefs.Name(rawValue: "foldersDifferenceNavigatorCenterInWindow")
    }
}

extension CommonPrefs {
    var folderDifferenceNavigatorWrap: DifferenceNavigator {
        bool(forKey: .Navigator.wrap) ? .wrap : []
    }

    var folderDifferenceNavigatorTraverseFolders: DifferenceNavigator {
        bool(forKey: .Navigator.traverseFolders) ? .traverseFolders : []
    }

    var folderDifferenceNavigatorCenterInWindow: DifferenceNavigator {
        bool(forKey: .Navigator.centerInWindow) ? .centerInWindow : []
    }

    var folderDifferenceNavigatorOptions: DifferenceNavigator {
        [
            folderDifferenceNavigatorWrap,
            folderDifferenceNavigatorTraverseFolders,
            folderDifferenceNavigatorCenterInWindow,
        ]
    }
}
