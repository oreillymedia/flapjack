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
    var primaryKey: PrimaryKeyType? {
        return self.value(forKey: type(of: self).primaryKeyPath) as? PrimaryKeyType
    }

    var context: DataContext? {
        return managedObjectContext
    }
}
