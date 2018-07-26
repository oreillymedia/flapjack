//
//  DataSource.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public typealias OnChangeClosure = (Set<DataSourceChange>, Set<DataSourceSectionChange>) -> Void

public protocol DataSource {
    associatedtype T: DataObject & Hashable
    
    var numberOfObjects: Int { get }
    var allObjects: [T] { get }
    var numberOfSections: Int { get }
    var sectionNames: [String] { get }
    var sectionIndexTitles: [String] { get }
    var onChange: OnChangeClosure? { get set }
    
    func execute()
    func numberOfObjects(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> T?
    func indexPath(for object: T?) -> IndexPath?
    func firstObject(_ matching: (T) -> Bool) -> T?
    func objectsWhere(_ matching: (T) -> Bool) -> [T]
    
    subscript(uniqueId: T.PrimaryKeyType) -> T? { get }
}
