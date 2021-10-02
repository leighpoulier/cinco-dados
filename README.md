# Cinco Dados 🎲🎲🎲🎲🎲

## Links

[Github repository](https://github.com/leighpoulier/cincodados)  
[Trello board](https://trello.com/b/uHqXtL1J/cinco-dados)

## Statement of Purpose and Scope

"Cinco Dados" is Español for "Five Dice".  Five Dice is a game of chance played with ... you guessed it ... five dice.  You probably know it by another name, which is a trademark, so I won't be using that name!

Cinco Dados is going to be my take on this game and is dedicated to my partner, who is Mexican, and with whom i play it often in real life.  It can be played solo or with friends. The game involves rolling five dice to achieve certain combinations of matching or sequentially numbered dice, and strategically inserting those rolls into the available slots on the score card, to maximise your score. 

The application is intended to fulfil social and entertainment needs, for anyone who enjoys casual games, whether solo or with friends. Each game takes around 10-15 minutes to complete, per player.

The application will commence with a main menu, from where a new game can be started.  Before the game a setup menu will gather setup information such as the number of players and their names.  Once this information is entered, the application will change to the main game screen.

The game will contain a visual representation of the dice, built from ASCII and Unicode box drawing characters that can be displayed in a terminal. It is intended that navigation and command selection within the game screen will be via the arrow keys and the space/enter key, to control the movement and activation of a visual cursor.  The cursor is used to select which dice to keep and which to roll during each turn.  After 3 turns the roll is over and the dice must be allocated to a free slot on the score card.  This process repeats over all the players until the score card is complete.

On the main game screen is the five visual dice, and the score card table showing the progress of each player and their scores for each of the dice combinations.

## List of Features

### 1. Cursor based navigation and control

Navigation throughout the application is intended to be accomplished solely with use of the arrow keys to select various on screen controls, such as buttons.  Once these controls are selected, the space bar or enter key can be used to activate the action that each control represents.  Controls can be simple buttons such as Yes/No/Exit or other controls such as the dice, or the individual table cells on the score card.  Using these controls instead of text input limits the need for input validation and provides a familiar-ish graphical user interface.

### 2. Game - Dice

During the main game, the five dice are "rolled" to generate the required combinations.  The dice will be represented visually, displayed as a grid of white blank chacters and black "pips" that can be represented in the terminal.  The values of the dice are generated from five seperate psuedo-random number generators; one for each dice. The action of dice rolling will be simulated by animating the dice in a sequence.  A locking function will be implemented, which enables the user to select which dice to roll again and which to keep, during the course of their 3 permitted rolls per turn

### 3. Game - Score Card

While the game is in progress, roughly half of the screen is taken up with the score card.  It displays the list of available score categories, and includes a score in those categories that have already had dice rolls allocated.  It calculates and displays the top half bonus, the subtotals of the top and bottom halves, and the grand total. There is one column for every player, with their name or initials at the top, highlighted when they are the current player. After completing their dice rolls, the player will use a cursor to navigate up and down their column to place their roll, with hypothetical score increments displayed in the affected cells.  Only cells which have not yet been allocated are selectable.

### 4. High Score Table

After completing a game, the score of each player will be assessed to see if it is within the top 10 of all scores ever recorded. If so, the player's name and score will be added to the high score table and the table will be displayed.  The table will be stored persistenly on disk in json format or similar. The high score table can also be viewed at any time by accessing the option from the main menu.

### 5. How to Play Screen

From the main menu the user can enter a screen of text describing how to play.  This screen contains multiple pages of text which can be navigated with "Next" and "Previous" buttons.

## Outline of User Interaction

### 1. General Navigation and User Experience

Navigation throughout the game menus and main game screen is via a cursor, which moves between available controls. Controls may be graphical items (eg. dice, cells of the scorecard table) or buttons (eg. options in a menu). Different controls may be available depending on game logic at any stage of the application.  Arrow keys are used to navigate the cursor between controls, and once the intended control is surrounded by the cursor, that control will highlight by displaying in a different colour. In some situations the cursor may highlight a control in orange to warn that the consequence of that selection might not be what they player intends.

On most pages in the application a line of context based help text at the bottom of the screen will provide instructions on how to interact with the game at any stage, and will change with the selected control and application navigation. For example "press the up ↑ or down ↓ keys to select an option and press enter ⏎ or spacebar to select".


### 1. Main Menu

Initially upon executing the program, the user will be presented with the main menu.  The menu will contain options such as start a new game, view the high scores table, view help information, or quit.  Navigation of the menu options is via the arrow keys up/down/left/right, and pressing the Enter or Space bar to activate the selected option.

Upon selecting to start a new game, the player will be presented with a series of prompts to set up the game.  These prompts will supply the program with the information it needs to run the main game. The information to be entered includes the number of players, and the name of each player.

At the top of each menu page will be a clear heading of the current menu, so that the user maintains awareness of their current position in the menu heirarchy.

At various times during the game confirmation of a user action is required.  This confirmation is dispayed in Yes/No type modal box overlaid on the current screen.  The user can use the arrow and enter/space to make their selection as above.

From the main menu, the user can also navigate to the "How to Play" screen. On this screen a similar concept is used to navigate through the pages of text, with the "Next" and "Previous" buttons.  Also available from the main menu is the "High Scores" screen, which displays a list of the 10 highest scores ever achieved.

Incorrect input in cursor navigation mode (pressing any non supported key) will be ignored and the visual cursor will not move.  The context help line at the bottom of the screen may display with an error message such as "Unable to move". Incorrect input in a text entry field (number of players or Player Name) will receive a similar message "Please enter a number only" or "Invalid character".

### 2. Game - Dice

The theme of arrow key based cursor movement continues during the main game, where the user will move the cursor to select on screen commands to progress the game. The context help line will provide players with context help as above.  

Each turn of the game consists of three rolls; each is activated via a large "ROLL" button which is selected by the cursor. For the first roll no dice are initially displayed, and the context help line will display "Select the ROLL button to roll the dice". When the dice are rolled, an animation process will show dice faces cycling and reveal the final position of each dice in sequence. 

Before the 2nd and 3rd roll, any of the dice can be locked so that they will not be affected by subsequent activations of the roll button. The context help line will display a message to "press the up/down keys to select a dice and space to lock/unlock".  Select the ROLL button to roll the unlocked dice". A locked dice will have a visual indicator such as a box around it so users can see when they have locked a dice. If all five dice are locked, the roll button will become disabled, preventing the user from rolling no dice and wasting a turn.  Incorrect key presses will be met with the same "Unable to move" notification as in the menu, with a lack of cursor movement. Once the intended dice are locked, the player can select and activate the "ROLL" button to continue, or they may choose at any time to allocate their dice roll to the score card.

### 3. Game - Score Card

Arrow based cursor movement and enter/space command selection continues, maintaining continuity in the user experience.  After the three rolls of a turn are completed, the user will be forced to choose where on the score card to place their final roll.  An algorithm will predict the best category to allocate the score based on the already allocated scores and the current dice values.

The context help line will display "Select a category on your score card to place this roll, press the up/down keys to select and Enter/Space to confirm". The cursor will appear in the player's column of the score card, and the up and down arrows can be used to select available cells of the table.  As each cell is highlighted, it will display the prospective score available should that category be chosen.

Logic will prevent cells already containing a roll from being selected, so when the up/down arrows are pressed the cursor will skip already allocated cells. Cateory selections which would result in zero score will be highlighed in orange when selected.  When the cursor highlights a cell which would result in a non-zero score it will be highlighted green.

To accept the selected category the user can press the space bar or enter key.  If the player selects a zero scoring cell (ie they have no choice, or they are choosing to forego a score for strategic reasons) they will be prompted again with a confirmation message "Are you sure you want enter a zero score for this category?", and will need to select the yes button and press enter/space again to confirm.

### 4. Summary Page / High Score Table

After completing a game, some game summary information is displayed, with a ranking of the players and their final scores.  Any player who has achieved a new high score is also indicated.  If the game was single player, the summary information contains the player's final score with a congratulatory message. If the game was multiplayer, then the players will be ranked and the winner declared.

If any player achieved a new high score, the updated high score table is displayed after ending the game.  No user interaction is required, apart from acknowledgement and closing the page with the enter/space key.  The information line will display "Press Enter/Space to return to the main menu". 

The user can also access the high score table at any time directly from the main menu.

## Control Flow Diagram

### 1. Control Flow Diagram for Main Menu, New Game Setup, and High Scores screens

![Control Flow Diagram for Main Menu, New Game setup, and High Scores screens](../../controlflowdiagram-main.drawio.png)

This diagram shows all parts of control flow, except for inside the main game loop.  The main game loop is represented by a predefined process symbol on this diagram and expanded in a separate diagram below.

### 2. Main Game Loop Control Flow Diagram

![Main Game Loop Control Flow Diagram](../../controlflowdiagram-gameloop.drawio.png)

This diagram shows the control flow once the main game loop is entered, via the previous control flow diagram.