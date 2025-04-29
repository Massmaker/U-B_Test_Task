//
//  Array+SafeIndexSubscript.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 29.04.2025.
//

import Foundation
extension Array {
    subscript(safe index:Int) -> Element? {
        if self.isEmpty {
            return nil
        }
        if index < 0 {
            return nil
        }
        
        let count = self.count
        if count - index > 0 {
            return self[index]
        }
        return nil
    }
}
