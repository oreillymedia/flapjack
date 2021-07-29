//
//  Pancake.swift
//  FlapjackExample
//
//  Created by Ben Kreeger on 7/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData
import Flapjack

@objc(Pancake)
public class Pancake: NSManagedObject {
    @NSManaged public private(set) var identifier: String
    @NSManaged public var flavor: String?
    @NSManaged public var radius: Double
    @NSManaged public var height: Double
    @NSManaged public private(set) var toppings: [String]
    @NSManaged public private(set) var createdAt: Date

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(identifier))
        setPrimitiveValue(Date(), forKey: #keyPath(createdAt))
        setPrimitiveValue([String](), forKey: #keyPath(toppings))
    }

    func addTopping(_ topping: String) {
        var mToppings = toppings
        mToppings.append(topping)
        toppings = mToppings
    }
}


extension Pancake: DataObject {
    public typealias PrimaryKeyType = String
    public static var representedName: String { return "Pancake" }
    public static var primaryKeyPath: String { return #keyPath(identifier) }
    public static var defaultSorters: [Flapjack.SortDescriptor] {
        return [
            Flapjack.SortDescriptor(#keyPath(flavor), ascending: true, caseInsensitive: true),
            Flapjack.SortDescriptor(#keyPath(radius), ascending: false),
            Flapjack.SortDescriptor(#keyPath(height), ascending: false)
        ]
    }
}
