//
//  Set+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/22/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public extension Set where Element: AnyObject {
    /**
     Returns a copy of this Set asn an Array sorted using `SortDescriptor` objects.

     - parameter descriptors: The `SortDescriptor` objects to use; these will be transformed into `NSSortDescriptor`
                              versions and run against the set as an `NSSet`.
     - returns: A new sorted array.
     */
    func sortedArray(using descriptors: [SortDescriptor]) -> [Element] {
        return (self as NSSet).sortedArray(using: descriptors.asNSSortDescriptors) as? [Element] ?? []
    }
}
