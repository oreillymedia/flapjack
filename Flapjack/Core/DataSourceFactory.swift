//
//  DataSourceFactory.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public protocol DataSourceFactory {
    func vendAllObjectsDataSource<T: DataObject>() -> CoreDataSource<T>
    func vendObjectsDataSource<T: DataObject>(attributes: DataContext.Attributes, sectionProperty: String?, limit: Int?) -> CoreDataSource<T>
    func vendObjectDataSource<T: DataObject>(uniqueID: DataContext.PrimaryKey) -> CoreSingleDataSource<T>
    func vendObjectDataSource<T: DataObject>(attributes: DataContext.Attributes) -> CoreSingleDataSource<T>
}
