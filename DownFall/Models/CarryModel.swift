//
//  Carry.swift
//  DownFall
//
//  Created by William Katz on 6/3/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

struct CarryModel: Decodable, Equatable {
    let items: [Item]
    
    static let zero = CarryModel(items: [])
    
    var hasGem: Bool {
        return items.contains { $0.type == .gem }
    }
    
    private var totalGold: Int {
        return items.filter({ $0.type == .gold }).first?.amount ?? 0
    }
    
    private var totalGem: Int {
        return items.filter({ $0.type == .gem }).count
    }
    
    func total(in currency: Currency) -> Int {
        switch currency {
        case .gem:
            return totalGem
        case .gold:
            return totalGold
        }
    }
    
    func pay(_ price: Int, inCurrency currency: Currency) -> CarryModel {
        var newItems: [Item] = []
        var pricePaid = 0
        let itemType: Item.ItemType = currency == .gold ? .gold : .gem
        for item in items {
            if item.type == itemType && pricePaid < price {
                pricePaid += 1
            } else {
                newItems.append(item)
            }
        }
        
        return CarryModel(items: newItems)
    }
    
    func earn(_ money: Int, inCurrency currency: Currency) -> CarryModel {
        var newItems = items
        var newAmount = money
        let itemType: Item.ItemType = currency == .gold ? .gold : .gem
        if let currentAmount = items.first(where: { $0.type == itemType })?.amount {
            newAmount += currentAmount
        }
        newItems.removeAll { $0.type == itemType }
        newItems.append(Item(type: itemType, amount: newAmount))
        
        return CarryModel(items: newItems)
    }

}
