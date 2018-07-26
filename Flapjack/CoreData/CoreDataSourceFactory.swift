//
//  CoreDataSourceFactory.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation


// MARK: - CoreDataSourceFactory

public class CoreDataSourceFactory {
    private let dataAccess: DataAccess
    
    
    // MARK: Lifecycle
    
    public init(dataAccess: DataAccess) {
        self.dataAccess = dataAccess
    }
    
    
    // MARK: Public functions
    
    public func vendAllObjectsDataSource<T: DataObject>() -> CoreDataSource<T> {
        return CoreDataSource<T>(dataAccess: dataAccess)
    }
    
    public func vendObjectsDataSource<T: DataObject>(attributes: DataContext.Attributes, sectionProperty: String?, limit: Int?) -> CoreDataSource<T> {
        return CoreDataSource<T>(dataAccess: dataAccess, attributes: attributes, sectionProperty: sectionProperty, limit: limit)
    }
    
    public func vendObjectDataSource<T: DataObject>(uniqueID: T.PrimaryKeyType) -> CoreSingleDataSource<T> {
        return CoreSingleDataSource<T>(dataAccess: dataAccess, uniqueID: uniqueID, prefetch: [])
    }
    
    public func vendObjectDataSource<T: DataObject>(attributes: DataContext.Attributes) -> CoreSingleDataSource<T> {
        return CoreSingleDataSource<T>(dataAccess: dataAccess, attributes: attributes, prefetch: [])
    }
}
