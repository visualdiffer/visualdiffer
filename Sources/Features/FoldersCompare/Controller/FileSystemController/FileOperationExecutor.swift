//
//  FileOperationExecutor.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

public protocol FileOperationExecutor<TPayload>: Sendable {
    associatedtype TPayload: Sendable

    var title: String { get }
    var summary: String { get }
    var image: NSImage? { get }
    var progressLabel: String { get }
    var prefName: CommonPrefs.Name? { get }

    var operationOnSingleItem: Bool { get }

    func execute(_ manager: FileOperationManagerAction, payload: TPayload?)
}
