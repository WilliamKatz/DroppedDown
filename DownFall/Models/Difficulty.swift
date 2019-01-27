//
//  Difficulty.swift
//  DownFall
//
//  Created by William Katz on 12/24/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

enum Difficulty: Double {
    case easy = 0.5
    case normal = 1.0
    case hard = 1.5
    
    func maxExpectedMonsters(for board: Board) -> Int {
        return max(Int(Double(board.tiles.count) * self.rawValue / 5.0), 1)
    }
    
    var moves: Int {
        switch self {
        case .easy:
            return 20
        case .normal:
            return 15
        case .hard:
            return 10
        }
    }
}

