//
//  DataSourceChange.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public enum DataSourceChange: CustomStringConvertible, Hashable {
    case insert(path: IndexPath)
    case delete(path: IndexPath)
    case move(from: IndexPath, toPath: IndexPath)
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
    
    public var hashValue: Int {
        return description.hashValue
    }
}
