//
//  PauseState.swift
//  DownFall
//
//  Created by William Katz on 7/28/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

struct PauseState: GameState {
    var state: State = .paused
    
    func enter(_ input: Input) {}
    
    func shouldAppend(_ input: Input) -> Bool {
        return input.type == .play || input.type == .selectLevel
    }
    
    func transitionState(given input: Input) -> AnyGameState? {
        switch input.type {
        case .play, .selectLevel:
            return AnyGameState(PlayState())
        default:
            return nil
        }
    }
}
