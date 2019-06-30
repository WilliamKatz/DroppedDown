//
//  Tile.swift
//  DownFall
//
//  Created by William Katz on 5/11/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

enum TileType: Equatable, Hashable, CaseIterable {
    
    static var rockCases: [TileType] = [.blueRock, .blackRock, .greenRock]
    static var allCases: [TileType] = [.blueRock, .blackRock ,.greenRock, .player(.zero), .exit, .empty, .monster(.zero), .item(.zero)]
    typealias AllCases = [TileType]

    static func == (lhs: TileType, rhs: TileType) -> Bool {
        switch (lhs, rhs) {
        case (.blueRock, .blueRock):
            return true
        case (.blackRock, .blackRock):
            return true
        case (.greenRock, .greenRock):
            return true
        case (.player, .player):
            return true
        case (.empty, .empty):
            return true
        case (.exit, .exit):
            return true
        case (.monster, .monster):
            return true
        case (.item(let lhsItem), .item(let rhsItem)):
            return lhsItem == rhsItem
        default:
            return false
        }
    }
    
    case blueRock
    case blackRock
    case greenRock
    case player(EntityModel)
    case monster(EntityModel)
    case empty
    case exit
    case item(Item)
    
    func isARock() -> Bool {
        switch self {
        case .blackRock, .blueRock, .greenRock:
            return true
        default:
            return false
        }
    }
    
    static var gem: TileType {
        return TileType.item(.gem)
    }
    
    static var gold: TileType {
        return TileType.item(.gold)
    }
    
    /// Return a string representing the texture's file name
    func textureString() -> String {
        switch self {
        case .blueRock:
            return TextueName.blueRock.rawValue
        case .blackRock:
            return TextueName.blackRock.rawValue
        case .greenRock:
            return TextueName.greenRock.rawValue
        case .player:
            return TextueName.player.rawValue
        case .empty:
            return TextueName.empty.rawValue
        case .exit:
            return TextueName.exit.rawValue
        case .monster(let data):
            return data.name
        case .item(let item):
            return item.textureName
        }
    }
    
    
    enum TextueName: String {
        case blueRock
        case blackRock
        case greenRock
        case player = "player2"
        case empty
        case exit
        case greenMonster
        case gem1
    }
}
