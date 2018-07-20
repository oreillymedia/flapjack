//
//  NSCompoundPredicate+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 3/3/17.
//  Copyright © 2017 Safari Books Online. All rights reserved.
//

import Foundation

public extension NSPredicate {
    public class func fromConditions(_ dictionary: [String:Any]) -> [NSPredicate] {
        return dictionary.compactMap { NSPredicate(key: $0, value: $1) }
    }

    public convenience init(key: String, value: Any) {
        let keyPath = key.hasPrefix("self") ? key : "%K"
        var args: [Any] = key.hasPrefix("self") ? [value] : [key, value]
        
        switch value {
        case is Array<Any>, is Set<AnyHashable>:
            self.init(format: "(\(keyPath) IN %@)", argumentArray: args)
        case let range as Range<Date>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) < %@", argumentArray: args)
        case let range as Range<Int>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) < %@", argumentArray: args)
        case let range as Range<Float>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) < %@", argumentArray: args)
        case let range as Range<Double>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) < %@", argumentArray: args)
        case let range as ClosedRange<Date>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) <= %@", argumentArray: args)
        case let range as ClosedRange<Int>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) <= %@", argumentArray: args)
        case let range as ClosedRange<Float>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) <= %@", argumentArray: args)
        case let range as ClosedRange<Double>:
            args = key.hasPrefix("self") ? [range.lowerBound, range.upperBound] : [key, range.lowerBound, key, range.upperBound]
            self.init(format: "\(keyPath) >= %@ AND \(keyPath) <= %@", argumentArray: args)
        case is CVarArg:
            self.init(format: "\(keyPath) == %@", argumentArray: args)
        default:
            print("Couldn't make a predicate out of value \(value)")
            self.init()
        }
    }
}

public extension NSCompoundPredicate {
    public convenience init(andPredicateFrom dictionary: [String:Any]) {
        self.init(andPredicateWithSubpredicates: NSPredicate.fromConditions(dictionary))
    }

    public convenience init(orPredicateFrom dictionary: [String:Any]) {
        self.init(orPredicateWithSubpredicates: NSPredicate.fromConditions(dictionary))
    }
}
