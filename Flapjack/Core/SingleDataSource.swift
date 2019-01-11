//
//  SingleDataSource.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 A protocol describing a type that listens for changes in an underlying data set (powered by a `DataContext`) on a
 single object described by a set of `attributes`. Conforming declarations should invoke the `onChange` closure when the
 monitored object happens to change.
 */
public protocol SingleDataSource {
    /// A generic alias for the underlying type of model object matched and monitored by the data source.
    associatedtype ModelType: DataObject

    /// The criteria being used for finding the object being observed by this data source.
    var attributes: DataContext.Attributes { get }
    /// The object being observed by this data source, if found.
    var object: ModelType? { get }
    /// A closure to be called whenever a change is detected to the object being observed.
    var onChange: ((ModelType?) -> Void)? { get set }

    /// Tells the data source to perform its operation and retain the matching result.
    func execute()
}
