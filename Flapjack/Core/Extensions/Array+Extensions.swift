//
//  Array+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/7/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public extension Array where Element: AnyObject & Equatable {
    func index(of object: Element, pointerComparison: Bool) -> Index? {
        guard pointerComparison else {
            return index(of: object)
        }
        return enumerated().first { $0.element === object }?.offset
    }

    func sorted(using descriptors: [SortDescriptor]) -> [Element] {
        return (self as NSArray).sortedArray(using: descriptors.asNSSortDescriptors) as? [Element] ?? []
    }
}


public extension RangeReplaceableCollection {
    mutating func remove<S: Sequence>(atIndexes indexes: S) where S.Iterator.Element == Self.Index {
        indexes.sorted().lazy.reversed().forEach { remove(at: $0) }
    }
}
