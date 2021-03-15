//
//  DataSourceChange.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 Describes a change in position for an element observed by a data source. This can be an insertion, a deletion, a move,
 or an update-in-place. Each case comes with the relevant index path information.
 */
public enum DataSourceChange: CustomStringConvertible, Hashable, Equatable {
    /// Describes an insertion into the data source's object set at a given index path.
    case insert(path: IndexPath)
    /// Describes a deletion from the data source's object set at a given index path.
    case delete(path: IndexPath)
    /// Describes a positional move from the data source's object set from an index path to another index path.
    case move(from: IndexPath, toPath: IndexPath)
    /// Describes an in-place update in the data source's object set (the object should then be refreshed).
    case update(path: IndexPath)

    public var description: String {
        switch self {
        case .insert(let path):
            return "insert (path: \(path))"
        case .delete(let path):
            return "delete (path: \(path))"
        case .move(let from, let toPath):
            return "move (from: \(from), toPath: \(toPath))"
        case .update(let path):
            return "update (path: \(path))"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}
