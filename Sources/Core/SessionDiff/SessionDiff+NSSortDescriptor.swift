//
//  SessionDiff+NSSortDescriptor.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/06/20.
//  Copyright (c) 2020 visualdiffer.com
//

extension NSSortDescriptor {
    enum SessionDiff: String {
        case name = "fileName"
        case size = "fileSize"
        case modificationDate = "fileModificationDate"
    }
}

extension SessionDiff.Column {
    func toSortDescriptorKey() -> NSSortDescriptor.SessionDiff {
        switch self {
        case .name:
            .name
        case .size:
            .size
        case .modificationDate:
            .modificationDate
        }
    }

    static func from(sortDescription: NSSortDescriptor.SessionDiff) -> SessionDiff.Column {
        switch sortDescription {
        case .name:
            .name
        case .size:
            .size
        case .modificationDate:
            .modificationDate
        }
    }
}

extension SessionDiff {
    func updateSortColumn(
        from sortDescriptor: NSSortDescriptor,
        side: Side
    ) {
        let key: NSSortDescriptor.SessionDiff = if let key = sortDescriptor.key {
            NSSortDescriptor.SessionDiff(rawValue: key) ?? .name
        } else {
            .name
        }
        currentSortColumn = SessionDiff.Column.from(sortDescription: key)
        isCurrentSortAscending = sortDescriptor.ascending
        currentSortSide = side
    }

    func columnSortDescriptor() -> NSSortDescriptor {
        let key = currentSortColumn.toSortDescriptorKey()
        let ascending = isCurrentSortAscending
        return NSSortDescriptor(key: key.rawValue, ascending: ascending)
    }
}
