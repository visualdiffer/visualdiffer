//
//  PreferencesPanelDataSource.swift
//  VisualDiffer
//
//  Created by davide ficano on 18/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

protocol PreferencesPanelDataSource {
    @MainActor func reloadData()
}
