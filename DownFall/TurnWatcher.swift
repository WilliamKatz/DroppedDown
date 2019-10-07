//
//  TurnWatcher.swift
//  DownFall
//
//  Created by William Katz on 9/26/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

class TurnWatcher {
    static let shared = TurnWatcher()
    
    private var newTurn = false
    
    init() {
        register()
    }
    
    func register() {
        Dispatch.shared.register { [weak self] (input) in
            switch input.type {
            case .transformation(let transformation):
                switch transformation.inputType {
                case .reffingFinished?:
                    ()
                default:
                    if transformation.tileTransformation != nil {
                        self?.newTurn = true
                    }
                }
            default:
                ()
            }
        }

    }
    
    func getNewTurnAndReset() -> Bool {
        let newTurnValue = newTurn
        newTurn = false
        return newTurnValue
    }
}