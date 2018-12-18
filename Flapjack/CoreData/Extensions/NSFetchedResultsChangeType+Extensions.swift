//
//  NSFetchedResultsChangeType+Extensions.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 5/17/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

extension NSFetchedResultsChangeType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .delete: return "delete"
        case .insert: return "insert"
        case .update: return "update"
        case .move:   return "move"
        }
    }

    internal func asDataSourceSectionChange(section: Int) -> DataSourceSectionChange? {
        switch self {
        case .insert: return .insert(section: section)
        case .delete: return .delete(section: section)
        case .update, .move: return nil
        }
    }

    internal func asDataSourceChange(at path: IndexPath?, newPath: IndexPath?) -> DataSourceChange? {
        switch self {
        case .insert:
            guard let newPath = newPath else {
                return nil
            }
            return .insert(path: newPath)
        case .delete:
            guard let path = path else {
                return nil
            }
            return .delete(path: path)
        case .move:
            guard let path = path, let newPath = newPath else {
                return nil
            }
            if path == newPath {
                return .update(path: path)
            }
            return .move(from: path, toPath: newPath)
        case .update:
            guard let path = path else {
                return nil
            }
            return .update(path: path)
        }
    }
}
