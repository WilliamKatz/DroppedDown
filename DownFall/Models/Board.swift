//
//  Board.swift
//  DownFall
//
//  Created by William Katz on 5/12/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

class Board: Equatable {
    static func == (lhs: Board, rhs: Board) -> Bool {
        return false
    }
    
    private(set) var tiles: [[Tile]]
    
    private var playerPosition : TileCoord? {
        return getTileStructPosition(.player(.zero))
    }
    var boardSize: Int { return tiles.count }
    var tileCreator: TileStrategy
    
    private let level: Level
    
    subscript(index: TileCoord) -> TileType? {
        guard isWithinBounds(index) else { return nil }
        return tiles[index.x][index.y].type
        
    }
    
    init(tileCreator: TileStrategy,
         tiles: [[Tile]],
         level: Level) {
        self.tileCreator = tileCreator
        self.tiles = tiles
        self.level = level
        
        Dispatch.shared.register { [weak self] in self?.handle(input: $0) }
    }
    
    private func isWithinBounds(_ tileCoord: TileCoord) -> Bool {
        let (tileRow, tileCol) = tileCoord.tuple
        return tileRow >= 0 && //lower bound
            tileCol >= 0 && // lower bound
            tileRow < boardSize && // upper bound
            tileCol < boardSize
    }
    
    private func resetShouldHighlight() {
        for i in 0..<tiles.count {
            for j in 0..<tiles[i].count {
                let tile = tiles[i][j]
                tiles[i][j] = Tile(type: tiles[i][j].type, shouldHighlight: false, bossTargetedToEat: tile.bossTargetedToEat)
            }
        }
    }
    
    func handle(input: Input) {
        var transformation: Transformation?
        resetShouldHighlight()
        switch input.type {
        case .rotateCounterClockwise:
            InputQueue.append(Input(.transformation(rotate(.left))))
            return
        case .rotateClockwise:
            InputQueue.append(Input(.transformation(rotate(.right))))
            return
        case .touchBegan:
            transformation = Transformation(transformation: nil,
                                            inputType: input.type,
                                            endTiles: tiles)
        case .touch(let tileCoord, let type):
            if case TileType.monster = type {
                transformation = indicateAttackPattern(from: tileCoord, inputType: input.type)
            } else {
                transformation = removeAndReplace(from: tiles, tileCoord: tileCoord, input: input)
            }
        case .attack:
            transformation = attack(input)
        case .monsterDies(let tileCoord):
            //only remove a single tile when a monster dies
            transformation = monsterDied(at: tileCoord, input: input)
        case .gameWin:
            transformation = gameWin()
        case .collectItem(let tileCoord, _, _):
            transformation = collectItem(at: tileCoord, input: input)
        case .reffingFinished(let newTurn):
            transformation = resetAttacks(newTurn: newTurn)
        case .transformation(let trans):
            if let inputType = trans.first?.inputType,
                case .reffingFinished(_) = inputType,
                let tilesSruct = trans.first?.endTiles {
                let input = Input(.newTurn, tilesSruct)
                InputQueue.append(input)
                transformation = nil
            }
        case .itemUseSelected(let ability):
            InputQueue.append(
                Input(
                    InputType.transformation(
                        [Transformation(transformation: nil, inputType: .itemUseSelected(ability), endTiles: self.tiles)]
                    )
                )
            )
            
        case .itemUsed(let ability, let targets):
            let trans = use(ability, on: targets, input: input)
            
            InputQueue.append(
                Input(
                    InputType.transformation(
                        [trans]
                    )
                )
            )
        case .bossTargetsWhatToEat(let coords):
            coords.forEach { coord in
                tiles[coord.row][coord.column].bossTargetedToEat = true
            }
            InputQueue.append(
                Input(
                    InputType.transformation(
                        [Transformation(transformation: nil, inputType: .bossTargetsWhatToEat(coords), endTiles: self.tiles)]
                    )
                )
            )
        case .bossEatsRocks(let coords):
            let trans = bossEatsRocks(input, targets: coords)
            InputQueue.append(Input(.transformation(trans)))
        case .bossTargetsWhatToAttack(let attackDictionary):
            transformation = bossAttackTargets(attackDictionary, input: input)
        case .bossAttacks(let attackDictionary):
            transformation = bossAttacks(attackDictionary, input: input)
        case .gameLose(_),
             .play,
             .pause,
             .animationsFinished,
             .playAgain,
             .boardBuilt,
             .selectLevel,
             .newTurn,
             .tutorial,
             .visitStore,
             .itemUseCanceled, .itemCanBeUsed:
            transformation = nil
        }
        
        guard let trans = transformation else { return }
        InputQueue.append(Input(.transformation([trans])))
    }
    
    func bossAttacks(_ attacks: [BossController.BossAttack: Set<TileCoord>], input: Input) -> Transformation {
        for (_, value) in attacks {
            value.forEach { coord in
                tiles[coord.row][coord.column].bossAttack = true
            }
        }
        return Transformation(transformation: nil, inputType: input.type, endTiles: tiles)
    }
    
    func bossAttackTargets(_ attacks: [BossController.BossAttack: Set<TileCoord>], input: Input) -> Transformation {
        for (_, value) in attacks {
            value.forEach { coord in
                tiles[coord.row][coord.column].bossTargetToAttack = true
            }
        }
        return Transformation(transformation: nil, inputType: input.type, endTiles: tiles)
    }
    
    func bossEatsRocks(_ input: Input, targets: [TileCoord]) -> [Transformation] {
        return [removeAndReplace(from: tiles, specificCoord: targets, input: input)]
    }
    
    func indicateAttackPattern(from coord: TileCoord, inputType: InputType) -> Transformation {
        func attackedTiles(in tiles: [[Tile]], from position: TileCoord) -> [TileCoord] {
            guard isWithinBounds(position) else { return [] }
            let attacker = tiles[position]
            if case TileType.player(let player) = attacker.type  {
                return calculateAttacks(for: player, from: position)
            } else if case TileType.monster(let monster) = attacker.type {
                return calculateAttacks(for: monster, from: position)
            }
            return []
        }
        
        
        func calculateAttacks(for entity: EntityModel, from position: TileCoord) -> [TileCoord] {
            return entity.attack.targets(from: position).compactMap { target in
                if isWithinBounds(target) {
                    return target
                }
                return nil
            }
        }

        var newTiles = tiles
        let affectedTile = attackedTiles(in: tiles, from: coord)
        for coord in affectedTile {
            newTiles[coord.x][coord.y].shouldHighlight = true
        }
        tiles = newTiles
        
        return Transformation(transformation: .none,
                              inputType: inputType,
                              endTiles: tiles)
    }
    
    
    // MARK: - Helpers
    private func getTileStructPosition(_ type: TileType) -> TileCoord? {
        for i in 0..<tiles.count {
            for j in 0..<tiles[i].count {
                if tiles[i][j].type == type {
                    return TileCoord(i,j)
                }
            }
        }
        return nil
    }
    
    private func use(_ ability: AnyAbility) {
        if let playerCoord = self.tiles(of: .player(.zero)).first {
            if case TileType.player(let data) = tiles[playerCoord].type {
                let newData = data.use(ability)
                var newTiles = tiles
                newTiles[playerCoord.row][playerCoord.column] = Tile(type: .player(newData))
                tiles = newTiles
            }
        }

    }
    
    private func swap(_ first: TileCoord, with second: TileCoord, input: Input) -> Transformation {
        
        let tempTile = tiles[first]
        tiles[first.row][first.column] = tiles[second.row][second.column]
        tiles[second.row][second.column] = tempTile
        let tileTransformation = [TileTransformation(first, second), TileTransformation(second, first)]
        return Transformation(transformation: [tileTransformation], inputType: input.type, endTiles: tiles)
        
    }
    
    private func transmogrify(_ target: TileCoord, input: Input) -> Transformation {
        if case let TileType.monster(data) = tiles[target].type {
            let newMonster = tileCreator.randomMonster(not: data.type)
            tiles[target.row][target.column] = newMonster
            return Transformation(transformation: nil, inputType: input.type, endTiles: tiles)
        } else {
            preconditionFailure("We should never hit this code path")
        }
    }
}

//MARK: - use ability

extension Board {
    private func use(_ ability: AnyAbility, on targets: [TileCoord], input: Input) -> Transformation {
        switch ability.type {
        case .greaterHealingPotion, .lesserHealingPotion:
            if let playerCoord = self.tiles(of: .player(.zero)).first {
                if case TileType.player(let data) = tiles[playerCoord].type, let heal = ability.heal {
                    let newData = data.heal(for: heal).use(ability)
                    tiles[playerCoord.x][playerCoord.y] = Tile(type: .player(newData))
                    return Transformation(transformation: nil,
                                          inputType: input.type,
                                          endTiles: tiles)
                    
                    
                    
                    
                }
            }
        case .dynamite:
            use(ability)
            return removeAndReplace(from: tiles, tileCoord: targets.first!, singleTile: true, input: input)
        case .rockASwap:
            use(ability)
            let firstTarget = targets.first!
            let secondTarget = targets.last!
            return swap(firstTarget, with: secondTarget, input: input)
        case .transmogrificationPotion:
            use(ability)
            let target = targets.first!
            return transmogrify(target, input: input)
        case .killMonsterPotion:
            use(ability)
            return removeAndReplace(from: tiles, tileCoord: targets.first!, singleTile: true, input: input)
        default:
            ()
        }
        
        return .zero
    }
}


// MARK: - Find Neighbors Remove and Replace

extension Board {
    
    /// Return true if a neighbor coord is within the bounds of the board
    /// within one tile in a cardinal direction of the currCoord
    /// and not equal to the currCoord
    func valid(neighbor: TileCoord?, for currCoord: TileCoord?) -> Bool {
        guard let (neighborRow, neighborCol) = neighbor?.tuple,
            let (tileRow, tileCol) = currCoord?.tuple else { return false }
        guard neighborRow >= 0, //lower bound
            neighborCol >= 0, // lower bound
            neighborRow < boardSize, // upper bound
            neighborCol < boardSize, // upper bound
            neighbor != currCoord // not the same coord
            else { return false }
        let tileSum = tileRow + tileCol
        let neighborSum = neighborRow + neighborCol
        let difference = abs(neighborSum - tileSum)
        guard difference <= 1 //tiles are within one of eachother
            && ((tileSum % 2 == 0  && neighborSum % 2 == 1) || (tileSum % 2 == 1 && neighborSum % 2 == 0)) // they are not diagonally touching
            else { return false }
        return true
    }
    
    func validCardinalNeighbors(of coord: TileCoord) -> [TileCoord] {
        var neighbors : [TileCoord] = []
        let (tileRow, tileCol) = coord.tuple
        for i in tileRow-1...tileRow+1 {
            for j in tileCol-1...tileCol+1 {
                //check that it is within bounds
                if valid(neighbor: TileCoord(i,j), for: TileCoord(tileRow, tileCol)) {
                    neighbors.append(TileCoord(i, j))
                }
            }
        }
        return neighbors
    }
    
    
    /// Find all contiguous neighbors of the same color as the tile that was tapped
    /// Return a new board with the selectedTiles updated
    
    func findNeighbors(_ coord: TileCoord) -> ([TileCoord], [TileCoord]) {
        let (x,y) = coord.tuple
        guard
            x >= 0,
            x < boardSize,
            y >= 0,
            y < boardSize else { return ([], []) }
        
        if case TileType.monster(_) = tiles[x][y].type { return ([],[]) }
        if case TileType.pillar = tiles[x][y].type { return ([],[]) }
        var queue = [TileCoord(x, y)]
        var tileCoordSet = Set(queue)
        var head = 0
        var pillars = Set<TileCoord>()
        
        while head < queue.count {
            let tileRow = queue[head].x
            let tileCol = queue[head].y
            let currTile = tiles[tileRow][tileCol]
            head += 1
            //add neighbors to queue
            for i in tileRow-1...tileRow+1 {
                for j in tileCol-1...tileCol+1 {
                    //check that it is within bounds, that we havent visited it before, and it's the same type as us
                    guard
                        valid(neighbor: TileCoord(i,j), for: TileCoord(tileRow, tileCol)),
                        !tileCoordSet.contains(TileCoord(i,j)),
                        let myColor = tiles[i][j].type.color, let theirColor = currTile.type.color,
                        myColor == theirColor
                        else { continue }
                    //valid neighbor within bounds
                    if case .pillar = tiles[i][j].type {
                        pillars.insert(TileCoord(i,j))
                    } else {
                        queue.append(TileCoord(i,j))
                        tileCoordSet.insert(TileCoord(i,j))
                    }
                }
            }
        }
        return (queue, Array(pillars))
    }
    
    /*
     * Remove and refill tiles from the current board
     *
     *  - replaces each tile in the contiguous group of same-colored tiles with an Empty tile type
     *  - iterates through each column starting an at row 0 and ending at row n-1, and increments a shift counter by 1 when it encounters an Empty sprite placeholder
     *  - swaps the current empty tile at index i with the tile at index i+1, thusly all empty tiles end up near at the "top" of each column
     *  - returns a transformation with the tiles that have been removed, added, and shifted down
     */
    
    func removeAndReplace(from tiles: [[Tile]],
                          tileCoord: TileCoord,
                          singleTile: Bool = false,
                          input: Input) -> Transformation {
        // Check that the tile group at row, col has more than 3 tiles
        var selectedTiles: [TileCoord] = [tileCoord]
        var selectedPillars: [TileCoord] = []
        if !singleTile {
            (selectedTiles, selectedPillars) = findNeighbors(tileCoord)
            if selectedTiles.count < 3 {
                return Transformation(transformation: nil,
                                      inputType: input.type,
                                      endTiles: tiles)
            }
        }
        
        
        
        // set the tiles to be removed as Empty placeholder
        var intermediateTiles = tiles
        for coord in selectedTiles {
            intermediateTiles[coord.x][coord.y] = Tile.empty
        }
        
        // decrement the health of each pillar
        for pillarCoord in selectedPillars {
            if case let .pillar(color, health) = intermediateTiles[pillarCoord.x][pillarCoord.y].type {
                if health == 1 {
                    // remove the pillar from the board
                    intermediateTiles[pillarCoord.x][pillarCoord.y] = Tile.empty
                } else {
                    //decrement the pillar's health
                    intermediateTiles[pillarCoord.x][pillarCoord.y] = Tile(type: .pillar(color, health-1))
                }
            }
        }
        
        // store tile transforamtions and shift information
        var newTiles : [TileTransformation] = []
        var (shiftDown, shiftIndices) = calculateShiftIndices(for: &intermediateTiles)
        
        //add new tiles
        addNewTiles(shiftIndices: shiftIndices,
                    shiftDown: &shiftDown,
                    newTiles: &newTiles,
                    intermediateTiles: &intermediateTiles)
        
        //create selectedTilesTransformation array
        let selectedTilesTransformation = selectedTiles.map { TileTransformation($0, $0) }
        
        //update our store of tilesftiles
        self.tiles = intermediateTiles
        
        // return our new board
        return Transformation(transformation: [selectedTilesTransformation,
                                               newTiles,
                                               shiftDown],
                              inputType: input.type,
                              endTiles: intermediateTiles
        )
    }
    
    
    func removeAndReplace(from tiles: [[Tile]],
                          specificCoord: [TileCoord],
                          singleTile: Bool = false,
                          input: Input) -> Transformation {
        // Check that the tile group at row, col has more than 3 tiles
        var selectedTiles: [TileCoord] = specificCoord
        
        
        // set the tiles to be removed as Empty placeholder
        var intermediateTiles = tiles
        for coord in selectedTiles {
            intermediateTiles[coord.x][coord.y] = Tile.empty
        }
        
        // store tile transforamtions and shift information
        var newTiles : [TileTransformation] = []
        var (shiftDown, shiftIndices) = calculateShiftIndices(for: &intermediateTiles)
        
        //add new tiles
        addNewTiles(shiftIndices: shiftIndices,
                    shiftDown: &shiftDown,
                    newTiles: &newTiles,
                    intermediateTiles: &intermediateTiles)
        
        //create selectedTilesTransformation array
        let selectedTilesTransformation = selectedTiles.map { TileTransformation($0, $0) }
        
        //update our store of tilesftiles
        self.tiles = intermediateTiles
        
        // return our new board
        return Transformation(transformation: [selectedTilesTransformation,
                                               newTiles,
                                               shiftDown],
                              inputType: input.type,
                              endTiles: intermediateTiles
        )
    }

    
    private func resetAttacks(newTurn: Bool) -> Transformation? {
        func resetAttacks(in tiles: [[Tile]]) -> [[Tile]] {
            var newTiles = tiles
            for (i, row) in tiles.enumerated() {
                for (j, _) in row.enumerated() {
                    if case .monster(let data) = tiles[i][j].type, newTurn {
                        newTiles[i][j] = Tile(type: .monster(data.resetAttacks().incrementsAttackTurns()))
                    }
                    
                    if case .player(let data) = tiles[i][j].type {
                        newTiles[i][j] = Tile(type: .player(data.resetAttacks()))
                    }
                }
            }
            return newTiles
        }
        
        tiles = resetAttacks(in: tiles)
        
        return Transformation(transformation: nil,
                              inputType: .reffingFinished(newTurn: newTurn),
                              endTiles: tiles
        )
        
        
    }
    
    private func collectItem(at coord: TileCoord, input: Input) -> Transformation {
        let selectedTile = tiles[coord]
        
        //remove and replace the single item tile
        let transformation = removeAndReplace(from: tiles, tileCoord: coord, singleTile: true, input: input)
        
        //save the item
        guard case let TileType.item(item) = selectedTile.type,
            var updatedTiles = transformation.endTiles,
            let pp = playerPosition,
            case let .player(data) = updatedTiles[pp].type
            else { return Transformation.zero }
            
        let newCarryModel = data.carry.earn(item.amount, inCurrency: item.type.currencyType)
        let playerData = EntityModel(originalHp: data.originalHp,
                                     hp: data.hp,
                                     name: data.name,
                                     // we have to reset attack here because the player has moved but the turn may not be over
                                     // Eg: it is possible that there could be two or more monsters
                                     // under the player and the player should be able to attack
                                     attack: data.attack.resetAttack(),
                                     type: data.type,
                                     carry: newCarryModel,
                                     animations: data.animations,
                                     abilities: data.abilities)
        
        updatedTiles[pp.x][pp.y] = Tile(type: .player(playerData))
        
        tiles = updatedTiles
        
        return Transformation(transformation: transformation.tileTransformation,
                              inputType: .collectItem(coord, item, playerData.carry.total(in: item.type.currencyType)),
                              endTiles: updatedTiles)
    }
    
    
    private func monsterDied(at coord: TileCoord, input: Input) -> Transformation {
        if case let .monster(monsterData) = tiles[coord].type {
            let gold = tileCreator.goldDropped(from: monsterData)
            let item = Item.init(type: .gold, amount: gold)
            let itemTile = TileType.item(item)
            tiles[coord.x][coord.y] = Tile(type: itemTile)
            return Transformation(transformation: nil,
                                  inputType: .monsterDies(coord),
                                  endTiles: tiles)
        } else {
            //no item! remove and replace
            return removeAndReplace(from: tiles, tileCoord: coord, singleTile: true, input: input)
        }
        
    }
    
    private func addNewTiles(shiftIndices: [Int],
                             shiftDown: inout [TileTransformation],
                             newTiles: inout [TileTransformation],
                             intermediateTiles: inout [[Tile]]) {
        // Intermediate tiles is the "in-between" board that has shifted down
        // tiles into and replaced the shifted down tiles with empty tiles
        // the tile creator replaces empty tiles with new tiles
        let createdTiles: [[Tile]] = tileCreator.tiles(for: intermediateTiles)
//        guard createdTiles.count == shiftIndices.reduce(0, +) else { assertionFailure("newTileTypes count must match the number of empty tiles in the board"); return }
        
        for (col, shifts) in shiftIndices.enumerated() where shifts > 0 {
            for startIdx in 0..<shifts {
                let startRow = boardSize + startIdx
                let startCol = col
                let endRow = startRow - shifts
                let endCol = col
                
                //append to shift dictionary
                var trans = TileTransformation(TileCoord(startRow, startCol),
                                               TileCoord(endRow, endCol))
                shiftDown.append(trans)
                
                //update new tiles
                trans = TileTransformation(TileCoord(startRow, startCol),
                                           TileCoord(endRow, endCol))
                newTiles.append(trans)
            }
        }
        
        intermediateTiles = createdTiles
    }
    
    private func calculateShiftIndices(for tiles: inout [[Tile]]) -> ([TileTransformation], [Int]) {
        var shiftIndices = Array(repeating: 0, count: tiles.count)
        var shiftDown: [TileTransformation] = []
        for col in 0..<tiles.count {
            var shift = 0
            for row in 0..<tiles.count {
                switch tiles[row][col].type {
                case .pillar:
                    shift = 0
                case .empty:
                    shift += 1
                default:
                    if shift != 0 {
                        let endRow = row-shift
                        let trans = TileTransformation(TileCoord(row, col), TileCoord(endRow, col))
                        shiftDown.append(trans)
                        
                        //update tile storage
                        let intermediateTile = tiles[row][col]
                        
                        // move the empty tile up
                        tiles[row][col] = tiles[row-shift][col]
                        // move the non-empty tile down
                        tiles[row-shift][col] = intermediateTile
                    }
                }
            }
            shiftIndices[col] = shift
        }
        return (shiftDown, shiftIndices)
    }
    
}

// MARK: - Factory

extension Board {
    static func build(tileCreator: TileStrategy,
                      difficulty: Difficulty,
                      level: Level) -> Board {
        //create a boardful of tiles
        let tilesStruct: [[Tile]] = tileCreator.board(difficulty: difficulty)
        
        //let the world know we built the board
        InputQueue.append(Input(.boardBuilt, tilesStruct))
        
        //init new board
        return Board(tileCreator: tileCreator, tiles: tilesStruct, level: level)
    }
}

// MARK: - Rotation

extension Board {
    
    enum RotationalDirection {
        case left
        case right
    }
    
    func rotate(_ direction: RotationalDirection) -> [Transformation] {
        var transformation: [TileTransformation] = []
        var allTransformations: [Transformation] = []
        var intermediateTiles: [[Tile]] = []
        let numCols = boardSize - 1
        let inputType: InputType
        switch direction {
        case .left:
            for colIdx in 0..<boardSize {
                var column : [Tile] = []
                for rowIdx in 0..<boardSize {
                    let endRow = colIdx
                    let endCol = numCols - rowIdx
                    
                    column.insert(tiles[rowIdx][colIdx], at: 0)
                    
                    //Create a TileTransformation object, the Renderer will use this to animate the changes
                    let trans = TileTransformation(TileCoord(rowIdx, colIdx),
                                                   TileCoord(endRow, endCol))
                    transformation.append(trans)
                }
                intermediateTiles.append(column)
            }
            inputType = .rotateCounterClockwise
        case .right:
            for colIdx in (0..<boardSize).reversed() {
                var column : [Tile] = []
                for rowIdx in 0..<boardSize {
                    let endRow = numCols - colIdx
                    let endCol = rowIdx
                    column.append(tiles[rowIdx][colIdx])
                    let trans = TileTransformation(TileCoord(rowIdx, colIdx),
                                                   TileCoord(endRow, endCol))
                    transformation.append(trans)
                }
                intermediateTiles.append(column)
            }
            inputType = .rotateClockwise
        }
        
        allTransformations.append(Transformation(transformation: [transformation],
                                                 inputType: inputType,
                                                 endTiles: intermediateTiles))
        
        if typeCount(for: self.tiles, of: .empty).count > 0 {
            // store tile transforamtions and shift information
            var newTiles : [TileTransformation] = []
            var (shiftDown, shiftIndices) = calculateShiftIndices(for: &intermediateTiles)
            
            //add new tiles
            addNewTiles(shiftIndices: shiftIndices,
                        shiftDown: &shiftDown,
                        newTiles: &newTiles,
                        intermediateTiles: &intermediateTiles)
            
            // return our new board
            
            allTransformations.append(Transformation(transformation: [newTiles, shiftDown],
                                           inputType: inputType,
                                           endTiles: intermediateTiles))
        }
        
        
        self.tiles = intermediateTiles
        
        return allTransformations
    }
}

// MARK: - CustomDebugStringConvertible

extension Board : CustomDebugStringConvertible {
    var debugDescription: String {
        var outs = "\ntop (of Tiles)"
        for tile in tiles.reversed() {
            outs += "\n\(tile)"
        }
        outs += "\nbottom"
        return outs
    }
    
}


extension Board {
    func gameWin() -> Transformation {
        guard let playerPosition = getTileStructPosition(TileType.player(.zero)),
            isWithinBounds(playerPosition.rowBelow) else {
                return Transformation(transformation: [], inputType: .gameWin)
        }
        if level.type == .tutorial1 || level.type == .tutorial2 {
            return Transformation(transformation: [], inputType: .gameWin)
        }
        
        return Transformation(transformation: [[TileTransformation(playerPosition, playerPosition.rowBelow)]],
                              inputType: .gameWin,
                              endTiles: tiles)
    }
}

// MARK - Tile counts

extension Board {
    func tiles(of type: TileType) -> [TileCoord] {
        var tileCoords: [TileCoord] = []
        for (i, _) in tiles.enumerated() {
            for (j, _) in tiles[i].enumerated() {
                tiles[i][j].type == type ? tileCoords.append(TileCoord(i, j)) : ()
            }
        }
        return tileCoords
    }
}


// MARK: - Combat
extension Board {
    
    func attack(_ input: Input) -> Transformation {
        guard case InputType.attack(_,
                                    let attackerPosition,
                                    let defenderPostion,
                                    _) = input.type else {
                                        return Transformation.zero
        }
        var attacker: EntityModel
        var defender: EntityModel
        
        
        //TODO: DRY, extract and shorten this code
        if let defenderPosition = defenderPostion,
            case let .player(playerModel) = tiles[attackerPosition].type,
            case let .monster(monsterModel) = tiles[defenderPosition].type,
            let relativeAttackDirection = defenderPosition.direction(relative: attackerPosition) {
            
            attacker = playerModel
            defender = monsterModel
            
            let (newAttackerData, newDefenderData) = CombatSimulator.simulate(attacker: attacker,
                                                                              defender: defender,
                                                                              attacked: relativeAttackDirection)
            
            tiles[attackerPosition.x][attackerPosition.y] = Tile(type: TileType.player(newAttackerData))
            tiles[defenderPosition.x][defenderPosition.y] = Tile(type: TileType.monster(newDefenderData))
            
        } else if let defenderPosition = defenderPostion,
            case let .player(playerModel) = tiles[defenderPosition].type,
            case let .monster(monsterModel) = tiles[attackerPosition].type,
            let relativeAttackDirection = defenderPosition.direction(relative: attackerPosition) {
            
            attacker = monsterModel
            defender = playerModel
            
            let (newAttackerData, newDefenderData) = CombatSimulator.simulate(attacker: attacker,
                                                                              defender: defender,
                                                                              attacked: relativeAttackDirection)
            
            tiles[attackerPosition.x][attackerPosition.y] = Tile(type: TileType.monster(newAttackerData))
            tiles[defenderPosition.x][defenderPosition.y] = Tile(type: TileType.player(newDefenderData))
        } else if case let .player(playerModel) = tiles[attackerPosition].type,
            defenderPostion == nil {
            //just note that the player attacked
            tiles[attackerPosition.x][attackerPosition.y] = Tile(type: TileType.player(playerModel.didAttack()))
            
        } else if case let .monster(monsterModel) = tiles[attackerPosition].type,
            defenderPostion == nil {
            //just note that the monster attacked
            tiles[attackerPosition.x][attackerPosition.y] = Tile(type: TileType.monster(monsterModel.didAttack()))
        }
        
        
        return Transformation(inputType: input.type,
                              endTiles: tiles)
    }
}
