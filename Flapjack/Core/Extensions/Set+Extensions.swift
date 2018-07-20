//
//  Set+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/22/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public extension Set where Element: AnyObject {
    public func sortedArray(using descriptors: [SortDescriptor]) -> Array<Element> {
        return (self as NSSet).sortedArray(using: descriptors.asNSSortDescriptors) as? Array<Element> ?? []
    }
}
