//
//  ViewLinkable.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/04/25.
//  Copyright (c) 2025 visualdiffer.com
//

protocol ViewLinkable<T> {
    associatedtype T
    @MainActor var linkedView: T? { get set }
}
