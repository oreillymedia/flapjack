//
//  NSManagedObject+DataObject.swift
//  Flapjack
//
//  Created by Ben Kreeger on 8/16/18.
//

import Foundation
import CoreData
#if !COCOAPODS
import Flapjack
#endif

public extension DataObject where Self: NSManagedObject {
    /// The primary key value itself for this object.
    var primaryKey: PrimaryKeyType? {
        return self.value(forKey: type(of: self).primaryKeyPath) as? PrimaryKeyType
    }

    /// The database context to which this object belongs, if it's part of one.
    var context: DataContext? {
        return managedObjectContext
    }
}
