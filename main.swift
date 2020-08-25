// SPDX-License-Identifier: Apache-2.0

/*
 * Simple Terminal Battleship Game in Swift
 * Copyright 2020 Kavawuvi
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// These are the ships we will use
let shipsToAdd : [Board.ShipType] = [
    Board.ShipType.AircraftCarrier,
    Board.ShipType.Battleship,
    Board.ShipType.Cruiser,
    Board.ShipType.Submarine,
    Board.ShipType.Destroyer
]

// Get our width and height
var width = 0
var height = 0
while true {
    width = promptForPositiveInt(prompt: "Board width (10): ", defaultValue: 10)
    height = promptForPositiveInt(prompt: "Board height (10): ", defaultValue: 10)

    // Make sure we have at least 40 spaces
    if width * height < 40 {
        print("At least 40 spaces are needed; got \(width) x \(height) (= \(width*height) spaces)")
        continue
    }

    // Make sure the width and height aren't too high
    if width > 26 || height > 99 {
        print("The maximum dimensions is 26x99; got \(width) x \(height)")
    }

    break
}

// Get difficulty
var difficulty = 0
while true {
    difficulty = promptForPositiveInt(prompt: "Difficulty [0-2] (2): ", defaultValue: 2)
    if difficulty > 2 {
        print("Difficulty must be between 0 and 2")
        continue
    }
    break
}

// Randomize ships for the given board. This will try to avoid placing ships adjacent to other ships.
func randomizeShips(_ board : Board) {
    ShipLoop: for ship in shipsToAdd {
        var attempts = 0

        InnerShipLoop: while true {
            // Randomize it!
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let orientation = Bool.random() ? Board.ShipOrientation.Horizontal : Board.ShipOrientation.Vertical
            let ship = Board.Ship.init(x:x,y:y,orientation:orientation,type:ship,board:board)

            // Check if we can add it
            if !board.canAddShip(ship) {
                continue
            }

            // Make sure it isn't adjacent to any other ship. Do this check 1000 times and give up
            let spaces = board.spacesOfShip(ship)
            if attempts < 1000 {
                for s in spaces {
                    for y in s[1] - 1...s[1] + 1 {
                        for x in s[0] - 1...s[0] + 1 {
                            if board.shipAtSpace(x:x, y:y) != nil {
                                attempts += 1
                                continue InnerShipLoop
                            }
                        }
                    }
                }
            }

            // Add it
            if board.addShip(ship) {
                continue ShipLoop
            }
        }
    }
}

// Create a board for the enemy
let enemy = Board.init(width:width, height:height)
randomizeShips(enemy)

// Let the player re-roll boards until they're happy
let player : Board = { () -> Board in
    while true {
        let player = Board.init(width:width, height:height)
        randomizeShips(player)
        player.showBoard(radar:true)

        if promptForYesNo(prompt:"Use this board? (Y/n)", defaultValue:true) {
            return player
        }
    }
}()

// Play with Salvo rules
let salvo = promptForYesNo(prompt:"Play with Salvo rules? [1 shot per ship per turn] (Y/n) ", defaultValue:true)

var turnCount = 0

// Set our base odd number so the computer's checkerboard is less predictable
var oddNumber = Int.random(in:0...1)

// Set our preferred direction to something random, too, so it's less predictable
var preferredDirection = Int.random(in:0...1)

func gameIsNotOver() -> Bool {
    return player.shipsRemaining > 0 && enemy.shipsRemaining > 0
}

func performTurn(player : Bool, board : Board, enemyBoard : Board) {
    for _ in 1...3 {
        print("")
    }

    // Print the thing
    if player {
        print("It's your turn!")
    }
    else {
        print("It's the computer's turn!")
    }

    func getCoordinatesFromComputer(_ difficulty : Int) -> [Int] {
        func randomShot() -> [Int] {
            // At 2 difficulty, we're smarter and only target every other tile, making is more efficient
            if difficulty == 2 {
                // Get the row and set "odd" (0 or 1) since this lets us do checkerboarding
                let row = Int.random(in:0..<enemyBoard.height)
                let odd = (oddNumber + row) % 2

                // Get a random number between 0 and half of the width, multiply by 2, and add "odd"
                var column = Int.random(in:0..<enemyBoard.width / 2) * 2 + odd

                // If we got outside of the board, set to "odd" so we are inside
                if column >= enemyBoard.width {
                    column = odd
                }

                // Return it
                return [column,row]
            }
            else {
                // Return a completely random number
                return [Int.random(in:0..<enemyBoard.width),Int.random(in:0..<enemyBoard.height)]
            }
        }

        func successfulRandomShot() -> [Int] {
            while true {
                let shot = randomShot()
                if enemyBoard.statusOfPieceAtSpace(x:shot[0], y:shot[1])! == Board.PieceStatus.Clear {
                    return shot
                }
            }
        }

        // If difficulty is 1 or 2, see if we hit something. If so, follow along the path
        if difficulty == 1 || difficulty == 2 {
            for y in 0..<enemyBoard.height {
                for x in 0..<enemyBoard.width {
                    func hitButNotSunkAtPiece(x : Int, y : Int) -> Bool {
                        // Did we hit there (or is it even valid???)? If not, try the next one
                        if let status = enemyBoard.statusOfPieceAtSpace(x:x, y:y) {
                            if status == Board.PieceStatus.Clear {
                                return false
                            }
                        }
                        else {
                            return false
                        }

                        // Is there a ship there that isn't sunk?
                        if let ship = enemyBoard.shipAtSpace(x:x, y:y) {
                            if ship.health == 0 {
                                return false
                            }
                        }
                        else {
                            return false
                        }

                        return true
                    }

                    if !hitButNotSunkAtPiece(x:x,y:y) {
                        continue
                    }

                    // Check left-right for a space we can hit
                    func lookForSomethingHorizontal() -> [Int]? {
                        for x2 in x..<enemyBoard.width {
                            if hitButNotSunkAtPiece(x:x2,y:y) {
                                continue
                            }
                            if enemyBoard.statusOfPieceAtSpace(x:x2, y:y)! == Board.PieceStatus.Clear {
                                return [x2,y]
                            }
                            else {
                                break
                            }
                        }
                        for x2 in (0..<x).reversed() {
                            if hitButNotSunkAtPiece(x:x2,y:y) {
                                continue
                            }
                            if enemyBoard.statusOfPieceAtSpace(x:x2, y:y)! == Board.PieceStatus.Clear {
                                return [x2,y]
                            }
                            else {
                                break
                            }
                        }
                        return nil
                    }

                    // Check up-down for a space we can hit
                    func lookForSomethingVertical() -> [Int]? {
                        for y2 in y..<enemyBoard.height {
                            if hitButNotSunkAtPiece(x:x,y:y2) {
                                continue
                            }
                            if enemyBoard.statusOfPieceAtSpace(x:x, y:y2)! == Board.PieceStatus.Clear {
                                return [x,y2]
                            }
                            else {
                                break
                            }
                        }
                        for y2 in (0..<y).reversed() {
                            if hitButNotSunkAtPiece(x:x,y:y2) {
                                continue
                            }
                            if enemyBoard.statusOfPieceAtSpace(x:x, y:y2)! == Board.PieceStatus.Clear {
                                return [x,y2]
                            }
                            else {
                                break
                            }
                        }
                        return nil
                    }

                    // First, let's hint the direction we could take by checking adjacent spaces
                    var hintedDirection = preferredDirection

                    // Horizontal?
                    if hitButNotSunkAtPiece(x:x-1, y:y) || hitButNotSunkAtPiece(x:x+1, y:y) {
                        hintedDirection = 0
                    }
                    // Vertical?
                    else if hitButNotSunkAtPiece(x:x, y:y-1) || hitButNotSunkAtPiece(x:x, y:y+1) {
                        hintedDirection = 1
                    }

                    // We see something here. Let's try following along the path
                    if hintedDirection == 0 {
                        if let h = lookForSomethingHorizontal() {
                            return h
                        }
                        else if let v = lookForSomethingVertical() {
                            return v
                        }
                    }
                    else if hintedDirection == 1 {
                        if let v = lookForSomethingVertical() {
                            return v
                        }
                        else if let h = lookForSomethingHorizontal() {
                            return h
                        }
                    }

                    // In theory we should never get here.
                    print("FAIL (bug?)")
                    break
                }
            }
        }

        // If not or we're at 0 difficulty, take a random shot
        return successfulRandomShot()
    }

    func showEnemyBoard() {
        if player {
            print("[ENEMY BOARD]")
            enemyBoard.showBoard(radar:false)
        }
        else {
            print("[YOUR BOARD]")
            enemyBoard.showBoard(radar:true)
        }
    }

    var casualties : [Board.Ship] = []

    // Get the number of ships we have left. This is how many shots we have, unless we're not playing Salvo
    let fireCount = salvo ? board.shipsRemaining : 1
    for i in 1...fireCount {
        // If we're done, break
        if enemyBoard.shipsRemaining == 0 {
            break
        }

        // If we're the player, show the enemy board
        if player {
            showEnemyBoard()
        }
        print("Input coordinates to fire at (e.g. B6) or press enter to let the computer decide")

        // Ask for a coordinate
        while true {
            let prompt = "Shot \(i)/\(fireCount): "
            let shot = { () -> [Int] in
                let automatedCoordinates = getCoordinatesFromComputer(player ? 2 : difficulty)
                if player {
                    return promptForCoordinates(prompt:prompt, defaultValue:automatedCoordinates)
                }
                else {
                    print("\(prompt)\(coordinatesToString(automatedCoordinates))")
                    return automatedCoordinates
                }
            }()

            // Check if said coordinates are attacked
            if let status = enemyBoard.statusOfPieceAtSpace(x:shot[0], y:shot[1]) {
                if status == Board.PieceStatus.Attacked {
                    print("Those coordinates have already been attacked")
                    continue
                }
            }
            else {
                print("Coordinates given are outside of the board")
                continue
            }

            // Perform the hit
            if !enemyBoard.performHitAtSpace(x:shot[0], y:shot[1]) {
                print("Failed to attack the given coordinates")
                continue
            }

            // Check if there's a ship there
            if let ship = enemyBoard.shipAtSpace(x:shot[0], y:shot[1]) {
                if ship.health > 0 {
                    if player {
                        print("Hit")
                    }
                    else {
                        print("Player \(ship.type.name) damaged (\(ship.health)/\(ship.type.length) HP)")
                    }
                }
                else {
                    print("\(player ? "Enemy" : "Player") \(ship.type.name) destroyed")
                }
                if !casualties.contains(ship) {
                    casualties.append(ship)
                }
            }
            // If we're the player, do this
            else if player {
                print("Miss")
            }
            break
        }
    }

    showEnemyBoard()

    // Show casualties
    if casualties.count > 0 {
        print("Casualties")
        print("- Damage to ship(s)")
        var destructionCount = 0
        for ship in casualties {
            if ship.health > 0 {
                if !player {
                    print("- \(ship.type.name) damaged (\(ship.health)/\(ship.type.length) HP)")
                }
            }
            else {
                print("- \(ship.type.name) destroyed")
                destructionCount += 1
            }
        }
        if destructionCount > 0 && salvo {
            print("- Firepower reduced to \(enemyBoard.shipsRemaining)")
        }
    }
    else {
        print("No casualties")
    }

    // If the game is over, note that too
    if enemyBoard.shipsRemaining == 0 {
        if player {
            print("You win! Congratulations!")
        }
        else {
            print("Oh, dear! All of your ships have been destroyed!")
        }
    }

    print("Press enter to continue", terminator:"")
    let _ = readLine()
}

// Turn loop
while gameIsNotOver() {
    // The computer has a 50/50 chance of skipping their turn on the first turn
    if turnCount != 0 || Bool.random() {
        performTurn(player:false, board:enemy, enemyBoard:player)
    }

    // If the game isn't over, keep going
    if gameIsNotOver() {
        performTurn(player:true, board:player, enemyBoard:enemy)
    }

    turnCount += 1
}

print("Game over!")
