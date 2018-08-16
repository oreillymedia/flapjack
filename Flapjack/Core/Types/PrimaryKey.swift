//
//  PrimaryKey.swift
//  Flapjack
//
//  Created by Ben Kreeger on 7/26/18.
//

import Foundation

public protocol PrimaryKey { }

extension String: PrimaryKey { }
extension Int16: PrimaryKey { }
extension Int32: PrimaryKey { }
extension Int64: PrimaryKey { }
extension UUID: PrimaryKey { }
extension URL: PrimaryKey { }
extension Data: PrimaryKey { }
