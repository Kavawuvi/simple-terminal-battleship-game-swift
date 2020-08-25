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

import Foundation

class Board {
    // Status of the board space
    enum PieceStatus {
        case Clear, Attacked
    }

    // Ship type (with methods for name and length)
    enum ShipType {
        case AircraftCarrier, Battleship, Submarine, Cruiser, Destroyer

        var length : Int {
            switch(self) {
            case ShipType.AircraftCarrier:
                return 5
            case ShipType.Battleship:
                return 4
            case ShipType.Submarine:
                return 3
            case ShipType.Cruiser:
                return 3
            case ShipType.Destroyer:
                return 2
            }
        }

        var name : String {
            switch(self) {
            case ShipType.AircraftCarrier:
                return "Aircraft Carrier"
            case ShipType.Battleship:
                return "Battleship"
            case ShipType.Submarine:
                return "Submarine"
            case ShipType.Cruiser:
                return "Cruiser"
            case ShipType.Destroyer:
                return "Destroyer"
            }
        }
    }

    enum ShipOrientation {
        case Horizontal, Vertical
    }

    class Ship : Equatable {
        private(set) var x = 0
        private(set) var y = 0
        private(set) var orientation = ShipOrientation.Horizontal
        private(set) var type = ShipType.Destroyer
        private(set) var board : Board? = nil

        static func ==(l: Ship, r: Ship) -> Bool {
            return (l === r) || (l.x == r.x && l.y == r.y && l.orientation == r.orientation && l.type == r.type && l.board === r.board)
        }

        // number of spaces that have not been attacked
        var health : Int {
            var health = type.length
            for i in board!.spacesOfShip(self) {
                if board!.statusOfPieceAtSpace(x:i[0], y:i[1])! == PieceStatus.Attacked {
                    health -= 1
                }
            }
            return health
        }

        init(x : Int, y : Int, orientation : ShipOrientation, type : ShipType, board : Board) {
            self.x = x
            self.y = y
            self.orientation = orientation
            self.type = type
            self.board = board
        }
    }

    private(set) var width = 0
    private(set) var height = 0
    private(set) var boardLayout : [PieceStatus] = []
    private(set) var ships : [Ship] = []

    // Get ships remaining
    var shipsRemaining : Int {
        var aliveShips = 0
        for i in ships {
            if i.health > 0 {
                aliveShips += 1
            }
        }
        return aliveShips
    }

    init(width : Int, height : Int) {
        // Initialize our dimensions
        self.width = width
        self.height = height

        // Initialize the actual board itself
        self.boardLayout = [PieceStatus](repeating: PieceStatus.Clear, count: width * height)
    }

    func spacesOfShip(_ ship : Ship) -> [[Int]] {
        // Get the number of pieces
        let pieceCount = ship.type.length

        // Work off of these
        let x = ship.x
        let y = ship.y

        // Initialize our pieces array all at once
        var pieces : [[Int]] = [[Int]](repeating: [x, y], count: pieceCount)

        // Iterate through all of the pieces
        for p in 0..<pieceCount {
            switch ship.orientation {
            case ShipOrientation.Horizontal:
                pieces[p][0] = x + p
                break
            case ShipOrientation.Vertical:
                pieces[p][1] = y + p
                break
            }
        }

        // Done
        return pieces
    }

    func statusOfPieceAtSpace(x : Int, y : Int) -> PieceStatus? {
        // Make sure it's within bounds
        if x >= 0 && x < width && y >= 0 && y < height {
            return boardLayout[x + y * width]
        }
        // If not, the piece is invalid
        else {
            return nil
        }
    }

    private func setStatusOfPieceAtSpace(x : Int, y : Int, toStatus : PieceStatus) {
        boardLayout[x + y * width] = toStatus
    }

    func canAddShip(_ ship : Ship) -> Bool {
        // Is it even on the same board?
        if ship.board !== self {
            return false
        }

        // Go through each space
        for s in spacesOfShip(ship) {
            // Make sure the piece is valid and it's unoccupied
            if statusOfPieceAtSpace(x:s[0], y:s[1]) == nil || shipAtSpace(x:s[0], y:s[1]) != nil {
                return false
            }
        }

        // By process of elimination, we can do it
        return true
    }

    func performHitAtSpace(x: Int, y : Int) -> Bool {
        // Make sure we can attack these
        if let status = statusOfPieceAtSpace(x:x, y:y) {
            if status == PieceStatus.Attacked {
                return false
            }
            else {
                setStatusOfPieceAtSpace(x:x, y:y, toStatus:PieceStatus.Attacked)
                return true
            }
        }
        else {
            return false
        }
    }

    func addShip(_ ship : Ship) -> Bool {
        // Check if we can add it. If so, append
        if canAddShip(ship) {
            ships.append(Ship.init(x:ship.x, y:ship.y, orientation:ship.orientation, type:ship.type, board:self))
            return true
        }
        else {
            return false
        }
    }

    func shipAtSpace(x : Int, y : Int) -> Ship? {
        ShipLoop: for ship in ships {
            // Are we behind the ship?
            if x < ship.x || y < ship.y {
                continue
            }

            // Are we aligned? If so, set the coordinate to check
            let coordinateToCheckFrom : Int
            let coordinateToCheckTo : Int

            switch ship.orientation {
            case ShipOrientation.Horizontal:
                if y != ship.y {
                    continue ShipLoop
                }
                coordinateToCheckFrom = ship.x
                coordinateToCheckTo = x
            case ShipOrientation.Vertical:
                if x != ship.x {
                    continue ShipLoop
                }
                coordinateToCheckFrom = ship.y
                coordinateToCheckTo = y
            }

            // If we're aligned and we're within the length of the ship, then this is a ship!
            if coordinateToCheckTo - coordinateToCheckFrom < ship.type.length {
                return ship
            }
        }

        return nil
    }

    func showBoard(radar : Bool) {
        // Top border
        print("╔", terminator:"")
        for _ in 0..<width {
            print("═══╤", terminator:"")
        }
        print("═══╗")

        // Label (top)
        print("║   ", terminator:"")
        for x in 0..<width {
            print("│ \(UnicodeScalar(65 + x)!) ", terminator:"")
        }
        print("║")

        func printRowBorder() {
            print("╟───", terminator:"")
            for _ in 0..<width {
                print("┼───", terminator:"")
            }
            print("╢")
        }

        // Draw each row
        for y in 0..<height {
            printRowBorder()
            let label = NSString(format:"%2i", y + 1)
            print("║\(label) ", terminator:"")
            for x in 0..<width {
                var characterToUse : Character = " "

                let status = statusOfPieceAtSpace(x:x, y:y)!
                let ship = shipAtSpace(x:x, y:y)
                let shipPresent = ship != nil
                let shipSunk = shipPresent && ship!.health == 0

                switch status {
                case PieceStatus.Clear:
                    characterToUse = radar && shipPresent ? "?" : " "
                    break
                case PieceStatus.Attacked:
                    characterToUse = shipPresent ? (shipSunk ? "S" : "H") : "M"
                    break
                }

                print("│ \(characterToUse) ", terminator:"")
            }
            print("║")
        }

        // Bottom border
        print("╚", terminator:"")
        for _ in 0..<width {
            print("═══╧", terminator:"")
        }
        print("═══╝")
    }
}
