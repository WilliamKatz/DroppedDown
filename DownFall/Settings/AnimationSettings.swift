//
//  AnimationSettings.swift
//  DownFall
//
//  Created by William Katz on 5/17/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

import CoreGraphics

struct AnimationSettings {
    static let rotateSpeed = 0.4
    static let fallSpeed = 0.2
    
    struct WinSprite {
        static let moveVector: CGVector = CGVector(dx: 0.0, dy: 20.0)
        static let shrinkCoefficient: CGFloat = 0.2
    }
    
    struct Store {
        static let itemFrameRate = Double(0.3)
    }
    
    struct Backpack {
        static let itemDetailMoveRate = Double(0.15)
    }
    
    struct Board {
        static let goldGainSpeedStart = Double(0.15)
        static let goldGainSpeedEnd = Double(0.65)
        static let goldWaitTime = Double(0.05)
    }
    
    struct HUD {
        static let goldGainedTime = Double(1.0)
    }
}
