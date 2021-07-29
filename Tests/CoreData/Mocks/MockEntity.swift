//
//  MockEntity+CoreDataClass.swift
//  Flapjack-Unit-CoreData-Tests
//
//  Created by Ben Kreeger on 11/1/18.
//
//

import Foundation
import CoreData

@testable import Flapjack
@testable import FlapjackCoreData

@objc(MockEntity)
public class MockEntity: NSManagedObject {
    @NSManaged public var someProperty: String?
    @NSManaged public var identifier: String
    @NSManaged public var someTransientProperty: Date?

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(identifier))
    }
}


extension MockEntity: DataObject {
    public typealias PrimaryKeyType = String

    public static var representedName: String {
        return "MockEntity"
    }

    public static var primaryKeyPath: String {
        return #keyPath(MockEntity.identifier)
    }

    public static var defaultSorters: [Flapjack.SortDescriptor] {
        return [SortDescriptor(#keyPath(MockEntity.identifier))]
    }
}
