//
//  DataObject.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import CoreData

// Sadly we have to bring in Core Data and define `NSFetchRequestResult` as a super-protocol.
//   Fortunately it adds no methods and is just a typedef for NSObjectProtocol, but hey.
public protocol DataObject: NSFetchRequestResult {
    static var representedName: String { get }
    static var primaryKeyPath: String { get }
    static var defaultSorters: [SortDescriptor] { get }
    var primaryKey: DataContext.PrimaryKey? { get }
    var context: DataContext? { get }
}

public extension DataObject where Self: NSManagedObject {
    public var primaryKey: DataContext.PrimaryKey? {
        return self.value(forKey: type(of: self).primaryKeyPath) as? DataContext.PrimaryKey
    }
    
    var context: DataContext? {
        return managedObjectContext
    }
}
