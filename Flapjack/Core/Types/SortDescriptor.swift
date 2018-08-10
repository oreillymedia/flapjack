//
//  SortDescriptor.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public struct SortDescriptor {
    public var keyPath: String
    public var ascending: Bool
    public var caseInsensitive: Bool

    public init(_ keyPath: String, ascending: Bool = true, caseInsensitive: Bool = false) {
        self.keyPath = keyPath
        self.ascending = ascending
        self.caseInsensitive = caseInsensitive
    }

    public var asNSSortDescriptor: NSSortDescriptor {
        if caseInsensitive {
            return NSSortDescriptor(key: keyPath, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
        return NSSortDescriptor(key: keyPath, ascending: ascending)
    }

    public var cacheKey: String {
        return "\(keyPath).\(ascending ? 1 : 0).\(caseInsensitive ? 1 : 0)"
    }
}


public extension Sequence where Element == SortDescriptor {
    var asNSSortDescriptors: [NSSortDescriptor] {
        return map { $0.asNSSortDescriptor }
    }

    var cacheKey: String {
        return map { $0.cacheKey }.joined(separator: "-")
    }
}
