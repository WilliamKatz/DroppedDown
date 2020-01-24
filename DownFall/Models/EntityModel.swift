//
//  Monster.swift
//  DownFall
//
//  Created by William Katz on 5/18/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import Foundation

protocol ResetsAttacks {
    func resetAttacks() -> EntityModel
}

struct EntityModel: Equatable, Decodable {
        
    enum EntityType: String, Decodable, CaseIterable {
        case bat
        case rat
        case dragon
        case alamo
        case wizard
        case lavaHorse
        case player
        case easyPlayer
        case normalPlayer
        case hardPlayer
    }
    
    static let playerCases: [EntityType] = [.easyPlayer, .normalPlayer, .hardPlayer]
    
    static let zero: EntityModel = EntityModel(originalHp: 0, hp: 0, name: "null", attack: .zero, type: .rat, carry: .zero, animations: .zero, abilities: [])
    
    let originalHp: Int
    let hp: Int
    let name: String
    let attack: AttackModel
    let type: EntityType
    let carry: CarryModel
    let animations: AllAnimationsModel
    var abilities: [AnyAbility] = []
    
    private enum CodingKeys: String, CodingKey {
        case originalHp
        case hp
        case name
        case attack
        case type
        case carry
        case animations
    }
    
    private func update(originalHp: Int? = nil,
                        hp: Int? = nil,
                        name: String? = nil,
                        attack: AttackModel? = nil,
                        type: EntityType? = nil,
                        carry: CarryModel? = nil,
                        animations: AllAnimationsModel? = nil,
                        abilities: [AnyAbility]? = nil) -> EntityModel {
        let updatedOriginalHp = originalHp ?? self.originalHp
        let updatedHp = hp ?? self.hp
        let updatedName = name ?? self.name
        let updatedAttack = attack ?? self.attack
        let updatedType = type ?? self.type
        let updatedCarry = carry ?? self.carry
        let updatedAnimations = animations ?? self.animations
        let updatedAbilities = abilities ?? self.abilities
        
        return EntityModel(originalHp: updatedOriginalHp,
                           hp: updatedHp,
                           name: updatedName,
                           attack: updatedAttack,
                           type: updatedType,
                           carry: updatedCarry,
                           animations: updatedAnimations,
                           abilities: updatedAbilities)
        
        
        
    }
    
    var canAttack: Bool {
        var bonusAttacks = 0
        for ability in abilities {
            if let attacks = ability.extraAttacksGranted  {
                bonusAttacks += attacks
            }
        }
        return attack.attacksPerTurn + bonusAttacks - attack.attacksThisTurn > 0
    }
    
    /**
     Add an ability to entities model.  If the model already contains that ability, then just increment the count
     
     - Returns: an updated entity model
     
     */
    func add(_ ability: Ability) -> EntityModel {
        var newAbilities = abilities
        if let index = newAbilities.firstIndex(of: AnyAbility(ability)) {
            var updatedAbility = newAbilities[index]
            updatedAbility.count += 1
            newAbilities[index] = updatedAbility
        } else {
            let anyAbility = AnyAbility(ability)
            newAbilities.append(anyAbility)
        }
        
        return self.update(abilities: newAbilities)

    }
    
    func remove(_ ability: Ability) -> EntityModel {
        var newAbilities = abilities
        newAbilities.removeAll(where: { $0.type == ability.type })
        return self.update(abilities: newAbilities)
    }
    
    func revive() -> EntityModel {
        return self.update(hp: originalHp)
    }
    
    func didAttack() -> EntityModel {
        return update(attack: attack.didAttack())
    }
    
    func wasAttacked(for damage: Int, from direction: Direction) -> EntityModel {
        var shieldedDamage = 0
        for ability in abilities {
            if let blockedDamage = ability.blocksDamage(from: direction) {
                shieldedDamage = blockedDamage
            }
        }
        
        let finalDamage = damage - shieldedDamage
        return update(hp: hp - finalDamage)
    }
    
    func buy(_ ability: Ability) -> EntityModel {
        return update(carry: carry.pay(ability.cost, inCurrency: ability.currency))
    }
    
    func sell(_ ability: Ability) -> EntityModel {
        return update(carry: carry.earn(ability.cost, inCurrency: ability.currency))
    }
    
    func canAfford(_ cost: Int, inCurrency currency: Currency) -> Bool {
        let totalAmount = carry.total(in: currency)
        return totalAmount >= cost
    }
    
    func willAttackNextTurn() -> Bool {
        return attack.willAttackNextTurn()
    }
    
    func heal(for amount: Int) -> EntityModel {
        return update(hp: min(originalHp, self.hp + amount))
    }
    
    func use(_ ability: Ability) -> EntityModel {
        var newAbilities = self.abilities
        newAbilities.removeFirst( where: { $0 == AnyAbility(ability) })
        return update(abilities: newAbilities)
    }

}

extension EntityModel: ResetsAttacks {
    func resetAttacks() -> EntityModel {
        return update(attack: attack.resetAttack())
    }
}

extension EntityModel {
    func incrementsAttackTurns() -> EntityModel {
        return update(attack: attack.incrementTurns())
    }
}

extension EntityModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(hp)
        hasher.combine(name)
    }
}

struct EntitiesModel: Equatable, Decodable {
    let entities: [EntityModel]
    
    func entity(with type: EntityModel.EntityType) -> EntityModel? {
        return entities.first(where: { $0.type == type})
    }
    
    var easyPlayer: EntityModel? {
        return entity(with: .easyPlayer)
    }
    
    var normalPlayer: EntityModel? {
        return entity(with: .normalPlayer)
    }
    
    var hardPlayer: EntityModel? {
        return entity(with: .hardPlayer)
    }
}


extension EntityModel: CustomDebugStringConvertible {
    var debugDescription: String {
        return "That is a \(self.type), it has \(self.hp)\n \(self.attack)"
    }
}

extension AttackModel: CustomDebugStringConvertible {
    var debugDescription: String {
        return "Attacks \(String(describing: self.attackSlope)) for \(self.damage)"
    }
}

