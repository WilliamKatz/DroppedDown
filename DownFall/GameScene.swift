//
//  GameScene.swift
//  DownFall
//
//  Created by William Katz on 5/9/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

import SpriteKit


enum BoardChange {
    case findNeighbors(Int, Int)
    case shiftReplace
}

protocol SpriteMediator {
    func sprites() -> [[DFTileSpriteNode]]
    func boardChanged(_ reason : BoardChange)
    func getBoard() -> Board
}

class GameScene: SKScene, SceneBuilder, SpriteMediator {
    
    let boardSize = 9
    
    internal var mediator: SpriteMediator?
    internal var foreground : SKNode!
    internal var board : Board
    
    //buttons
    var left : SKNode!
    var right: SKNode!

    
    override func didMove(to view: SKView) {
        foreground = self.childNode(withName: "foreground")!
        left = self.childNode(withName: "left")!
        right = self.childNode(withName: "right")!
        addTileNodes(board.spriteNodes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.board = Board.build(size: boardSize)
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit(){
        NotificationCenter.default.addObserver(self, selector: #selector(newTiles), name: .newTiles, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(removeTiles), name: .removeTiles, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shiftReplace), name: .shiftReplace, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shiftDown), name: .shiftDown, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(neighborsFound), name: .neighborsFound, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: .rotated, object: nil)
        mediator = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension GameScene {
    func registerTouch(_ touch: UITouch) {
        let touchPoint = touch.location(in: self)
        for col in 0..<board.spriteNodes.count {
            for row in 0..<board.spriteNodes[col].count {
                if board.spriteNodes[col][row].contains(touchPoint) {
                    if board.selectedTiles.contains(where: { (locale) -> Bool in
                        return (col, row) == locale
                    }) {
                        boardChanged(BoardChange.shiftReplace)
                    } else {
                        boardChanged(BoardChange.findNeighbors(col, row))
                    }
                }
            }
        }
        if left.contains(touchPoint) {
            board.rotate(.left)
        }
        
        if right.contains(touchPoint) {
            board.rotate(.right)
        }
    }
}

// MARK: SpriteMediator
extension GameScene {
    
    func sprites() -> [[DFTileSpriteNode]] {
        return board.spriteNodes
    }
    
    func boardChanged(_ reason: BoardChange) {
        switch reason {
        case .findNeighbors(let x, let y):
            board.removeActions()
            board.findNeighbors(x, y)
        case .shiftReplace:
            board.shiftReplaceTiles()
        }
    }
    
    func getBoard() -> Board {
        return self.board
    }
    
}
// MARK: Board notifications


extension GameScene {
    @objc func removeTiles(notification: NSNotification) {
        //show that tiles have been remove before shifting
        //this could be a good time to animate the rock destruction
        foreground.removeAllChildren()
        addTileNodes(board.spriteNodes)
        board.shiftDown()
    }
    
    @objc func shiftDown(notification: NSNotification) {
        //animate the shifting of tiles that were previously on the board
        //that are now above empty spaces
        //does that mean board is responsible for animation?
        guard let transformation = notification.userInfo?["transformation"] as? [Transformation] else { fatalError() }
        
        for trans in transformation {
            let tileSize = board.tileSize
            let point = CGPoint.init(x: tileSize*trans.initial.1+board.bottomLeft.1, y: tileSize*trans.initial.0+board.bottomLeft.1)
            for child in foreground.children {
                if child.contains(point) {
                    let endPoint = CGPoint.init(x: tileSize*trans.end.1+board.bottomLeft.1, y: tileSize*trans.end.0+board.bottomLeft.0)
                    let animation = SKAction.move(to: endPoint, duration: 0.2)
                    child.run(animation)
                }
            }
        }
        board.fillEmpty()
    }
    
    @objc func newTiles(notification: NSNotification) {
        guard let newTiles = notification.userInfo?["newTiles"] as? [(Int, Int)] else { fatalError("No new DFTileSpriteNode information") }
        
        for (row, col) in newTiles {
            let sprite = board.spriteNodes[row][col]
            //animate
            let x = board.tileSize * boardSize + ( row * board.tileSize ) + board.bottomLeft.0
            let y = board.tileSize * col + board.bottomLeft.1
            sprite.position = CGPoint.init(x: y, y: x)
            sprite.removeFromParent()
            foreground.addChild(sprite)
            let targetPosition = CGPoint.init(x: board.tileSize*col+board.bottomLeft.0, y: board.tileSize*row+board.bottomLeft.1)
            let moveTo = SKAction.move(to: targetPosition, duration: 0.2)
            sprite.run(moveTo)
            
        }
        
    }
    
    @objc func shiftReplace(notification: NSNotification) {
        //update scene
        foreground.removeAllChildren()
        addTileNodes(board.spriteNodes)
        
    }
    
    @objc func neighborsFound(notification: NSNotification) {
        //update Sprites
        board.removeActions()
        guard let tiles = notification.userInfo?["tiles"] as? [(Int, Int)] else { fatalError("No tiles in notification") }
        board.blinkTiles(at: tiles)
        //update Scene
    }
    
    @objc func rotated(notification: NSNotification) {
        guard let transformation = notification.userInfo?["transformation"] as? [Transformation] else { fatalError("No transformations provided for rotate") }
        
        for trans in transformation {
            let tileSize = board.tileSize
            let point = CGPoint.init(x: tileSize*trans.initial.1+board.bottomLeft.1, y: tileSize*trans.initial.0+board.bottomLeft.1)
            for child in foreground.children {
                if child.contains(point) {
                    let endPoint = CGPoint.init(x: tileSize*trans.end.1+board.bottomLeft.1, y: tileSize*trans.end.0+board.bottomLeft.0)
                    let animation = SKAction.move(to: endPoint, duration: 0.4)
                    child.run(animation)
                }
            }

        }
    }
}

// MARK: Touch Relay


extension GameScene {
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        registerTouch(touch)
    }
}
