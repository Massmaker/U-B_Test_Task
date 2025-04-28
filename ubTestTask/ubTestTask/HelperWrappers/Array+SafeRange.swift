//
//  Array+SafeRange.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 28.04.2025.
//

import Foundation
extension Array {
    /// Safely accesses a sub-array within the given range.
    /// Returns a new array containing the elements within the valid portion of the range.
    subscript(safe range: Range<Index>) -> [Element] {
        let lowerBound = Swift.max(range.lowerBound, startIndex)
        let upperBound = Swift.min(range.upperBound, endIndex)

        guard lowerBound < upperBound else {
            return []
        }

        return Array(self[lowerBound..<upperBound])
    }

    /// Safely accesses a sub-array within the given closed range.
    /// Returns a new array containing the elements within the valid portion of the range.
    subscript(safe range: ClosedRange<Index>) -> [Element] {
        let lowerBound = Swift.max(range.lowerBound, startIndex)
        let upperBound = Swift.min(range.upperBound, endIndex - 1) // Adjust for closed range

        guard lowerBound <= upperBound else {
            return []
        }

        return Array(self[lowerBound...upperBound])
    }
}
