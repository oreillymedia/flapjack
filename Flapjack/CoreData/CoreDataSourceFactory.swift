//
//  CoreDataSourceFactory.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
#if !COCOAPODS
import Flapjack
#endif


// MARK: - CoreDataSourceFactory

public class CoreDataSourceFactory {
    private let dataAccess: DataAccess


    // MARK: Lifecycle

    public init(dataAccess: DataAccess) {
        self.dataAccess = dataAccess
    }


    // MARK: Public functions

    /**
     Creates and returns a data source that will get notified when any objects of a given type are changed, inserted, or
     deleted.

     - returns: A data source that will get notified when any objects of a given type are changed, inserted, or deleted.
     */
    public func vendAllObjectsDataSource<T: DataObject>() -> CoreDataSource<T> {
        return CoreDataSource<T>(dataAccess: dataAccess)
    }

    /**
     Creates and returns a data source that will get notified when any objects of a given type are changed, inserted, or
     deleted so long as it matches the provided attributes. Can be grouped into sections by a `sectionProperty`, and
     limited by a `limit` parameter.

     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter sectionProperty: A keypath to a property to use when grouping together results, if desired.
     - parameter limit: An optional limit to be applied to the results.
     - returns: A data source that will get notified when any objects matching the attributes are changed, inserted, or
                deleted.
     */
    public func vendObjectsDataSource<T: DataObject>(attributes: DataContext.Attributes, sectionProperty: String?, limit: Int?) -> CoreDataSource<T> {
        return CoreDataSource<T>(dataAccess: dataAccess, attributes: attributes, sectionProperty: sectionProperty, limit: limit)
    }

    /**
     Creates and returns a data source that will get notified when any specific object of a given type is changed,
     inserted, or deleted.

     - parameter uniqueID: The unique identifier of the object to find and then listen for.
     - parameter context: The context on which to listen for object changes.
     - returns: A data source that will get notified when the matching object is changed, inserted, or deleted.
     */
    public func vendObjectDataSource<T: DataObject>(uniqueID: T.PrimaryKeyType, context: DataContext) -> CoreSingleDataSource<T> {
        return CoreSingleDataSource<T>(context: context, uniqueID: uniqueID, prefetch: [])
    }

    /**
     Creates and returns a data source that will get notified when any specific object of a given type is changed,
     inserted, or deleted.

     - parameter attributes: An optional dictionary of key-value query constraints to apply to the lookup.
     - parameter context: The context on which to listen for object changes.
     - returns: A data source that will get notified when the matching object is changed, inserted, or deleted.
     */
    public func vendObjectDataSource<T: DataObject>(attributes: DataContext.Attributes, context: DataContext) -> CoreSingleDataSource<T> {
        return CoreSingleDataSource<T>(context: context, attributes: attributes, prefetch: [])
    }
}
