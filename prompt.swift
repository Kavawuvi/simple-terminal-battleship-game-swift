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

// Ask for an integer
func promptForInt(prompt : String, defaultValue : Int) -> Int {
    while true {
        print(prompt, terminator:"")
        if let line = readLine() {
            if line == "" {
                return defaultValue
            }
            else if let v = Int(line) {
                return v
            }
            else {
                print("A number was expected")
            }
        }
        else {
            return defaultValue
        }
    }
}

// Ask for a positive integer
func promptForPositiveInt(prompt : String, defaultValue : Int) -> Int {
    while true {
        let v = promptForInt(prompt:prompt, defaultValue:defaultValue)
        if v > 0 {
            return v
        }
        else {
            print("A positive number (i.e. 1 or higher) was expected")
        }
    }
}

// Ask for a yes or no response
func promptForYesNo(prompt : String, defaultValue : Bool) -> Bool {
    while true {
        print(prompt, terminator:"")
        if let line = readLine() {
            if line == "" {
                return defaultValue
            }
            else if line.lowercased() == "y" {
                return true
            }
            else if line.lowercased() == "n" {
                return false
            }
            else {
                print("Expected y or n")
            }
        }
        else {
            return defaultValue
        }
    }
}

// Get coordinates
func promptForCoordinates(prompt : String, defaultValue : [Int]) -> [Int] {
    while true {
        print(prompt, terminator:"")

        // Get the coordinates from the player and make them lowercase
        let line = readLine()!.lowercased()
        if line == "" {
            print("Auto-targeting \(coordinatesToString(defaultValue))")
            return defaultValue
        }

        // Make sure it's long enough
        if line.count < 2 {
            print("You need to enter valid coordinates (must be at least two characters)")
            continue
        }

        // Get the letter
        let letter = line[line.startIndex]
        if !letter.isLetter {
            print("You need to enter valid coordinates (must start with a letter)")
            continue
        }
        
        // Convert the letter to a coordinate (simply subtract from "a"'s ASCII value)
        let firstCoordinate = Int(letter.asciiValue! - Character("a").asciiValue!)

        // And the number
        if let number = Int(line[line.index(line.startIndex, offsetBy: 1)...]) {
            return [firstCoordinate, number - 1]
        }
        else {
            print("You need to enter valid coordinates (must end with a number)")
            continue
        }
    }
}

// Convert to string
func coordinatesToString(_ coordinates : [Int]) -> String {
    return "\(UnicodeScalar(65 + coordinates[0])!)\(coordinates[1] + 1)"
}
