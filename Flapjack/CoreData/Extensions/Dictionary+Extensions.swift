//
//  Dictionary+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

internal extension Dictionary where Key == String, Value == Any {
    var cacheKey: String {
        return self.keys.sorted().compactMap { key in
            guard let value = self[key] else {
                return nil
            }
            return "\(key).\(String(describing: value))"
        }.joined(separator: "-")
    }
}
