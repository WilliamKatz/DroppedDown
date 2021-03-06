//
//  GameViewController.swift
//  DownFall
//
//  Created by William Katz on 5/9/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    private var gameSceneNode: GameScene?
    private var boardSize = 7
    private var entities: [EntityModel]?
    private var selectedDifficulty: Difficulty = .normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO: handle failure more gracefully. ie redownload or retry
        let entityData = try! Data.data(from: "entities")!
        entities = try! JSONDecoder().decode(EntitiesModel.self, from: entityData).entities
        levelSelect()
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait]
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension GameViewController {
    private func levelSelect() {
        if let levelSelectScene = GKScene(fileNamed: "LevelSelect")?.rootNode as? LevelSelect {
            levelSelectScene.scaleMode = .aspectFill
            levelSelectScene.levelSelectDelegate = self
            
            if let view = self.view as! SKView? {
                view.presentScene(levelSelectScene)
                view.ignoresSiblingOrder = true
            }
            
        }
    }
    
    private func startLevel() {
        gameSceneNode = nil
        if let scene = GKScene(fileNamed: "GameScene")?.rootNode as? GameScene,
            let entities = entities {
            gameSceneNode = scene
            gameSceneNode!.scaleMode = .aspectFill
            gameSceneNode!.gameSceneDelegate = self
            gameSceneNode!.commonInit(boardSize: boardSize,
                                      entities: entities,
                                      difficulty: selectedDifficulty)
            
            if let view = self.view as! SKView? {
                view.presentScene(gameSceneNode)
                view.ignoresSiblingOrder = true
                
                //Debug settings
                //TODO: remove for release
                view.showsFPS = true
                view.showsNodeCount = true
                
            }
        }
    }
}

extension GameViewController: LevelSelectDelegate {
    func didSelect(_ difficulty: Difficulty) {
        if let view = self.view as! SKView? {
            view.presentScene(nil)
            selectedDifficulty = difficulty
            startLevel()
        }
    }
}


extension GameViewController: GameSceneDelegate {
    func selectLevel() {
        if let view = self.view as! SKView? {
            view.presentScene(nil)
            levelSelect()
        }

    }
    
    func reset() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.75)
        let remove = SKAction.removeFromParent()
        gameSceneNode?.run(SKAction.group([fadeOut, remove])) { [weak self] in
            self?.startLevel()
        }
    }
}
