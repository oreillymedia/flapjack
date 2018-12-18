//
//  PrimaryKey.swift
//  Flapjack
//
//  Created by Ben Kreeger on 7/26/18.
//

import Foundation

/**
 A generic way to describe a `DataObject`'s primary key without tying it to a specific underlying type. An object's
 `PrimaryKey` field should uniquely identify an object in an entity table/group.
 */
public protocol PrimaryKey { }

extension String: PrimaryKey { }
extension Int16: PrimaryKey { }
extension Int32: PrimaryKey { }
extension Int64: PrimaryKey { }
extension UUID: PrimaryKey { }
extension URL: PrimaryKey { }
extension Data: PrimaryKey { }
