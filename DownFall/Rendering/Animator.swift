//
//  Animator.swift
//  DownFall
//
//  Created by William Katz on 9/15/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import Foundation
import SpriteKit


struct Animator {
    
    public func smokeAnimation() -> SKAction {
        let smokeTexture = SpriteSheet(texture: SKTexture(imageNamed: "smokeAnimation"), rows: 1, columns: 6).animationFrames()
        let smokeAnimation = SKAction.animate(with: smokeTexture, timePerFrame: 0.07)
        return smokeAnimation
    }
    
    public func explodeAnimation() -> SKAction {
        let explodeTexture = SpriteSheet(texture: SKTexture(imageNamed: "explodeAnimation"), rows: 1, columns: 4).animationFrames()
        let explodeAnimation = SKAction.animate(with: explodeTexture, timePerFrame: 0.07)
        return explodeAnimation
    }
    
    func timePerFrame() -> Double {
        return 0.07
    }
    
    func projectileTimePerFrame(for monsterType: EntityModel.EntityType) -> Double {
        switch monsterType {
        case .alamo:
            return 0.03
        case .dragon:
            return 0.1
        default:
            return 0.07
        }
    }
    
    func projectileKeyFrame(for entity: EntityModel, index: Int) -> Double {
        switch entity.type {
        case .dragon:
            var duration: Double = 0
            if index >= 0 {
                if let keyframes = entity.keyframe(of: .attack) {
                    duration += Double(keyframes)
                }
            }
            if index >= 1 {
                if let keyframes = entity.keyframe(of: .projectileStart) {
                    duration += Double(keyframes)
                }
            }
            if index >= 2 {
                if let midKeyFrame = entity.keyframe(of: .projectileMid) {
                    duration += Double(midKeyFrame*index)
                }
            }
            return duration
        case .alamo:
            var duration: Double = 0
            if index >= 0, let keyframes = entity.keyframe(of: .attack) {
                duration += Double(keyframes)
            }
            if index >= 1, let keyframe = entity.keyframe(of: .projectileStart) {
                duration += Double(keyframe * index)
            }
            return duration
        default:
            return 0
        }
        
    }
    
    func gameWin(transformation: Transformation?,
                 sprites: [[DFTileSpriteNode]],
                 completion: (() -> Void)? = nil) {
        guard let transformation = transformation,
            let playerWinTransformation = transformation.tileTransformation?.first?.first else {
                completion?()
                return
        }
        
        let exitSprite = sprites[playerWinTransformation.end]
        exitSprite.removeMinecart()
        let playerSprite = sprites[playerWinTransformation.initial]
        playerSprite.removeFromParent()
        
        let minecart = SKSpriteNode(imageNamed: "minecart")
        minecart.size = exitSprite.size.scale(by: Style.DFTileSpriteNode.Exit.minecartSizeCoefficient)
        minecart.zPosition = Precedence.foreground.rawValue
        minecart.position = CGPoint.position(minecart.frame, inside: exitSprite.frame, verticalAnchor: .center, horizontalAnchor: .center)
        
        let playerWin = SKSpriteNode(imageNamed: "playerWin")
        playerWin.size = exitSprite.size.scale(by: Style.DFTileSpriteNode.Exit.minecartSizeCoefficient)
        playerWin.zPosition = Precedence.foreground.rawValue
        playerWin.position = .zero
        
        minecart.addChild(playerWin)
        
        exitSprite.addChild(minecart)
        
        let shrinkAnimation = SKAction.scale(to: AnimationSettings.WinSprite.shrinkCoefficient, duration: 1.0)
        let moveVector = AnimationSettings.WinSprite.moveVector
        let moveAnimation = SKAction.move(by: moveVector, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        
        
        minecart.run(SKAction.sequence([SKAction.group([shrinkAnimation, moveAnimation]), removeAction])) {
            completion?()
        }
    }
    
    func animateGold(goldSprites: [SKSpriteNode], gained: Int, from startPosition: CGPoint, to endPosition: CGPoint) { 
        var index = 0
        let animations: [(SKSpriteNode, SKAction)] = goldSprites.map { sprite in
            let wait = SKAction.wait(forDuration: Double(index) * AnimationSettings.Board.goldWaitTime)
            let moveAction = SKAction.move(to: endPosition, duration: AnimationSettings.Board.goldGainSpeedEnd)
            index += 1
            return (sprite, SKAction.sequence([wait,moveAction, SKAction.removeFromParent()]))
        }
        animate(animations)
    }
    func animate(_ spriteActions: [SpriteAction], completion: (() -> Void)? = nil) {
        let spriteActionTuple = spriteActions.map { ($0.sprite, $0.action) }
        self.animate(spriteActionTuple, completion: completion)
    }
    
    func animate(_ spriteActions: [(SKSpriteNode, SKAction)], completion: (() -> Void)? = nil) {
        if spriteActions.count == 0 { completion?() }
        var numActions = spriteActions.count
        // tell each child to run it's action
        for (child, action) in spriteActions {
            child.run(action) {
                numActions -= 1
                if numActions == 0 {
                    completion?()                    
                }
            }
        }
    }
    
    
    func animate(_ transformation: [TileTransformation]?,
                 boardSize: CGFloat,
                 bottomLeft: CGPoint,
                 spriteForeground: SKNode,
                 tileSize: CGFloat,
                 _ completion: (() -> Void)? = nil) {
        guard let transformation = transformation else {
            completion?()
            return
        }
        
        var childActionDict : [SKNode : SKAction] = [:]
        
        // create each animation action
        for transIdx in 0..<transformation.count {
            let trans = transformation[transIdx]
            //calculate a point that is out of bounds of the foreground
            let outOfBounds: CGFloat = CGFloat(trans.initial.x) >= boardSize ? tileSize * boardSize : 0
            
            // Translate the TileTransformation initial to a tile on screen
            let point = CGPoint.init(x: tileSize * CGFloat(trans.initial.tuple.1) + bottomLeft.x,
                                     y: outOfBounds + tileSize * CGFloat(trans.initial.x) + bottomLeft.y)
            
            // Find that tile and add that animation
            for child in spriteForeground.children {
                if child.contains(point) {
                    let endPoint = CGPoint.init(x: tileSize * CGFloat(trans.end.y) + bottomLeft.x,
                                                y: tileSize * CGFloat(trans.end.x) + bottomLeft.y)
                    let animation = SKAction.move(to: endPoint, duration: AnimationSettings.fallSpeed)
                    childActionDict[child] = animation
                    
                    break
                }
            }
            
        }
        
        // tell each child to run it's action
        for (child, action) in childActionDict {
            child.run(action) {
                completion?()
            }
        }
    }
    
    func animate(attackInputType: InputType,
                 foreground: SKNode,
                 tiles: [[Tile]],
                 sprites: [[DFTileSpriteNode]],
                 positions: ([TileCoord]) -> [CGPoint],
                 completion: (() -> Void)?) {
        guard case InputType.attack(_,
                                    let attackerPosition,
                                    let defenderPosition,
                                    let affectedTiles) = attackInputType else { return }
        
        /*
         Attack animations involve a few things depending on the attack.
         
         There is the animation of the attacker.
         The animation of the defender.
         The sprite/animation of the projectile
         
         However, there is not always a projectile involved.  For example, a player hitting a rat with their pick axe. Or a rat attacking a player
         
         The basic sequence of attacks are:
         - animate the attacker
         - if there are projectiles, animate those
         
         When we are all said and finished, we call animations finished to move on
         
         */
        
        // group up the actions so we can run them sequentially
        var groupedActions: [SKAction] = []
        
        // CAREFUL: Synchronizing on main thread
        let dispatchGroup = DispatchGroup()
        
        
        // attacker animation
        if let attackAnimation = animation(for: .attack, fromPosition: attackerPosition, toPosition: defenderPosition, in: tiles, sprites: sprites, dispatchGroup: dispatchGroup) {
            groupedActions.append(attackAnimation)
        }
        
        let attackAnimationFrames = animationFrames(for: .attack, fromPosition: attackerPosition, toPosition: defenderPosition, in: tiles)
        
        // projectile
        if let projectileGroup = projectileAnimations(from: attackerPosition, in: tiles, with: sprites, affectedTilesPosition: positions(affectedTiles), foreground: foreground, dispatchGroup: dispatchGroup, attackPosition: attackerPosition, defenderPosition: defenderPosition, attackAnimationFrameCount: attackAnimationFrames),
            projectileGroup.count > 0 {
            groupedActions.append(SKAction.group(projectileGroup))
        }
        
        // defender animation
        if let defend = animation(for: .hurt, fromPosition: defenderPosition, toPosition: nil, in: tiles, sprites: sprites, dispatchGroup: dispatchGroup) {
            groupedActions.append(defend)
        }
        
        
        foreground.run(SKAction.sequence(groupedActions))
        dispatchGroup.notify(queue: .main) {
            completion?()
        }
        
    }
    
    private func projectileAnimations(from position: TileCoord?, in tiles: [[Tile]], with sprites: [[DFTileSpriteNode]], affectedTilesPosition: [CGPoint], foreground: SKNode, dispatchGroup: DispatchGroup, attackPosition: TileCoord, defenderPosition: TileCoord?, attackAnimationFrameCount: Int) -> [SKAction]? {
        
        guard let entityPosition = position else { return nil }
        
        /// get the projectile animations depending on the tile type
        
        var projectileStartAnimationFrames: [SKTexture]?
        var projectileMidAnimationFrames: [SKTexture]?
        var projectileEndAnimationFrames: [SKTexture]?
        
        // get the projectile animation
        var projectileRetracts = false
        var isProjectileSequenced = false
        var showSmokeAfter = false
        var projectileTilePerFrame = 0.03
        var flipSpriteHorizontally = false
        if case let TileType.monster(monsterData) = tiles[entityPosition].type {
            
            // set the projectil speed
            projectileTilePerFrame = projectileTimePerFrame(for: monsterData.type)
            
            /// set some variables based on the monster type
            switch monsterData.type {
            case .alamo:
                projectileRetracts = true
                isProjectileSequenced = true
            case .sally:
                projectileRetracts = true
                isProjectileSequenced = true
                projectileTilePerFrame = 0.03
                if let defenderPos = defenderPosition {
                    flipSpriteHorizontally = attackPosition.direction(relative: defenderPos) == .east
                }
            case .dragon:
                isProjectileSequenced = true
                showSmokeAfter = true
            default:
                ()
            }
            
            // grab the start tile animation
            if let projectileAnimation = monsterData.animation(of: .projectileStart) {
                projectileStartAnimationFrames = projectileAnimation
            }
            // grab the mid tile animation
            if let projectileAnimation = monsterData.animation(of: .projectileMid) {
                projectileMidAnimationFrames = projectileAnimation
            }
            
            // grab the end tile animations
            if let projectileAnimation = monsterData.animation(of: .projectileEnd) {
                projectileEndAnimationFrames = projectileAnimation
            }
        }
        
        // projectile
        var projectileGroup: [SKAction] = []
        
        /// certain projectiles like Alamo's attack have two distinct phases.  There is the initial movement across the tile.  These frames are `projectileStart`. The next phase could be a few things.  In Alamo's case, the frames for `projectileMid` are repeated. In Dragon's case, every tile after the first only does `projectileMid`.  In the bat's case, there is no `projectileMid
        
        
        /// Every projectile has start frames.  We can safely return in the case that we do not have any projectileStartFrames
        guard let startFrames = projectileStartAnimationFrames, startFrames.count > 0 else { return nil }
        let affectedTileCount = affectedTilesPosition.count
        
        /// the TileCoords where projectiles should appear
        for (idx, position) in affectedTilesPosition.enumerated() {
            
            /// the initial projectile animation
            var projectileAnimations: [SKAction] = [SKAction.animate(with: startFrames, timePerFrame: projectileTilePerFrame)]
            
            /// Create a sprite where to run the animations
            /// This will get added and removed from the foreground node
            let sprite = SKSpriteNode(color: .clear, size: sprites[0][0].size)
            sprite.position = position
            sprite.zPosition = Precedence.menu.rawValue
            
            /// The following actions are sequenced.
            var sequencedActions: [SKAction] = []
            
            /// For some monster attacks, the projectile goes out and comes back.
            /// We need to animate an `idle` animation and a reverse of the original projectile aniamtion to create this effect
            if projectileRetracts, let midFrames = projectileMidAnimationFrames {
                projectileAnimations = [retractableAnimation(startFrames: startFrames, midFrames: midFrames, endFrames: projectileEndAnimationFrames, currentIndex: idx, totalAfectedTiles: affectedTileCount, projectileAnimationSpeed: projectileTilePerFrame, attackAnimationCount: attackAnimationFrameCount)]
            }
            /// If the attack does not retract then we want to show the midFrames in all the tiles between 1..<n, where n is the length of the attack. Unless there is an projectileEnd aniamtion.  Then we want to only show the midFrames for the middle tiles, where the idx is in 1..<n-1.
            else if idx > 0, let midFrames = projectileMidAnimationFrames {
                let midFrameAnimation = SKAction.animate(with: midFrames, timePerFrame: projectileTilePerFrame)
                projectileAnimations = [midFrameAnimation]
            }
            
            /// sequence the projectile
            if !projectileRetracts,
                isProjectileSequenced,
                case let TileType.monster(monsterData) = tiles[entityPosition].type {
                let duration = projectileKeyFrame(for: monsterData, index: idx)
                let waitAction = SKAction.wait(forDuration: duration * projectileTilePerFrame)
                sequencedActions.append(waitAction)
            }
            
            /// Show smoke as an after effect if needed
            if showSmokeAfter {
                projectileAnimations.append(smokeAnimation())
            }
            
            /// Flip the sprites along y-axis to face the correct direction
            if flipSpriteHorizontally {
                sprite.xScale *= -1
            }
            
            /// The action that animates the actual projectile
            let projectileAction =
                SKAction.run {
                    foreground.addChild(sprite)
                    sprite.run (SKAction.sequence(projectileAnimations)) {
                        sprite.removeFromParent()
                    }
            }
            
            sequencedActions.append(projectileAction)
            let sequence = SKAction.sequence(sequencedActions)
            
            /// All these projectile actions assume the same start time
            projectileGroup.append(sequence)
            
        }
        
        return projectileGroup
    }
    
    private func retractableAnimation(startFrames: [SKTexture], midFrames: [SKTexture], endFrames: [SKTexture]?, currentIndex: Int, totalAfectedTiles: Int, projectileAnimationSpeed: Double, attackAnimationCount: Int = 0) -> SKAction {
        
        let waitFrames = currentIndex * startFrames.count
        let waitDuration = Double(waitFrames + attackAnimationCount) * projectileAnimationSpeed
        let waitAction = SKAction.wait(forDuration: waitDuration)
        
        // start
        let startAnimation: SKAction
        //save the start frames to reverse later
        let actualStartFrames: [SKTexture]
        if currentIndex == totalAfectedTiles - 1, let endFrames = endFrames {
            startAnimation = SKAction.animate(with: endFrames, timePerFrame: projectileAnimationSpeed)
            actualStartFrames = endFrames
        } else {
            startAnimation = SKAction.animate(with: startFrames, timePerFrame: projectileAnimationSpeed)
            actualStartFrames = startFrames
        }
        
        // mid frames
        /// calculate the number of non-terminal tiles after my current index
        let framesAfterMeMinusLastFrame = totalAfectedTiles - currentIndex - 2
        
        /// a constant representing that a projectile goes out and back
        let outAndBackConstant = 2
        
        /// the specific amount of time to wait on the terminal tile.  It differs depending on the animation
        let lastTileWait = (2 * (endFrames?.count ?? startFrames.count))
        
        /// the total frames we need to wait for
        let totalFrames: Int
        
        /// this is the case for the terminal tile
        if framesAfterMeMinusLastFrame == -1 {
            totalFrames = 0
        }
        /// The penultimate tile
        else if framesAfterMeMinusLastFrame == 0 {
            totalFrames = lastTileWait
        }
        /// Any other tile
        else {
            totalFrames = framesAfterMeMinusLastFrame * startFrames.count * outAndBackConstant + lastTileWait
        }
        
        /// Determine the number of repititions.
        let totalCycles = totalFrames / midFrames.count
        
        /// The single animation
        let singleMidFrameAnimation = SKAction.animate(with: midFrames, timePerFrame: projectileAnimationSpeed)
        
        /// The repeated animation
        let repeatedMidAnimation = SKAction.repeat(singleMidFrameAnimation, count: totalCycles)
        
        /// The start animation reverse, animated after the wait animation
        let reverseStartAnimation = SKAction.animate(with: actualStartFrames.reversed(), timePerFrame: projectileAnimationSpeed)
        
        
        /// From the top
        /// Wait your turn to animate
        /// Animate the start
        /// Repeat an idle animation in projectileMidFrames
        /// Reverse the start
        /// Done
        return SKAction.sequence([waitAction, startAnimation, repeatedMidAnimation, reverseStartAnimation])
    }
    
    private func animationFrames(for animationType: AnimationType,
                                 fromPosition position: TileCoord?,
                                 toPosition defenderPosition: TileCoord?,
                                 in tiles: [[Tile]]) -> Int {
        if let position = position {
            if case let TileType.monster(monsterData) = tiles[position].type,
                let attackAnimation = monsterData.animation(of: animationType) {
                return attackAnimation.count
            } else if case let TileType.player(playerData) = tiles[position].type,
                let attackAnimation = playerData.animation(of: animationType) {
                return attackAnimation.count
            }
        }
        return 0
    }
    
    private func animation(for animationType: AnimationType,
                           fromPosition position: TileCoord?,
                           toPosition defenderPosition: TileCoord?,
                           in tiles: [[Tile]],
                           sprites: [[DFTileSpriteNode]],
                           dispatchGroup: DispatchGroup,
                           reverse: Bool = false) -> SKAction? {
        
        var animationFrames: [SKTexture]?
        // get the attack animation
        if let position = position {
            if case let TileType.monster(monsterData) = tiles[position].type,
                let attackAnimation = monsterData.animation(of: animationType) {
                animationFrames = attackAnimation
            } else if case let TileType.player(playerData) = tiles[position].type,
                let attackAnimation = playerData.animation(of: animationType) {
                animationFrames = attackAnimation
            }
        }
        
        var flipHorizontally = false
        if let defendPos = defenderPosition, position?.direction(relative: defendPos) == .east {
            flipHorizontally = true
        }
        
        // animate!
        if let position = position,
            var frames = animationFrames {
            if reverse { frames.reverse() }
            let animation: SKAction
                
            if flipHorizontally {
                let flipAnimation = SKAction.scaleX(to: -1, duration: 0.01)
                animation = SKAction.sequence([flipAnimation, SKAction.animate(with: frames, timePerFrame: self.timePerFrame())])
            } else {
                animation = SKAction.animate(with: frames, timePerFrame: self.timePerFrame())
            }
            
            dispatchGroup.enter()
            return
                SKAction.run {
                    sprites[position].run(animation) {
                        dispatchGroup.leave()
                    }
            }
        }
        return nil
    }
}
