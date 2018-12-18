//
//  DataObjectID.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 A generic way to describe a `DataObject`'s data store identifier (not to be confused with its `PrimaryKey` without
 tying it to a specific underlying database technology. An object's `DataObjectID` should generally uniquely identify an
 object across multiple data stores.
 */
public protocol DataObjectID { }
