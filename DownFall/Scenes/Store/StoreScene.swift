//
//  StoreScene.swift
//  DownFall
//
//  Created by William Katz on 7/31/19.
//  Copyright © 2019 William Katz LLC. All rights reserved.
//

import SpriteKit

let closeButton = "closeButton"
let buyButton = "buyButton"
let sellButton = "sellButton"
let wallet = "wllet"

protocol StoreSceneDelegate: class {
    func leave(_ storeScene: StoreScene, updatedPlayerData: EntityModel)
}

protocol StoreSceneInventory {
    var items: [Ability] { get }
}

class StoreScene: SKScene {
    private let background: SKSpriteNode
    private var playerData: EntityModel
    private var items: [StoreItem] = []
    var selectedItem: StoreItem? {
        didSet {
            guard oldValue != selectedItem else { return }
            toggleUI()
        }
    }
    
    weak var storeSceneDelegate: StoreSceneDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    
    init(size: CGSize,
         playerData: EntityModel,
         inventory: StoreSceneInventory) {
        //playable rect
        let maxAspectRatio : CGFloat = 19.5/9.0
        let playableWidth = size.height / maxAspectRatio
        background = SKSpriteNode(color: .clayRed,
                                  size: CGSize(width: playableWidth,
                                               height: size.height))
        
        self.playerData = playerData
        super.init(size: size)
        
        
        
        let button = Button(size: CGSize(width: 150, height: 50),
                            delegate: self,
                            identifier: .leaveStore,
                            precedence: .foreground,
                            fontSize:  25)
        button.position = CGPoint(x: 0, y: -300)
        
        
        items = createStoreItems(from: inventory)
        positionStore(items, playableWidth)
        items.forEach {
            addChild($0)
        }
        
        
        background.addChild(button)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(background)
        addChild(walletView)
    }
    
    private func createStoreItems(from inventory: StoreSceneInventory) -> [StoreItem] {
        var items: [StoreItem] = []
        for item in inventory.items {
            items.append(StoreItem(ability: item,
                                   size: CGSize(width: 50, height: 50),
                                   delegate: self,
                                   identifier: .storeItem,
                                   precedence: .foreground,
                                   fontSize: 25))
        }
        return items
    }
    
    private func positionStore(_ items: [StoreItem],_ playableWidth: CGFloat) {
        let gridPoints = CGPoint.gridPositions(rows: 3,
                                               columns: 3,
                                               itemSize: CGSize(width: 50, height: 50),
                                               width: playableWidth,
                                               height: 330,
                                               bottomLeft: CGPoint(x: -frame.width/2, y: -125))
        for (index, position) in gridPoints.enumerated() {
            if items.count >= index {
                items[index].position = position
            }
            
        }
    }

    private var walletView: SKSpriteNode {
        let walletView = SKSpriteNode(color: .storeBlack, size: CGSize(width: 150, height: 50))
        walletView.position = CGPoint(x: frame.minX + walletView.size.width/2, y: -200)
        
        let coin = SKSpriteNode(texture: SKTexture(imageNamed: "gold"), size: CGSize(width: 35, height: 35))
        coin.position = CGPoint(x: walletView.size.width/2 - coin.size.width/2, y: 0)
        
        let coinLabel = Label(text: "\(playerData.carry.totalGold)",
                              precedence: .foreground,
                              font: UIFont.storeItemDescription,
                              fontColor: .storeDarkGray,
                              maxWidth: walletView.frame.width)
        coinLabel.centeredInSuperview()
        
        
        walletView.addChild(coin)
        walletView.addChild(coinLabel)
        walletView.name = wallet
        return walletView
    }
    
    private var transactionButton: Button {
        let purchased = selectedItem?.isPurchased ?? false
        let purchaseButton = Button(size: CGSize(width: 200, height: 50),
                                    delegate: self,
                                    textureName: purchased ? sellButton : buyButton,
                                    precedence: .foreground)
        purchaseButton.position = CGPoint(x: frame.maxX, y: -200)
        return purchaseButton
    }
    
    private func toggleUI() {
        toggleSelect()
        togglePopup()
        toggleTransactionButton()
    }
    
    
    private func informationPopup(with text: String) -> SKSpriteNode {
        let popupNode = SKSpriteNode(color: .storeItemBackground,
                                     size: CGSize(width: self.frame.width - 100, height: 200))
        popupNode.position = CGPoint(x: frame.midX, y: frame.maxY - 150)
        let descriptionLabel = Label(text: text,
                                     precedence: .foreground,
                                     font: UIFont.storeItemDescription,
                                     fontColor: .storeDarkGray,
                                     maxWidth: popupNode.frame.width - 8)
        descriptionLabel.horizontalAlignmentMode = .center
        descriptionLabel.verticalAlignmentMode = .center
        popupNode.addChild(descriptionLabel)
        
        let closeBtn = Button(size: CGSize(width: 35, height: 35),
                                 delegate: self,
                                 textureName: closeButton,
                                 precedence: .menu)
        closeBtn.position = CGPoint(x: popupNode.frame.width/2 - closeBtn.frame.width/2,
                                    y: popupNode.frame.height/2 - closeBtn.frame.height/2)
        popupNode.addChild(closeBtn)
        popupNode.name = "popup"
        return popupNode
    }
    
    private func show(_ node: SKSpriteNode) {
        children.forEach {
            if $0.name == node.name {
                $0.removeFromParent()
            }
        }
        addChild(node)
    }
    
    private func toggleSelect() {
        func deselect() {
            for item in items {
                item.deselect()
            }
        }
        func select() {
            for item in items {
                if item == selectedItem {
                    item.select()
                }
            }
        }
        
        deselect()
        select()
        
    }
    
    private func togglePopup() {
        func hidePopup() {
            for child in self.children {
                if child.name == "popup" {
                    child.removeAllChildren()
                    child.removeFromParent()
                }
            }
        }
        
        func showPopup() {
            guard let description = selectedItem?.ability.description else { return }
            let infoPopup = informationPopup(with: description)
            show(infoPopup)
        }
        
        hidePopup()
        showPopup()
    }
    

    
    private func hidePopup() {
        for child in self.children {
            if child.name == "popup" {
                child.removeAllChildren()
                child.removeFromParent()
            } else if child.name == buyButton {
                let slideOut = SKAction.moveTo(x: frame.maxX + child.frame.width/2,
                                              duration: TimeInterval(exactly: 0.3)!)
                child.run(slideOut) {
                    child.removeFromParent()
                }

            }
        }
    }
    
    private func hideButton(with name: String) {
        for child in self.children {
            if child.name == name {
                let slideOut = SKAction.moveTo(x: frame.maxX + child.frame.width/2,
                                               duration: TimeInterval(exactly: 0.3)!)
                child.run(slideOut) {
                    child.removeFromParent()
                }
                
            }
        }

    }
    
    private func reloadWalletView() {
        let newWalletView = walletView
        
        for child in children {
            if child.name == wallet {
                removeFromParent()
            }
        }
        
        show(newWalletView)
    }
    
    private func buy(_ storeItem: StoreItem) {
        let ability = storeItem.ability
        if playerData.canAfford(ability.cost) {
            playerData = playerData.add(ability)
            playerData = playerData.buy(ability)
            storeItem.purchase()
            reloadWalletView()
        }
    }
    
    private func sell(_ storeItem: StoreItem) {
        playerData = playerData.remove(storeItem.ability)
        playerData = playerData.sell(storeItem.ability)
        storeItem.sell()
        reloadWalletView()
    }
    
    private func toggleTransactionButton() {
        hideButton(with: buyButton)
        hideButton(with: sellButton)
        if let selectedItem = selectedItem {
            showButton(selectedItem.isPurchased ? sellButton : buyButton)
        }
    }
    
    private func showButton(_ buttonName: String) {
        let button = transactionButton
        let slideIn = SKAction.moveTo(x: frame.maxX - transactionButton.size.width/2,
                                      duration: TimeInterval(exactly: 0.5)!)
        show(button)
        button.run(slideIn)
    }
}

extension StoreScene: StoreItemDelegate {
    func storeItemTapped(_ storeItem: StoreItem, ability: Ability) {
        selectedItem = storeItem
    }
    
    func wasTransactedOn(_ storeItem: StoreItem) {
        toggleUI()
    }
}

extension StoreScene : ButtonDelegate {
    func buttonPressed(_ button: Button) {
        if button.name == "leaveStore" {
            storeSceneDelegate?.leave(self, updatedPlayerData: playerData)
        } else if button.name == buyButton,
            let storeItem = selectedItem {
            buy(storeItem)
        } else if button.name == sellButton,
            let storeItem = selectedItem {
            sell(storeItem)
        } else if button.name == closeButton {
            selectedItem = nil
        }

    }
}