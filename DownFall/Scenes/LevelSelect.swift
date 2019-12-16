//
//  LevelSelect.swift
//  DownFall
//
//  Created by William Katz on 6/30/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import SpriteKit

protocol LevelSelectDelegate: class {
    func didSelect(_ difficulty: Difficulty, _ playerModel: EntityModel?)
}

class LevelSelect: SKScene {
    private var background: SKSpriteNode!
    private var easy: SKLabelNode!
    private var normal: SKLabelNode!
    private var hard: SKLabelNode!
    weak var levelSelectDelegate: LevelSelectDelegate?
    var playerModel: EntityModel?
    
    override func didMove(to view: SKView) {
        background = self.childNode(withName: "background") as? SKSpriteNode
        background.color = UIColor.clayRed
        
        easy = self.childNode(withName: "easy") as? SKLabelNode
        normal = self.childNode(withName: "normal") as? SKLabelNode
        hard = self.childNode(withName: "hard") as? SKLabelNode
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let positionInScene = touch.location(in: self.background)
        if easy.contains(positionInScene) {
            levelSelectDelegate?.didSelect(.normal, playerModel)
        } else if normal.contains(positionInScene) {
            levelSelectDelegate?.didSelect(.tutorial1, playerModel)
        } else if hard.contains(positionInScene) {
            levelSelectDelegate?.didSelect(.tutorial2, playerModel)
        }
    }
    
    
}
