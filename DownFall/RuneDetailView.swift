//
//  RuneDetailView.swift
//  DownFall
//
//  Created by Katz, Billy on 4/19/20.
//  Copyright © 2020 William Katz LLC. All rights reserved.
//

import SpriteKit

protocol RuneDetailViewModelable {
    var rune: Rune? { get }
    var progress: CGFloat { get }
    var confirmed: ((Rune) -> ())? { get set }
    var canceled: (() -> ())? { get set }
    var isCharged: Bool { get }
    var chargeDescription: String? { get }
    var mode: ViewMode { get }
    
}

struct RuneDetailViewModel: RuneDetailViewModelable {
    var rune: Rune?
    var progress: CGFloat
    var confirmed: ((Rune) -> ())?
    var canceled: (() -> ())?
    var mode: ViewMode
    
    /// returns true is we have completed the charging of a rune
    var isCharged: Bool {
        guard let rune = rune else { return false }
        return progress >= CGFloat(rune.cooldown)
    }
    
    /// returns a string to display to players that describes how to recahrge the rune
    var chargeDescription: String? {
        guard let rune = rune else { return nil }
        var strings: [String] = []
        for type in rune.rechargeType {
            switch type {
            case .rock:
                let grouped = rune.rechargeMinimum > 1
                if grouped {
                    strings.append("Mine \(rune.cooldown) groups of \(rune.rechargeMinimum) or more.")
                } else {
                    strings.append("Mine \(rune.cooldown) rocks.")
                }
            default:
                break
            }
        }
        strings.removeDuplicates()
        
        return strings.joined(separator: ". ")
    }
}

class RuneDetailView: SKSpriteNode, ButtonDelegate {
    let viewModel: RuneDetailViewModelable
    
    struct Constants {
        static let detailBackgroundScale = CGFloat(0.6)
    }
    
    init(viewModel: RuneDetailViewModelable, size: CGSize) {
        self.viewModel = viewModel
        super.init(texture: nil, color: .clear, size: size)
        
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        setupRuneView()
        setupDetailView()
        setupButtons()
    }
    
    func setupRuneView() {
        let size: CGSize
        if viewModel.mode == .storeHUD {
            size = CGSize.oneFifty.scale(by: 0.5)
        }else {
            size = .oneFifty
        }
        
        let viewModel = RuneSlotViewModel(rune: self.viewModel.rune,
                                          registerForUpdates: false,
                                          progress: Int(self.viewModel.progress))
        let runeSlotView = RuneSlotView(viewModel: viewModel,
                                        size: size)
        runeSlotView.position = CGPoint.position(runeSlotView.frame, inside: frame, verticalAlign: .center, horizontalAnchor: .left)
        runeSlotView.zPosition = Precedence.foreground.rawValue
        viewModel.runeWasTapped = { [weak self] (_,_) in self?.viewModel.canceled?() }
        addChild(runeSlotView)
    }
    
    func setupDetailView() {
        let detailView = SKShapeNode(rectOf: size.scale(by: Constants.detailBackgroundScale))
        detailView.color = .runeDetailColor
        detailView.zPosition = Precedence.background.rawValue
        detailView.position = CGPoint.position(detailView.frame, inside: frame, verticalAlign: .center, horizontalAnchor: .center)
        addChild(detailView)
        
        let textOffset = Style.Padding.less
        
        let titleColumnWidth = viewModel.mode == .storeHUD ? 0.0 : CGFloat(180.0)
        let titleContainer = SKSpriteNode(color: .clear, size: CGSize(width: titleColumnWidth, height: detailView.frame.height))
        titleContainer.position = CGPoint.position(titleContainer.frame, inside: detailView.frame, verticalAlign: .center, horizontalAnchor: .left)
        
        /// effect text
        let titleFontSize = UIFont.mediumSize
        let effectTitle = ParagraphNode(text: "Effect:", paragraphWidth: titleColumnWidth, fontSize: titleFontSize)
        let chargeTitle = ParagraphNode(text: "Charge:", paragraphWidth: titleColumnWidth, fontSize: titleFontSize)
        let progressTitle = ParagraphNode(text: "Progress:", paragraphWidth: titleColumnWidth, fontSize: titleFontSize)
        
        progressTitle.position = CGPoint.position(progressTitle.frame, inside: titleContainer.frame, verticalAlign: .bottom, horizontalAnchor: .right, yOffset: textOffset)
        chargeTitle.position = CGPoint.position(chargeTitle.frame, inside: titleContainer.frame, verticalAlign: .center, horizontalAnchor: .right)
        effectTitle.position = CGPoint.position(effectTitle.frame, inside: titleContainer.frame, verticalAlign: .top, horizontalAnchor: .right, yOffset: textOffset)
        
        
        if viewModel.mode != .storeHUD {
            titleContainer.addChild(effectTitle)
            titleContainer.addChild(progressTitle)
            titleContainer.addChild(chargeTitle)
        }
        
        
        // description container
        let descriptionWidth = detailView.frame.width - titleColumnWidth
        let descriptionContainer = SKSpriteNode(color: .clear, size: CGSize(width: descriptionWidth, height: detailView.frame.height))
        descriptionContainer.position = CGPoint.alignVertically(descriptionContainer.frame, relativeTo: titleContainer.frame, horizontalAnchor: .right, verticalAlign: .center, horizontalPadding: Style.Padding.more, translatedToBounds: true)
        
        // description paragraphs
        let descriptionOffset = textOffset + 3.0
        let descriptionFontSize = UIFont.smallSize
        let effectDescription = ParagraphNode(text: viewModel.rune?.description ?? "", paragraphWidth: descriptionWidth, fontSize: descriptionFontSize)
        let chargeDescription = ParagraphNode(text: viewModel.chargeDescription ?? "", paragraphWidth: descriptionWidth, fontSize: descriptionFontSize)
        
        
        
        effectDescription.position = CGPoint.position(effectDescription.frame, inside: descriptionContainer.frame, verticalAlign: .top, horizontalAnchor: .left, yOffset: descriptionOffset)
        chargeDescription.position = CGPoint.position(chargeDescription.frame, inside: descriptionContainer.frame, verticalAlign: .center, horizontalAnchor: .left)
        
        descriptionContainer.addChild(effectDescription)
        
        if viewModel.mode != .storeHUD {
            if let ability = viewModel.rune {
                let progressDescription = ParagraphNode(text: "\(Int(viewModel.progress))/\( ability.cooldown)", paragraphWidth: descriptionWidth, fontSize: descriptionFontSize)
                progressDescription.position = CGPoint.position(progressDescription.frame, inside: descriptionContainer.frame, verticalAlign: .bottom, horizontalAnchor: .left, yOffset: descriptionOffset)
                descriptionContainer.addChild(progressDescription)
            }
            
            
            
            descriptionContainer.addChild(chargeDescription)
            
        }
        
        detailView.addChild(descriptionContainer)
        detailView.addChild(titleContainer)
        
    }
    
    var confirmButton: Button?
    
    func enableButton(_ enable: Bool) {
        confirmButton?.enable(enable && viewModel.isCharged)
    }
    
    func setupButtons() {
        switch viewModel.mode {
        case .itemDetail, .inventory:
            if viewModel.rune != nil {
                
                let confirmSprite = SKSpriteNode(texture: SKTexture(imageNamed: "buttonAffirmitive"), size: .oneHundred)
                let confirmButton = Button(size: .oneHundred, delegate: self, identifier: .backpackConfirm, image: confirmSprite, shape: .circle, showSelection: true, disable: !viewModel.isCharged)
                confirmButton.position = CGPoint.position(confirmButton.frame, inside: self.frame, verticalAlign: .center, horizontalAnchor: .right, xOffset: Style.Padding.more)
                addChild(confirmButton)
                
                self.confirmButton = confirmButton
            }
            
            let cancelSprite = SKSpriteNode(texture: SKTexture(imageNamed: "buttonNegative"), size: .oneHundred)
            let cancelButton = Button(size: .oneHundred, delegate: self, identifier: .backpackCancel, image: cancelSprite, shape: .circle, showSelection: true)
            cancelButton.position = CGPoint.alignHorizontally(cancelButton.frame, relativeTo: frame, horizontalAnchor: .right, verticalAlign: .top, verticalPadding: Style.Padding.more, horizontalPadding: Style.Padding.more)
            
            addChild(cancelButton)
        case .storeHUD, .storeHUDExpanded:
            let cancelSprite = SKSpriteNode(texture: SKTexture(imageNamed: "buttonNegative"), size: .oneHundred)
            let cancelButton = Button(size: .oneHundred, delegate: self, identifier: .backpackCancel, image: cancelSprite, shape: .circle, showSelection: true)
            cancelButton.position = CGPoint.position(cancelButton.frame, inside: self.frame, verticalAlign: .center, horizontalAnchor: .right, xOffset: Style.Padding.more)
            
            addChild(cancelButton)
        }
    }
    
    /// MARK: ButtonDelegate
    func buttonTapped(_ button: Button) {
        switch button.identifier {
        case .backpackCancel:
            viewModel.canceled?()
        case .backpackConfirm:
            guard let ability = viewModel.rune else { return }
            viewModel.confirmed?(ability)
        default:
            break
        }
    }
    
}
