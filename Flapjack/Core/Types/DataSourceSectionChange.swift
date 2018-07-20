//
//  DataSourceSectionChange.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public enum DataSourceSectionChange: CustomStringConvertible, Hashable {
    case insert(section: Int)
    case delete(section: Int)
    
    public var section: Int {
        switch self {
        case .insert(let section), .delete(let section): return section
        }
    }
    
    public var description: String {
        switch self {
        case .insert(let section): return "insert (section: \(section))"
        case .delete(let section): return "delete (section: \(section))"
        }
    }
    
    public var hashValue: Int {
        return description.hashValue
    }
}
