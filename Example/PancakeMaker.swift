//
//  PancakeMaker.swift
//  FlapjackExample
//
//  Created by Ben Kreeger on 7/26/18.
//  Copyright (c) 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import Flapjack

class PancakeMaker {
    private let dataAccess: DataAccess

    init(dataAccess: DataAccess) {
        self.dataAccess = dataAccess
    }


    // MARK: Public functions

    func makePancake(_ completion: @escaping (Pancake?, Error?) -> Void) {
        let flavors = ["Raspberry", "Blueberry", "Chocolate Chip", "Banana", "Cheesecake", "Mango", "Rhubarb"]
        let flavor = flavors[Int(arc4random_uniform(UInt32(flavors.count)))]
        let radius = Double(arc4random_uniform(10))
        let height = Double(arc4random_uniform(10))

        dataAccess.performInBackground { [weak self] context in
            let pancake = context.create(Pancake.self, attributes: ["flavor": flavor, "radius": radius, "height": height])
            let error = context.persist()

            DispatchQueue.main.async {
                guard let `self` = self else {
                    return
                }
                let foregroundPancake = self.dataAccess.mainContext.object(ofType: Pancake.self, objectID: pancake.objectID)
                completion(foregroundPancake, error)
            }
        }
    }
}
