# Cinco Dados 🎲🎲🎲🎲🎲

## Statement of Purpose and Scope

"Cinco Dados" is Español for "Five Dice".  Five Dice is a dice game played with ... you guessed it ... five dice.  You probably know it by another name, which is a trademark, so I won't be using that name!

Cinco Dados is doing to be my take on this game and is dedicated to my partner Luis, who is Mexican, with whom i play it often in real life.  It can be played solo or with friends. The game involves rolling five dice to achieve certain combinations of matching or sequentially numbered dice, and strategically inserting those rolls into the available slots on the score card, to maximise your score. 

The application is intended to be used as entertainment, by anyone who enjoys casual games. Each game takes around 10-15 minutes to complete, per player.

The game will contain a visual representation of the dice, built from ASCII characters that can be displayed in a terminal. It is intended that navigation and command selection within the game screen will be via the arrow keys and the space/enter key, to control the movement and activation of a cursor.

The application will commence with a menu, where the number of players is established, and each player can enter their name.  Once this information is entered, the application will change to the main game screen.

On the main game screen is the score card table, showing the progress of each player and their scores for each of the dice combinations.

## List of Features

### 1. Main Menu

Initially upon executing the program, the user will be presented with a menu.  The menu will contain options to start a new game, or view the high scores table or quit.  Navigation of the menu options is via the arrow keys up/down, and pressing the Enter or Space key to activate the selected option.  After the completion of a game the player returns to the main menu. 

Upon selecting to start a new game, the player will be presented with a series of prompts to set up the game.  These prompts will supply the program with the information it needs to run the main game. The information to be entered includes the number of players, and the name of each player.

### 2. Game - Dice

During the main game, the five dice are rolled to try and generate the required combinations.  The dice will be represented visually, displayed as a grid of white blank chacters and black "pips" that can be represented in the terminal.  The action of dice rolling will be simulated by animating the dice faces, hopefully with a sequenced animation ending.

### 3. Game - Score Card

While the game is in progress, roughly half of the screen is taken up with the score card.  It displays the list of available dice combinations, and includes a score in those that have already had dice rolls allocated.  It calculates and displays the top half bonus, subtotals of the top and bottom halves, and the grand total. There is one column for every player, with their name or initials at the top. After completing their dice rolls, the player will use a cursor to navigate up and down their column to place their roll, with hypothetical score increments displayed in the affected cells.

### 4. High Score Table

After completing a game, the score of each player will be assessed to see if it is within the top 10 of all scores ever recorded. If so, the player's name and score will be added to the high score table and the table will be displayed.  The table will be stored persistenly on disk in json format or similar. The high score table can also be viewed at any time by accessing the option from the main menu.  

## Outline of User Interaction

### General Navigation and User Experience

Navigation throughout the game menus and main game screen is via a cursor, which moves between available controls. Controls may be graphical items (eg. dice, cells of the scorecard table) or text (eg. options in a menu). Different controls may be available depending on game logic at any stage of the application.  Once the intended control is highlighted by the cursor, it will highlight by displaying in a different colour or in reverse (will see how they look when implemented). In some situations the cursor may highlight a control in orange to warn that the consequence of that selection might not be what they player intends.

On most pages in the application an "instruction line" at the bottom of the screen will provide instructions on how to interact with the game at any stage, and will change with the context and game progression. In the case of any incorrect key press, the instruction line will temporarily show "Incorrect Key Press in red".

### 1. Main Menu

The instruction line will provide direction to the user about how to navigate the menu. For example "press the up ↑ or down ↓ keys to select an option and press enter ⏎ or spacebar to select that option".

At the top of each menu page will be a clear heading of the current menu, so that the user maintains awareness of their current position in the menu heirarchy.

Incorrect input in cursor navigation mode (pressing any non supported key) will be responded to on the information line with an error message such as "Incorrect Key press". Incorrect input in a text entry field (number of players or Player Name) will receive a similar message "Please enter a number only" or "Invalid character".

### 2. Game - Dice

The theme of arrow key based cursor movement will continue, where the user will move the cursor to select on screen commands to progress the game. The instruction line will provide players with help as above.  

Each turn of the game consists of three rolls; each is activated via a large "ROLL" button to be selected by the cursor. For the first roll no dice are initially displayed, and the instruction line will display "Select the ROLL button to roll the dice". When the dice are rolled, an animation process will show dice faces cycling and reveal the final position of each dice in sequence. 

Before the 2nd and 3rd roll, any of the dice can be locked so that they will not be affected by subsequent rolls. The instruction line will display a message to "press the up/down keys to select a dice and space to lock/unlock.  Select the ROLL button to roll the unlocked dice". A locked dice will have a visual indicator of a box around it so users can see when they have locked a dice. Incorrect key presses will be met with the same "Incorrect Key" notification as in the menu, with a lack of cursor movement. Once the required dice are locked, the player can select and activate the "ROLL" button to continue.

### 3. Game - Score Card

Arrow based cursor movement and command selection continues, maintaining continuity in the user experience.  After the three rolls of a turn are completed, the user will need to choose where on the score card to place their final roll.

The instruction line will display "Please select an open spot on your score card to place this roll, press the up/down keys to select and Enter/Space to confirm". The cursor will appear in the player's column of the score card, and the up and down arrows can be used to select available cells of the table.

Logic will prevent cells already containing a roll from being selected, and cursor selections which do not match the dice (resulting in 0 score) will be highlighed in orange when selected.  When the cursor highlights a cell which would result in a non-zero score it will be highlighted green.

The hypothetical score will display inside any selected cell, and to accept the selection the user can press the space bar or enter key.  If the player selects a zero scoring cell (ie they have no choice, or they are choosing to forego a score for strategic reasons) they will be prompted again with a message "Are you sure you want enter a score of 0 ?", and will need to press enter/space again to confirm.

### 4. Summary Page / High Score Table

After completing a game, some game summary information is displayed, and below this, the high score table. The user can also access the High Score Table directly from the main menu, in which case the summary information from the ending game is not displayed.

If the game was single player, the summary information contains the player's final score with a congratulatory message. If the game was multiplayer, then the players will be ranked and the winner declared.

The players who qualify for the high score will be notified they have achieved a high score.

The high score table is displayed underneath with the changes highlighted.

No user interaction is required, apart from acknowledgement and closing the page with the enter/space key.  The information line will display "Press Enter/Space to return to the main menu". Any other input will receive an "Incorrect Key" notification.

