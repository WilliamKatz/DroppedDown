//
//  Controls.swift
//  DownFall
//
//  Created by William Katz on 3/3/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import SpriteKit

class Controls: SKSpriteNode {
    
    struct Constants {
        static let rotateRight = "rotateRight"
        static let rotateLeft = "rotateLeft"
    }
    
    static func build(color: UIColor,
                      size: CGSize,
                      precedence: Precedence) -> Controls {
        let controls = Controls(texture: SKTexture(imageNamed: "header"), color: color, size: size)
        let rotateRight = SKSpriteNode(imageNamed: "rotateRight")
        rotateRight.scale(to: CGSize(width: 200.0, height: 200.0))
        rotateRight.zPosition = precedence.rawValue
        let rotateRightX = controls.frame.maxX - rotateRight.frame.width/2
        rotateRight.position = CGPoint(x: rotateRightX, y: size.height/2 - rotateRight.frame.height/2)
        rotateRight.name = Constants.rotateRight
        
        let rotateLeft = SKSpriteNode(imageNamed: "rotateLeft")
        rotateLeft.scale(to: CGSize(width: 200.0, height: 200.0))
        rotateLeft.zPosition = precedence.rawValue
        let rotateLeftX = controls.frame.minX + rotateLeft.frame.width/2
        rotateLeft.position = CGPoint(x: rotateLeftX, y: size.height/2 - rotateLeft.frame.height/2)
        rotateLeft.name = Constants.rotateLeft
    
        controls.isUserInteractionEnabled = true
        controls.addChild(rotateLeft)
        controls.addChild(rotateRight)
        
        return controls
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let positionInScene = touch.location(in: self)
        let nodes = self.nodes(at: positionInScene)
        
        
        for node in nodes {
            if node.name == Constants.rotateLeft {
                InputQueue.append(Input(.rotateLeft))
            }
            if node.name == Constants.rotateRight {
                InputQueue.append(Input(.rotateRight))
            }
        }
        
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        isUserInteractionEnabled = true
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
