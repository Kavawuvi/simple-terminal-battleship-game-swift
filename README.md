# Simple Terminal Battleship Game in Swift
This is a simple terminal-based Battleship game written in Swift.

Starting a game is simple:
- Input the board size
- Input the difficulty of the computer
    - **(0)** All shots are random
        - Does not consider any previous ships that have been hit
    - **(1)** All shots are random until a ship is found
        - Checks the board for unsunk ships that have been hit before searching
    - **(2)** All shots are random along a checkerboard until a ship is found
        - More efficient at locating ships than 1
        - Checkerboard pattern is randomized
- Randomize your board until you find a board you like
    - This will try to avoid placing ships next to other ships
    - TODO: Add an option to assemble your own board
- Choose whether you want to play with Salvo rules
    - With normal rules, you fire once per turn
    - With Salvo rules, you fire once per ship per turn
        - As you lose ships, you lose firepower, reducing the number of attacks
          per turn

These are the rules to Battleship:
- Each player takes turns attacking the other player
    - To attack, declare the coordinates you are attacking (e.g. B6). These
      coordinates must be within the board, and you must not have attacked there
      previously.
    - Each attack will give feedback:
        - **Miss**: Your attack did not land on any ship.
        - **Hit**: Your attack damaged a ship. The ship is not revealed, yet.
        - **Sink**: Your attack destroyed a ship. The ship is revealed.
- The game ends when a player's fleet is destroyed
