//
//  NSCompoundPredicate+Extensions.swift
//  Flapjack
//
//  Created by Ben Kreeger on 3/3/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public extension NSPredicate {
    class func fromConditions(_ dictionary: [String: Any?]) -> [NSPredicate] {
        return dictionary.compactMap { NSPredicate(key: $0, value: $1) }
    }

    convenience init(key: String, value: Any?) {
        let keyPath = key.hasPrefix("self") ? key : "%K"
        var args: [Any] = key.hasPrefix("self") ? [] : [key]

        guard let value = value else {
            self.init(format: "\(keyPath) == nil", argumentArray: args)
            return
        }

        args.append(value)

        switch value {
        case is [Any], is [AnyHashable], is Set<AnyHashable>:
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
    convenience init(andPredicateFrom dictionary: [String: Any?]) {
        self.init(andPredicateWithSubpredicates: NSPredicate.fromConditions(dictionary))
    }

    convenience init(orPredicateFrom dictionary: [String: Any?]) {
        self.init(orPredicateWithSubpredicates: NSPredicate.fromConditions(dictionary))
    }
}
