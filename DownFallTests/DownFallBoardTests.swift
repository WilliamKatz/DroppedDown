//
//  DownFallTests.swift
//  DownFallTests
//
//  Created by William Katz on 5/9/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

import XCTest
@testable import DownFall

/* Example board
                                (0,0)   (0,1)   (0,2)
 let tiles: [[MockTile]] = [[.player2, .exit, .blueRock],
 
                                (1,0)       (1,1)       (1,2)
                            [.greenRock, .blueRock, .blackRock],
 
                                (2,0)       (2,1)       (2,2)
                            [.blueRock, .greenRock, .blueRock]]
 
 
 */

struct MockBoardHelper {
    private static func row(of type: TileType = .greenRock, by size: Int = 5) -> [TileType] {
        return Array(repeating: type, count: size)
    }
    
    static func createBoard(_ type: TileType = .greenRock, size: Int = 5) -> Board {
        return Board.init(tiles: Array(repeating: row(of: type, by: size), count: size))
    }
    
    static func createBoardWithRowOfSameColor(_ type: TileType = .greenRock, size: Int = 5, rowIdx: Int = 0) -> Board {
        var tiles = createBoard(.exit, size: size).tiles
        for col in 0..<size {
            tiles[rowIdx][col] = type
        }
        return Board.init(tiles: tiles)
    }
}

class DownFallTests: XCTestCase {
    
    var tiles: [[TileType]]!
    var board: Board!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.tiles = [[TileType.player(), .exit, .blueRock],
                  [.blueRock, .blueRock, .blueRock],
                  [.blueRock, .blueRock, .blueRock]]
        self.board = Board.init(tiles: tiles,
                                playerPosition: TileCoord(0,0),
                                exitPosition: TileCoord(0,1))
    }
    
    func testValidNeighbors() {
        
        //surrounded by 8
        var neighborTileCoord = TileCoord(0, 1)
        var currTileCoord = TileCoord(1,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(1, 2)
        currTileCoord = TileCoord(1,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(2, 1)
        currTileCoord = TileCoord(1,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(1, 0)
        currTileCoord = TileCoord(1,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        
        // surrounded by 5
        neighborTileCoord = TileCoord(0, 0)
        currTileCoord = TileCoord(0,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(0, 2)
        currTileCoord = TileCoord(0,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(1, 1)
        currTileCoord = TileCoord(0,1)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        
        //surround by three
        
        neighborTileCoord = TileCoord(0, 1)
        currTileCoord = TileCoord(0,0)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(1, 0)
        currTileCoord = TileCoord(0,0)
        XCTAssertTrue(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
    }
    
    func testNotValidNeighbors() {
        
        // surrounded by 8, NW, NE, SW, SE are not valid neighbors
        var neighborTileCoord = TileCoord(0, 0)
        var currTileCoord = TileCoord(1,1)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(0, 2)
        currTileCoord = TileCoord(1,1)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(2, 0)
        currTileCoord = TileCoord(1,1)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(2, 2)
        currTileCoord = TileCoord(1,1)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        
        // surrounded by 5, NW and SW or NE and SE or NW and NE or SW and SE are not neighbors
        neighborTileCoord = TileCoord(1, 0)
        currTileCoord = TileCoord(0,1)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(1, 2)
        currTileCoord = TileCoord(0,1)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        
        //surround by three NW, NE, SW, or  SE is not a neighbor
        
        neighborTileCoord = TileCoord(1, 1)
        currTileCoord = TileCoord(0,0)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        
        // all non-adjacent tiles are not neighbors
        
        neighborTileCoord = TileCoord(2, 2)
        currTileCoord = TileCoord(0,0)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(1, 2)
        currTileCoord = TileCoord(0,0)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(2, 0)
        currTileCoord = TileCoord(0,0)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(2, 1)
        currTileCoord = TileCoord(0,0)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))
        
        neighborTileCoord = TileCoord(0, 2)
        currTileCoord = TileCoord(0,0)
        XCTAssertFalse(board.valid(neighbor: neighborTileCoord, for: currTileCoord))


    }


    func testFindNeighbors () {
        let expectedNeighbors: [TileCoord] = [(0,2), (1,2), (2,2), (1,1), (1,0), (2,0), (2,1)].map { TileCoord($0.0, $0.1) }
        let actualNeighbors = board.findNeighbors(1, 1)
        XCTAssertEqual(Set(actualNeighbors), Set(expectedNeighbors), "Neighbors found do not match")
        
    }
    
    func testFindNoNeighbots() {
        let tiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                                   [.blackRock, .greenRock, .blackRock],
                                   [.blueRock, .blackRock, .blueRock]]
        
        let board = Board.init(tiles: tiles,
                               playerPosition: TileCoord(0,0),
                               exitPosition: TileCoord(0,1))
        let actualFoundNeighbors = board.findNeighbors(1,1)
        XCTAssertTrue(actualFoundNeighbors.count == 1, "No neighbors found, inital and after board should be equal")
    }
    
    func testInvalidInputFindNeighbors() {
        let actualFoundNeighbors = board.findNeighbors(-1,-1)
        XCTAssertTrue(actualFoundNeighbors.isEmpty, "Invalid input, inital and after board should be equal")
    }
    
    func testRotateLeft() {
        
        let tiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                                   [.greenRock, .blueRock, .blackRock],
                                   [.blueRock, .greenRock, .blueRock]]
        
        let rotatedTiles: [[TileType]] = [[.blueRock, .greenRock, TileType.player()],
                                          [.greenRock, .blueRock, .exit],
                                          [.blueRock, .blackRock, .blueRock]]
        
        let initalBoard = Board.init(tiles: tiles,
                                     playerPosition: TileCoord(0,0),
                                     exitPosition: TileCoord(0,1))
        
        let expectedRotatedBoard = Board.init(tiles: rotatedTiles,
                                              playerPosition: TileCoord(0,2),
                                              exitPosition: TileCoord(1,2))
        
        let acutalRotatedBoard = initalBoard.rotate(.left).endBoard
        XCTAssert(acutalRotatedBoard == expectedRotatedBoard, "Inital board should match expected result board after 90 degree rotate left")
        
        
    }
    
    func testRotateRight() {
        let tiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                                   [.greenRock, .blueRock, .blackRock],
                                   [.blueRock, .greenRock, .blueRock]]
        
        let rotatedTiles: [[TileType]] = [[.blueRock, .blackRock, .blueRock],
                                          [.exit, .blueRock, .greenRock],
                                          [TileType.player(), .greenRock, .blueRock]]
        
        let initalBoard = Board.init(tiles: tiles,
                                     playerPosition: TileCoord(0,0),
                                     exitPosition: TileCoord(0,1))
        
        let expectedRotatedBoard = Board.init(tiles: rotatedTiles,
                                              playerPosition: TileCoord(2,0),
                                              exitPosition: TileCoord(1,0))
        
        let acutalRotatedBoard = initalBoard.rotate(.right).endBoard
        XCTAssert(acutalRotatedBoard == expectedRotatedBoard, "Inital board should match expected result board after 90 degree rotate right")
    }
    
    func testTapPlayerDoesNotResultTransformation() {
        let expectedBoard = board
        let actualBoard = board.handle(input: Input.touch(TileCoord(0,0)))?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Tapping player should not result in a board transformation")
    }
    
    func testTapExitDoesNotResultTransformation() {
        let expectedBoard = board
        let actualBoard = board.handle(input: Input.touch(TileCoord(0,1)))?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Tapping exit should not result in a board transformation")
    }
    
    //TODO: tap monster does not result in transformation
    
    
    func testBoardNonValidPlayerAttack() {
        let givenTiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                      [.greenMonster(CombatTileData(hp: 1, attackDamage: 1)), .blueRock, .blueRock],
                      [.blueRock, .blueRock, .blueRock]]
        
        let expectedTiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                                           [.greenMonster(CombatTileData(hp: 1, attackDamage: 1)), .blueRock, .blueRock],
                                           [.blueRock, .blueRock, .blueRock]]
        let expectedBoard = Board.init(tiles: expectedTiles, playerPosition: TileCoord(0, 0), exitPosition: TileCoord(0,1))
        let actualBoard = Board.init(tiles: givenTiles, playerPosition: TileCoord(0, 0), exitPosition: TileCoord(0,1)).handle(input: Input.playerAttack)?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Board doesnt change when player attacks non-attackable thing.")

    }
    
    func testBoardComputesValidPlayerAttackVariableDamage() {
        let player1 = TileType.player()
        let player2 = TileType.player(CombatTileData(hp: 3, attackDamage: 3))
        
        
        var givenTiles: [[TileType]] = [[.blueRock, .exit, .blueRock],
                                        [.greenMonster(CombatTileData(hp: 3, attackDamage: 1)), .blueRock, .blueRock],
                                        [player1, .blueRock, .blueRock]]
        
        var expectedTiles: [[TileType]] = [[.blueRock, .exit, .blueRock],
                                           [.greenMonster(CombatTileData(hp: 2, attackDamage: 1)), .blueRock, .blueRock],
                                           [player1, .blueRock, .blueRock]]
        var expectedBoard = Board.init(tiles: expectedTiles)
        var actualBoard = Board.init(tiles: givenTiles).handle(input: Input.playerAttack)?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Board removes HP from tiles beneath the player equal to the palyer attack damage.")
        
        givenTiles = [[.blueRock, .exit, .blueRock],
                      [.greenMonster(CombatTileData(hp: 5, attackDamage: 1)), .blueRock, .blueRock],
                      [player2, .blueRock, .blueRock]]
        
        expectedTiles = [[.blueRock, .exit, .blueRock],
                         [.greenMonster(CombatTileData(hp: 2, attackDamage: 1)), .blueRock, .blueRock],
                         [player2, .blueRock, .blueRock]]
        
        let expectedBoard1 = Board.init(tiles: expectedTiles)
        let actualBoard1 = Board.init(tiles: givenTiles).handle(input: Input.playerAttack)?.endBoard
        XCTAssertEqual(expectedBoard1, actualBoard1, "Board removes HP from tiles beneath the palyer equal to the palyer attack damage.")
        
        
        givenTiles = [[.blueRock, .exit, .blueRock],
                      [.greenMonster(CombatTileData(hp: 1, attackDamage: 1)), .blueRock, .blueRock],
                      [player2, .blueRock, .blueRock]]
        
        expectedTiles = [[.blueRock, .exit, .blueRock],
                         [.greenMonster(CombatTileData(hp: -2, attackDamage: 1)), .blueRock, .blueRock],
                         [player2, .blueRock, .blueRock]]
        
        expectedBoard = Board.init(tiles: expectedTiles)
        actualBoard = Board.init(tiles: givenTiles).handle(input: Input.playerAttack)?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Board subtracts HP from tile's hp located beneath the player equal to the player attack damage.")
        
        
        givenTiles = [[.blueRock, .exit, .blueRock],
                      [.greenMonster(CombatTileData(hp: 2, attackDamage: 1)), .blueRock, .blueRock],
                      [TileType.player(CombatTileData(hp: 3, attackDamage: 1)), .blueRock, .blueRock]]
        
        expectedTiles = [[.blueRock, .exit, .blueRock],
                         [.greenMonster(CombatTileData(hp: 1, attackDamage: 1)), .blueRock, .blueRock],
                         [TileType.player(CombatTileData(hp: 3, attackDamage: 1)), .blueRock, .blueRock]]
        
        expectedBoard = Board.init(tiles: expectedTiles)
        actualBoard = Board.init(tiles: givenTiles).handle(input: Input.playerAttack)?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Board subtracts HP from tile's hp located beneath the player equal to the player attack damage.")
    }
    
    func testBoardValidMonsters() {
        let monster = TileType.greenMonster(CombatTileData(hp: 1, attackDamage: 1))
        let givenTiles: [[TileType]] = [[TileType.player(CombatTileData(hp: 1, attackDamage: 1)), .exit, .blueRock],
                                        [monster, .blueRock, .blueRock],
                                        [.blueRock, .blueRock, .blueRock]]
        
        let expectedTiles: [[TileType]] = [[TileType.player(CombatTileData(hp: 0, attackDamage: 1)), .exit, .blueRock],
                                           [monster, .blueRock, .blueRock],
                                           [.blueRock, .blueRock, .blueRock]]
        let expectedBoard = Board.init(tiles: expectedTiles, playerPosition: TileCoord(0, 0), exitPosition: TileCoord(0,1))
        let actualBoard = Board.init(tiles: givenTiles, playerPosition: TileCoord(0, 0), exitPosition: TileCoord(0,1)).handle(input: Input.monsterAttack(TileCoord(1,0)))?.endBoard
        XCTAssertEqual(expectedBoard, actualBoard, "Board applies Monster's attack damage to Player's hp.")
        
    }
    
    func testBoardDeterminesHowManyTilesAreEmpty() {
        var tiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                                   [.blackRock, .empty, .blackRock],
                                   [.blueRock, .empty, .blueRock]]
        
        var board = Board.init(tiles: tiles)
        XCTAssertEqual(board.tiles(of: .empty).count, 2, "Board can deteremine how many empty tiles it has")

        tiles = [[.empty, .empty, .empty],
                 [.empty, .empty, .empty],
                 [.empty, .empty, .empty]]
        board = Board.init(tiles: tiles)
        XCTAssertEqual(board.tiles(of: .empty).count, 9, "Board can deteremine how many empty tiles it has")
        
        tiles = [[.blackRock, .blackRock, .blackRock],
                 [.blackRock, .blackRock, .blackRock],
                 [.blackRock, .blackRock, .blackRock]]
        board = Board.init(tiles: tiles)
        XCTAssertEqual(board.tiles(of: .empty).count, 0, "Board can deteremine how many empty tiles it has")

    }
    
    func testBoardKnowsHowManyExitsThereAre() {
        var tiles: [[TileType]] = [[TileType.player(), .exit, .blueRock],
                                   [.blackRock, .empty, .blackRock],
                                   [.blueRock, .empty, .blueRock]]
        
        var board = Board.init(tiles: tiles)
        XCTAssertEqual(board.tiles(of: .exit).count, 1, "Board can deteremine how many exit tiles it has")
        
        tiles = [[.empty, .exit, .empty],
                 [.empty, .exit, .empty],
                 [.empty, .exit, .empty]]
        board = Board.init(tiles: tiles)
        XCTAssertEqual(board.tiles(of: .exit).count, 3, "Board can deteremine how many exit tiles it has")
        
        tiles = [[.exit, .exit, .exit],
                 [.exit, .exit, .exit],
                 [.exit, .exit, .exit]]
        board = Board.init(tiles: tiles)
        XCTAssertEqual(board.tiles(of: .exit).count, 9, "Board can deteremine how many exit tiles it has")
        
    }
    
    func arrayEquality(_ actual: [TileTransformation], _ expected: [TileTransformation] )  {
        for idx in 0..<actual.count {
            let actualStart = actual[idx].initial
            let actualEnd = actual[idx].end
            
            let expectedStart = expected[idx].initial
            let expectedEnd = expected[idx].end
            
            XCTAssertEqual(actualStart, expectedStart, "Actual and expected initial coords match")
            XCTAssertEqual(actualEnd, expectedEnd, "Actual and expected end coords match")
        }
    }
    
    func testBoardRemoveAndReplace() {
        let size = 5
        let board = MockBoardHelper.createBoard(size: size)
        
        var expectedTransformation: [TileTransformation] = []
        for colIdx in 0..<size{
            for rowIdx in size..<size+5 {
                let targetRow = rowIdx-size
                let trans = TileTransformation(TileCoord(rowIdx, colIdx), TileCoord(targetRow, colIdx))
                expectedTransformation.append(trans)
            }
        }
        
        let actualTransformation: [TileTransformation] = board.removeAndReplace(TileCoord(0,0)).tileTransformation![2]
        
        XCTAssertEqual(expectedTransformation.count, actualTransformation.count, "Shift down transformations should be the same")
        
        arrayEquality(actualTransformation, expectedTransformation)
        
    }
    
    func testRemoveFirstRow() {
        let size = 3
        let board = MockBoardHelper.createBoardWithRowOfSameColor(.blackRock, size: size, rowIdx: 0)
        
        var expectedTransformation: [TileTransformation] = []
        for colIdx in 0..<size{
            for rowIdx in 1..<size {
                let targetRow = rowIdx-1
                let trans = TileTransformation(TileCoord(rowIdx, colIdx), TileCoord(targetRow, colIdx))
                expectedTransformation.append(trans)
            }
        }
        for colIdx in 0..<size{
            for rowIdx in size..<size+1 {
                let targetRow = rowIdx-1
                let trans = TileTransformation(TileCoord(rowIdx, colIdx), TileCoord(targetRow, colIdx))
                expectedTransformation.append(trans)
            }
        }

        
        
        let actualTransformation = board.removeAndReplace(TileCoord(0,0)).tileTransformation![2]
        
        XCTAssertEqual(expectedTransformation.count, actualTransformation.count, "Shift down transformations should be the same")
        arrayEquality(actualTransformation, expectedTransformation)
        
    }
    
    func testBoardRemoveAndReplaceSingleTile() {
        let board = MockBoardHelper.createBoard(.greenRock, size: 3)
        
        let expectedTransformation = [TileTransformation.init(TileCoord(1, 1), TileCoord(0, 1)),
                                      TileTransformation.init(TileCoord(2, 1), TileCoord(1, 1)),
                                      TileTransformation.init(TileCoord(3, 1), TileCoord(2, 1))]
        
        
        let actualTransformation = board.removeAndReplace(TileCoord(0, 1), singleTile: true).tileTransformation![2]
        
        XCTAssertEqual(expectedTransformation.count, actualTransformation.count, "Shift down transformations should be the same")
        arrayEquality(actualTransformation, expectedTransformation)

    }
    
    func testvalidCardinalNeighbors() {
        let board = MockBoardHelper.createBoard(.greenRock, size: 3)
        
        // Test 1,1 has 4 neighbors
        var expectedNeighborsSet : Set<TileCoord> = [TileCoord(0, 1), TileCoord(1, 0), TileCoord(2, 1), TileCoord(1, 2)]
        var actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(1, 1)))
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        
        // Test 0,0 has 2 neighbors
        expectedNeighborsSet = [TileCoord(0, 1), TileCoord(1, 0)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(0, 0)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        
        // Test 2,0 has 2 neighbors
        expectedNeighborsSet = [TileCoord(1, 0), TileCoord(2, 1)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(2, 0)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        // Test 2,2 has 2 neighbors
        expectedNeighborsSet = [TileCoord(1, 2), TileCoord(2, 1)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(2, 2)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        // Test 0,2 has 2 neighbors
        expectedNeighborsSet = [TileCoord(0, 1), TileCoord(1, 2)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(0, 2)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        // Test 0,1 has 3 neighbors
        expectedNeighborsSet = [TileCoord(0, 0), TileCoord(1, 1), TileCoord(0, 2)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(0, 1)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        // Test 1,0 has 3 neighbors
        expectedNeighborsSet = [TileCoord(0, 0), TileCoord(1, 1), TileCoord(2, 0)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(1,0)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        // Test 2,1 has 3 neighbors
        expectedNeighborsSet = [TileCoord(2, 0), TileCoord(1, 1), TileCoord(2, 2)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(2, 1)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
        // Test 1,2 has 3 neighbors
        expectedNeighborsSet = [TileCoord(2, 2), TileCoord(1, 1), TileCoord(0, 2)]
        actualNeighborSet = Set(board.validCardinalNeighbors(of: TileCoord(1, 2)))
        
        XCTAssertEqual(expectedNeighborsSet, actualNeighborSet)
        
    }
}

