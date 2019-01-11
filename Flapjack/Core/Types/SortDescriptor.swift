//
//  SortDescriptor.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 A simple struct for encapsulating rules for sorting a list. Conveniently maps to `NSSortDescriptor` when necessary.
 */
public struct SortDescriptor {
    /// The stringified version of the object's keypath by which to sort. Can also be supplied as `#keyPath(...)`.
    public var keyPath: String
    /// Whether or not to sort ascending; default is `true`.
    public var ascending: Bool
    /// Whether or not to disregard case sensitivity on sorting strings; default is `false` (case matters).
    public var caseInsensitive: Bool

    /**
     Initializes a new `SortDescriptor`, ready to use.

     - parameter keyPath: The stringified version of the object's keypath by which to sort. Can also be supplied as
                          `#keyPath(...)`.
     - parameter ascending: Whether or not to sort ascending; default is `true`.
     - parameter caseInsensitive: Whether or not to disregard case sensitivity on sorting strings; default is `false`
                                  (case matters).
     */
    public init(_ keyPath: String, ascending: Bool = true, caseInsensitive: Bool = false) {
        self.keyPath = keyPath
        self.ascending = ascending
        self.caseInsensitive = caseInsensitive
    }

    /// Converts this into an `NSSortDescriptor`, using `NSString.caseInsensitiveCompare` if necessary.
    public var asNSSortDescriptor: NSSortDescriptor {
        if caseInsensitive {
            return NSSortDescriptor(key: keyPath, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
        return NSSortDescriptor(key: keyPath, ascending: ascending)
    }

    /// A unique string version of the contents of this sort descriptor, handy for injecting into a longer cache key.
    public var cacheKey: String {
        return "\(keyPath).\(ascending ? 1 : 0).\(caseInsensitive ? 1 : 0)"
    }
}


public extension Sequence where Element == SortDescriptor {
    /// Converts a sequence of `SortDescriptor` objects into its `NSSortDescriptor` array equivalent.
    var asNSSortDescriptors: [NSSortDescriptor] {
        return map { $0.asNSSortDescriptor }
    }

    /// Converts a sequence of `SortDescriptor` objects into a unique string for injecting into a longer cache key.
    var cacheKey: String {
        return map { $0.cacheKey }.joined(separator: "-")
    }
}
