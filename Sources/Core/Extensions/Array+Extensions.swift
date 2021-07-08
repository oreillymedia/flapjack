//
//  Array+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/7/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public extension Array where Element: AnyObject & Equatable {
    /**
     Returns a copy of this array sorted using an array of `SortDescriptor` objects.

     - parameter descriptors: The `SortDescriptor` objects to use; these will be transformed into `NSSortDescriptor`
                              versions and run against the array as an `NSArray`.
     - returns: A new sorted array.
     */
    func sorted(using descriptors: [SortDescriptor]) -> [Element] {
        return (self as NSArray).sortedArray(using: descriptors.asNSSortDescriptors) as? [Element] ?? []
    }
}


internal extension Array where Element: AnyObject & Equatable {
    func firstIndex(of object: Element, pointerComparison: Bool) -> Index? {
        guard pointerComparison else {
            return firstIndex(of: object)
        }
        return enumerated().first { $0.element === object }?.offset
    }
}

internal extension RangeReplaceableCollection {
    mutating func remove<S: Sequence>(atIndexes indexes: S) where S.Iterator.Element == Self.Index {
        indexes.sorted().lazy.reversed().forEach { remove(at: $0) }
    }
}
