//
//  Collection+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 1/25/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

extension Collection {
    /**
     Returns an optional element. If the `index` does not exist in the collection, the subscript returns nil.
     
     - parameter safe: The index of the element to return, if it exists.
     - returns: An optional element from the collection at the specified index.
     */
    public subscript(safe i: Index) -> Self.Iterator.Element? {
        return at(i)
    }
    
    /**
     Returns an optional element. If the `index` does not exist in the collection, the function returns nil.
     
     - parameter index: The index of the element to return, if it exists.
     - returns: An optional element from the collection at the specified index.
     */
    public func at(_ i: Index) -> Self.Iterator.Element? {
        return indices.contains(i) ? self[i] : nil
    }
}

#if swift(>=4.1)
#else
    extension Collection {
        public func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
            return try flatMap(transform)
        }
    }
    extension EnumeratedSequence {
        public func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
            return try flatMap(transform)
        }
    }
#endif
