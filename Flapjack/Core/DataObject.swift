//
//  DataObject.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 An abstraction on top of a model object, typically mapped one-to-one to a database entity such as Core Data's
 `NSManagedObject` or Realm's `Realm.Object`. Those conforming to this protocol should be sure to denote the type
 of `PrimaryKey` to expose (through the associated type `PrimaryKeyType`).
 */
public protocol DataObject {
    /// A generic reference to the type belonging to the primary key field of this model.
    associatedtype PrimaryKeyType: PrimaryKey

    /// The string representation of this object's type in a database (like Core Data's entity names).
    static var representedName: String { get }

    /// The keypath to primary key value (a string version of the attribute name).
    static var primaryKeyPath: String { get }

    /// An array of sorting criteria to be applied by default when fetching collections of these objects.
    static var defaultSorters: [SortDescriptor] { get }

    /// The primary key value itself for the object.
    var primaryKey: PrimaryKeyType? { get }

    /// The database context to which this object belongs, if it's part of one.
    var context: DataContext? { get }
}
