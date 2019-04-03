//
//  RefereeTests.swift
//  DownFallTests
//
//  Created by William Katz on 12/29/18.
//  Copyright © 2018 William Katz LLC. All rights reserved.
//

import XCTest
@testable import DownFall

class RefereeTests: XCTestCase {
    
    let mockBoard = Board.build(size: 10)
    var allBlack: Builder!
    var allGreen: Builder!
    var player: Builder!
    var exit: Builder!
    
    override func setUp() {
        super.setUp()
        
        allBlack = all(.blackRock, mockBoard)
        allGreen = all(.greenRock, mockBoard)
        player = xTiles(1, .player(), mockBoard)
        exit = xTiles(1, .exit, mockBoard)
    }
    
    func testRefereeGameWin() {
        
        //same for all tests in this function
        let expectedOutput = Input(.gameWin)
        
        let gameWin = allBlack >>> win(mockBoard)
        let gameBoard = gameWin(mockBoard)
        let actualOutput = Referee.enforceRules(gameBoard.tiles)
        XCTAssertEqual(expectedOutput, actualOutput)
        
        
        let gameWin2 = (allGreen >>> player) >>> win(mockBoard)
        let gameBoard2 = gameWin2(mockBoard)
        let actualOutput2 = Referee.enforceRules(gameBoard2.tiles)
        XCTAssertEqual(expectedOutput, actualOutput2)

        let gameWin3 = (allGreen >>> exit) >>> win(mockBoard)
        let gameBoard3 = gameWin3(mockBoard)
        let actualOutput3 = Referee.enforceRules(gameBoard3.tiles)
        XCTAssertEqual(expectedOutput, actualOutput3)
    }
    
    
    func testRefereeGameLoses() {
        
        let gameLose = lose(mockBoard)
        let gameBoard = gameLose(mockBoard)
        
        let expectedOutput = Input(.gameLose)
        let actualOutput = Referee.enforceRules(gameBoard.tiles)
        
        XCTAssertEqual(expectedOutput, actualOutput)
        
        var board = Board(tiles: [[.greenRock, .blueRock, .blueRock],
                 [.blueRock, .blackRock, .exit],
                 [.greenRock, .player(), .greenRock]])
        
        let actualOutput2 = Referee.enforceRules(board.tiles)
        
        XCTAssertEqual(expectedOutput, actualOutput2)
        
        
        board = Board(tiles: [[.greenRock, .blueRock, .blueRock, .greenRock],
                 [.blueRock, .blackRock, .exit, .greenRock],
                 [.greenRock, .player(), .blueRock, .blackRock],
                 [.blueRock, .blackRock, .greenRock, .greenRock]])
        
        let actualOutput3 = Referee.enforceRules(board.tiles)
        
        XCTAssertEqual(expectedOutput, actualOutput3)
    }
    
    func testRefereeNonGameLose() {
        
        let gameLose = Input(.gameLose)
        // If the player can attack we dont lose (yet)
        var tiles = [[TileType.greenRock, .blueRock, .blueRock, .greenRock],
                     [.blueRock, .greenMonster(CombatTileData.monster()), .exit, .greenRock],
                     [.greenRock, .player(), .blueRock, .blackRock],
                     [.blueRock, .blackRock, .greenRock, .greenRock]]
        var actualOutput = Referee.enforceRules(tiles)
        
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can attack, we don't lose")
        
        //the player can rotate once to win, this is not a lose
        tiles = [[.greenRock, .blueRock, .blueRock, .greenRock],
                 [.blueRock, .blackRock, .blackRock, .greenRock],
                 [.greenRock, .player(), .exit, .blackRock],
                 [.blueRock, .blackRock, .greenRock, .greenRock]]
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can rotate to win, we don't lose")
        
        //the player can rotate twice to win, this is not a lose
        tiles = [[.greenRock, .blueRock, .blueRock, .greenRock],
                 [.blueRock, .blackRock, .blackRock, .greenRock],
                 [.greenRock, .player(), .blueRock, .blackRock],
                 [.blueRock, .exit, .greenRock, .greenRock]]
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can rotate to win, we don't lose")
        
        //the player can rotate to win once to win, this is not a lose
        tiles = [[.greenRock, .blueRock, .blueRock, .greenRock],
                 [.blueRock, .blackRock, .blackRock, .greenRock],
                 [.exit, .player(), .blueRock, .blackRock],
                 [.blueRock, .blueRock, .greenRock, .greenRock]]
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can rotate to win, we don't lose")
        
        //the player can rotate to kill a monster
        tiles = [[.greenRock, .blueRock, .blueRock, .exit],
                 [.blueRock, .blackRock, .blackRock, .greenRock],
                 [.greenRock, .player(), .greenMonster(), .blackRock],
                 [.blueRock, .blueRock, .greenRock, .greenRock]]
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can rotate to attack, we don't lose")
        
        //the player can rotate to kill a monster
        tiles = [[.greenRock, .blueRock, .blueRock, .exit],
                 [.blueRock, .blackRock, .blackRock, .greenRock],
                 [.greenRock, .player(), .blueRock, .blackRock],
                 [.blueRock, .greenMonster(), .greenRock, .greenRock]]
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can rotate to attack, we don't lose")
        
        //the player can rotate to kill a monster
        tiles = [[.greenRock, .blueRock, .blueRock, .exit],
                 [.blueRock, .blackRock, .blackRock, .greenRock],
                 [.greenMonster(), .player(), .blueRock, .blackRock],
                 [.blueRock, .blueRock, .greenRock, .greenRock]]
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(actualOutput, gameLose, "If the player can rotate to attack, we don't lose")

        
    }

    func testRefereePlayerAttacks() {
        var tiles = [[.blueRock, .greenMonster(), .blueRock, .blueRock],
                     [.blackRock, TileType.player(), .exit, .blueRock],
                     [.blackRock, .greenRock, .greenRock, .greenRock]]
        var expectedOutput = Input(.attack(TileCoord(1, 1), TileCoord(0, 1)))
        let actualOutput = Referee.enforceRules(tiles)
        XCTAssertEqual(expectedOutput, actualOutput)
        
        tiles = [[.blackRock, .blueRock, .blueRock],
                 [.exit, .blueRock, .greenMonster(CombatTileData(hp:1, attacksThisTurn: 0, weapon: .mouth))],
                 [.greenRock, .greenRock, .player()]]
        expectedOutput = Input(.attack(TileCoord(2, 2), TileCoord(1, 2)))
        let actualOutput2 = Referee.enforceRules(tiles)
        XCTAssertEqual(expectedOutput, actualOutput2)

    }

    func testRefereeMonsterAttacks() {
        var tiles = [[TileType.player(), .blueRock, .blueRock],
                     [.pickAxeMonster, .exit, .blueRock],
                     [.blueRock, .blueRock, .greenRock]]
        var expectedOutput = Input(.attack(TileCoord(1, 0), TileCoord(0, 0)))
        var actualOutput = Referee.enforceRules(tiles)
        XCTAssertEqual(expectedOutput, actualOutput, "Pick axe monsters attack down")
        
        tiles = [[TileType.blueRock, .blueRock, .blueRock],
                 [.pickAxeMonster, .exit, .player()],
                 [.greenRock, .greenRock, .pickAxeMonster]]
        expectedOutput = Input(.attack(TileCoord(2, 2), TileCoord(1, 2)))
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertEqual(expectedOutput, actualOutput, "Pick axe monsters attack down")
        
        tiles = [[TileType.exit, .blueRock, .blueRock],
                 [.mouthyMonster, .player(), .blueRock],
                 [.greenRock, .greenRock, .greenRock]]
        expectedOutput = Input(.attack(TileCoord(1, 0), TileCoord(1, 1)))
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertEqual(expectedOutput, actualOutput, "Mouthy monsters attacked things on it's sides")
        
        tiles = [[TileType.exit, .blueRock, .blueRock],
                 [.greenRock, .greenRock, .greenRock],
                 [.player(), .mouthyMonster, .blueRock]]
        expectedOutput = Input(.attack(TileCoord(2, 1), TileCoord(2, 0)))
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertEqual(expectedOutput, actualOutput, "Mouthy monsters attacked things on it's sides")

        
        // The following do not trigger attacks seeing as they are mouthy monsters
        tiles = [[TileType.player(), .blueRock, .blueRock],
                     [.mouthyMonster, .exit, .blueRock],
                     [.greenRock, .greenRock, .greenRock]]
        expectedOutput = Input(.attack(TileCoord(1, 0), TileCoord(0, 0)))
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(expectedOutput, actualOutput, "Mouthy monsters attacked things on it's sides")

        tiles = [[.blackRock, .blueRock, .blueRock],
                 [.exit, .blueRock, .player()],
                 [.greenRock, .greenRock, .mouthyMonster]]
        expectedOutput = Input(.attack(TileCoord(2, 2), TileCoord(1, 2)))
        actualOutput = Referee.enforceRules(tiles)
        XCTAssertNotEqual(expectedOutput, actualOutput, "Mouthy monsters attacked things on it's sides")
    }
    
    func testRefereeMonsterDies() {
        let dyingMonster = TileType.greenMonster(CombatTileData(hp: 0, attacksThisTurn: 0, weapon: .mouth))
        
        var tiles = [[TileType.greenRock, .blueRock, .greenRock, .greenRock],
                     [.blueRock, dyingMonster, .exit, .greenRock],
                     [.greenRock, .player(), .blueRock, .blackRock],
                     [.blueRock, .blackRock, .greenRock, .greenRock]]
        var expected = Input(.monsterDies(TileCoord(1, 1)))
        var actual = Referee.enforceRules(tiles)
        
        XCTAssertEqual(expected, actual, "Monster dies when hp reaches 0")
        
        tiles = [[.greenRock, .blueRock, .greenRock, .greenRock],
                 [.blueRock, dyingMonster, .exit, .greenRock],
                 [.greenRock, .player(), .blueRock, .blackRock],
                 [.blueRock, .blackRock, dyingMonster, .greenRock]]
        expected = Input(.monsterDies(TileCoord(1, 1)))
        actual = Referee.enforceRules(tiles)
        
        XCTAssertEqual(expected, actual, "Only one monster can die at a time")
    }
}