//
//  NonEmptyContainer.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation
struct NonEmptyContainer<T:Collection & Sendable> {
    private(set) var value:T
    init?(_ value: T) {
        guard !value.isEmpty else {
            return nil
        }
        self.value = value
            
    }
}

//extension NonEmptyContainer:Sendable where T.Element:Sendable {
//    
//}

