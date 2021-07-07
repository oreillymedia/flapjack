//
//  DataSourceSectionChange.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/18/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 Describes a change in position for a section grouping of content observed by a data source. This can be an insertion or
 a deletion. Each case comes with the relevant section index information.
 */
public enum DataSourceSectionChange: CustomStringConvertible, Hashable, Equatable {
    /// Describes an insertion of a new section into the data source's grouped object set.
    case insert(section: Int)
    /// Describes a deletion of an existing section from the data source's grouped object set.
    case delete(section: Int)

    public var description: String {
        switch self {
        case .insert(let section): return "insert (section: \(section))"
        case .delete(let section): return "delete (section: \(section))"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}
