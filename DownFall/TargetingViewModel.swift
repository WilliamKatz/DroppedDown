//
//  TargetingViewModel.swift
//  DownFall
//
//  Created by Katz, Billy on 1/22/20.
//  Copyright © 2020 William Katz LLC. All rights reserved.
//

import Foundation

struct Target {
    let coord: TileCoord
    let isLegal: Bool
}

protocol TargetingOutputs {
    var toastMessage: String { get }
    var currentTargets: [Target] { get }
    var legallyTargeted: Bool { get }
    
}

protocol TargetingInputs {
    
    /// Use this to choose targets
    func didTarget(_ coord: TileCoord)
    
    /// Use this to consume the item
    func didUse(_ ability: AnyAbility?)
    
    /// Use this to select an ability
    func didSelect(_ ability: AnyAbility?)
}

protocol Targeting: TargetingOutputs, TargetingInputs {}

class TargetingViewModel: Targeting {
    
    public var updateCallback: (() -> Void)?
    
    var ability: AnyAbility? {
        didSet {
            if let ability = ability {
                InputQueue.append(Input(InputType.itemUseSelected(ability)))
            }
            else {
                InputQueue.append(Input(InputType.itemUseCanceled))
            }
            currentTargets = []
            autoTarget()
        }
    }
    
    var numberOfTargets: Int {
        return ability?.targets ?? 0
    }
    
    var typesOfTargets: [TileType] {
        return ability?.targetTypes ?? []
    }
    
    var toastMessage: String {
        if ability == nil {
            return ""
        }
        let baseString = "Choose "
        
        //remove duplicates of human readable strings
        let typesOfTargetString = typesOfTargets.reduce([]) { (result, tileType) -> [String] in
            var newResult = result
            if !result.contains(tileType.humanReadable) {
                newResult.append(tileType.humanReadable)
            }
            return newResult
        }
        
        // build the string of the types
        let types: String
        if typesOfTargetString.count == 0 {
            types = ""
        }
        else if typesOfTargetString.count == 1 {
            types = typesOfTargetString.first ?? ""
        } else if typesOfTargetString.count == 2 {
            types = "\(typesOfTargetString.first ?? "") and/or \(typesOfTargetString.last ?? "")"
        } else {
            var allButLastString = typesOfTargetString.dropLast().joined(separator: ", ")
            
            allButLastString.append(" and/or \(typesOfTargetString.last ?? "")")
            types = allButLastString
        }
        return baseString + "\(self.numberOfTargets) " + types + "\(self.numberOfTargets > 1 ? "s" : "")"
    }
    
    var currentTargets: [Target] = [] {
        didSet {
            updateCallback?()
            InputQueue.append(Input(InputType.itemCanBeUsed(legallyTargeted)))
        }
    }
    
    
    var legallyTargeted: Bool {
        return self.currentTargets.allSatisfy({
            return $0.isLegal
        }) && self.currentTargets.count == self.numberOfTargets
    }
    
    
    private var tiles: [[Tile]]? = nil {
        didSet {
            autoTarget()
            updateCallback?()
        }
    }
    
    init() {
        Dispatch.shared.register { [weak self] (input) in
            switch input.type {
            case .transformation(let trans):
                if let inputType = trans.inputType,
                    case InputType.itemUseSelected(_) = inputType,
                    let endTiles = trans.endTiles
                {
                    self?.tiles = endTiles
                }
                
            case .itemUseCanceled:
                ()
            default:
                ()
            }
        }
    }
    
    private func isTargetLegal(_ coord: TileCoord) -> Bool {
        guard let tiles = tiles else { return false }
        if typesOfTargets.contains(tiles[coord].type) {
            return true
        }
        return false
    }
    
    /**
     Toggles targeted-ness of a tile.  If a tile is not targeted it becomes targeted.  The opposite is true.
     
     - Note: If the max number of targets for an ability is reached and a unique coord is passed in. The most recently placed target is un-targeted. And the passed in coord becomes targeted.
     - Parameters coord: The coord that is being targetted
     - Returns: Nothing
     */
    func didTarget(_ coord: TileCoord) {
        guard ability != nil else { preconditionFailure("We should be able to target if we dont have an ability selected") }
        if currentTargets.contains(where: { return $0.coord == coord } ) {
            //remove the new target
            currentTargets.removeAll(where: { return $0.coord == coord })
        } else if currentTargets.count < self.numberOfTargets {
            //add the new target
            currentTargets.append(Target(coord: coord, isLegal: isTargetLegal(coord)))
        } else {
            // move the most recently placed unless there is one that is "illegal" then move that one.
            let count = currentTargets.count
            currentTargets.removeFirst(where: { !$0.isLegal })
            if currentTargets.count == count {
                currentTargets.removeLast()
            }
            //add the new target
            currentTargets.append(Target(coord: coord, isLegal: isTargetLegal(coord)))
        }
    }
    
    func didUse(_ ability: AnyAbility?) {
        guard let ability = ability else { return }
        guard legallyTargeted else { return }
        InputQueue.append(
            Input(.itemUsed(ability, currentTargets.map { $0.coord }))
        )
        self.ability = nil
        
    }
    
    func didSelect(_ ability: AnyAbility?) {
        self.ability = ability
    }
    
    private func autoTarget() {
        guard let tiles = tiles else { return }
        var targetCoords: [TileCoord] = []
        for type in typesOfTargets {
            targetCoords.append(contentsOf: typeCount(for: tiles, of: type))
        }
        if targetCoords.count <= numberOfTargets {
            // targets are necessarily legal because we looped over types of targets
            currentTargets = targetCoords.map { Target(coord: $0, isLegal: true) }
        }
    }
}

extension Array {
    mutating func removeFirst(where predicate: (Element) -> Bool) {
        var indexToRemove: Int?
        for (index, el) in self.enumerated() {
            if predicate(el) {
                indexToRemove = index
                break
            }
        }
        if indexToRemove != nil {
            self.remove(at: indexToRemove!)
        }
    }
}
