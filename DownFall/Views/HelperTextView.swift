//
//  HelperTextView.swift
//  DownFall
//
//  Created by William Katz on 4/2/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import SpriteKit

class HelperTextView: SKSpriteNode {
    static func build(color: UIColor, size: CGSize) -> HelperTextView {
        let header = HelperTextView(texture: nil, color: color, size: size)
        Dispatch.shared.register { input in
            header.show(input)
        }
        return header
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(_ input: Input) {
        var descriptionText = ""
        switch input.type {
        case .gameLose(let text):
            descriptionText = text
        case .gameWin:
            descriptionText = "You won, you are a masterful miner!\n Make sure to leave feedback :)"
        case .transformation(let trans):
            guard let inputType = trans.first?.inputType else { return }
            switch inputType {
            case .attack(_, let attackerPosition, let defenderPosition, _, _):
                if let tiles = trans.first?.endTiles {
                    if let defenderPosition = defenderPosition {
                        let attacker = tiles[attackerPosition]
                        let defender = tiles[defenderPosition]
                        
                        if case let TileType.monster(monsterData) = attacker.type,
                            case TileType.player = defender.type {
                            // monster attacked player
                            
                            descriptionText = "You've been attacked by a\n monster for \(monsterData.attack.damage) damage."
                        } else if case TileType.monster = defender.type,
                            case TileType.player = attacker.type {
                            // we attacked the monster
                            descriptionText = "You slayed a monster,\n you're a worthy champion indeed!"
                        }
                    }
                }
            default:
                descriptionText = ""
            }
        case .touch(_, let type):
            switch type {
            case .rock:
                descriptionText = "Remove rocks by tapping on groups\n of 3 or more anywhere on the board."
            case .exit:
                descriptionText = "That's the mine shaft,\n but you cant exit until you find the gem!"
            case .player:
                descriptionText = "That's you! Stay alive and find the exit"
            case .monster(let data):
                descriptionText = "\(data)"
            case .empty:
                descriptionText = "How in the hell did you tap on an empty tile? BECAUSE WE ADDED Pillars, BOOOM"
            case .item(let item):
                descriptionText = "That's \(item.textureName), cool!"
            case .dynamite:
                descriptionText = "Dynamite!"
            case .pillar:
                descriptionText = ""
            }
        case .boardBuilt, .pause:
            ()
        case .rotateCounterClockwise, .rotateClockwise:
            descriptionText = "Try swiping up or down on the\n right side of the screen!!"
        default:
            descriptionText = ""
        }

        if descriptionText.count == 0 { return }
        self.removeAllChildren()
        
        let descLabel = SKLabelNode(text: descriptionText)
        descLabel.fontSize = UIFont.mediumSize
        descLabel.zPosition = 11
        descLabel.fontColor = .lightText
        descLabel.fontName = "Helvetica"
        descLabel.position = CGPoint(x: 0, y: -45)
        descLabel.numberOfLines = 0
    }
    
    var paragraphWidth: CGFloat {
        return frame.width - Style.Padding.more
    }
}
