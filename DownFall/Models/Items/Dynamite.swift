//
//  Dynamite.swift
//  DownFall
//
//  Created by William Katz on 12/19/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import Foundation

struct Dynamite: Ability {
    func animatedColumns() -> Int? {
        return nil
    }
    
    var affectsCombat: Bool {
        return false
    }
    
    var textureName: String {
        return "dynamite"
    }
    
    var cost: Int { return 58 }
    
    var currency: Currency { return .gold }
    
    var type: AbilityType { return .dynamite }
    
    var description: String {
        return "Destroys one of any kind of rock."
    }
    
    var flavorText: String {
        return "Boom boom boom boom, I want you to go boom."
    }
    
    var extraAttacksGranted: Int? {
        return nil
    }
    
    func blocksDamage(from: Direction) -> Int? {
        return nil
    }
    
    var usage: Usage {
        return .once
    }
    
    
    var targets: Int? { return 1 }
    var targetTypes: [TileType]? { return TileType.rockCases }
}

