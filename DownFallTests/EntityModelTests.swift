//
//  EntityModelTests.swift
//  DownFallTests
//
//  Created by William Katz on 5/18/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

@testable import DownFall

import XCTest


class EntityModelTests: XCTestCase {
    
    func testEntityModelParsingFromData() {
        guard let data = try! Data.data(from: "EntityTest") else {
            XCTFail("Failed to json file");
            return
        }
        do {
            let entity = try JSONDecoder().decode(EntitiesModel.self, from: data).entities.first!
            XCTAssertEqual(entity.hp, 1)
            XCTAssertEqual(entity.name, "Gloop")
            
            let expectedRangeModel = RangeModel(lower: 1, upper: 1)
            let expectedAnimationPaths = "Animations/gloop.png"
            let expectedAttackModel = AttackModel(frequency: 0,
                                                  range: expectedRangeModel,
                                                  damage: 1,
                                                  directions: [.east, .west],
                                                  animationPaths: [expectedAnimationPaths],
                                                  hasAttacked: false)
            XCTAssertEqual(entity.attack.frequency, expectedAttackModel.frequency)
            XCTAssertEqual(entity.attack.range, expectedAttackModel.range)
            XCTAssertEqual(entity.attack.directions, expectedAttackModel.directions)
            XCTAssertEqual(entity.attack.animationPaths, expectedAttackModel.animationPaths)
        }
        catch {
            XCTFail("Failed JSON decode the Entity Model because \(error)")
        }
    }
    
    func json(from fileName: String) throws -> [String: Any]? {
        if let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] else {
                    return nil
                }
                return jsonResult
            } catch {
                // handle error
                XCTFail("\(error)")
            }
        }
        return nil
    }
}

