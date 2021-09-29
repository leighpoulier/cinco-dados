require_relative "game"
module CincoDados
    class Controller


    def self.start()

        #Game should be instantiated with players, after player names are input from terminal


        @@reader = TTY::Reader.new(interrupt: Proc.new do
            @@game_screen.clean_up()
            puts "Ctrl-C pressed: Exiting ... Goodbye!"
            exit
        end)
        
        @@reader.subscribe(self)


        # create bogus players, should be passed in
        players = []
            
        player_iryna = Player.new("Iryna")
        player_iryna.add_score(:ones, 3)
        player_iryna.add_score(:fives, 15)
        player_iryna.add_score(:three_of_a_kind, 18)
        player_iryna.add_score(:small_straight, 30)
        player_iryna.add_score(:chance, 24)
        
        player_james = Player.new("James")
        player_james.add_score(:twos, 8)
        player_james.add_score(:fives, 15)
        player_james.add_score(:four_of_a_kind, 26)
        player_james.add_score(:large_straight, 40)
        
        player_leigh = Player.new("Leigh")
        player_leigh.add_score(:threes, 12)
        player_leigh.add_score(:fours, 16)
        player_leigh.add_score(:fives, 15)
        player_leigh.add_score(:sixes, 24)
        player_leigh.add_score(:full_house, 25)
        player_leigh.add_score(:cinco_dados, 50)
        
        players.push(player_iryna, player_james, player_leigh)
        
        main_game(players)
        


    end

    def self.screen()
        @@game_screen
    end

    def self.game()
        @@game
    end

    def self.keypress(event)  # implements subscription of TTY::Reader
        Logger.log.info("keypress event: key.name = #{event.key.name}, event.value = #{event.value}")
        case
        when event.key.name == :up || event.value == "w"
            @@cursor.move(NORTH)
        when event.key.name == :left || event.value == "a"
            @@cursor.move(WEST)
        when event.key.name == :down || event.value == "s"
            @@cursor.move(SOUTH)
        when event.key.name == :right || event.value == "d"
            @@cursor.move(EAST)
        when event.key.name == :return || event.key.name == :space
            @@cursor.activate()
        end
        display_message(@@cursor.get_status())
    end

    def self.display_message(message)
        @@console.display_message(message)
    end


    def self.clear_message()
        @@console.display_message("")
    end

    def self.main_game(players)

        # screen must come first, ready to receive the controls created in game
        # includes creation of button, infoline, selection cursor
        @@game_screen = GameScreen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)

            



        # after screen is created, create game. This includes controls such as dados and players scores
        @@game = Game.new(@@game_screen, players)

        # link button to middle dado
        @@game_screen.button.add_link(WEST, @@game.dados_cup.dados[2], false)

        # register activate event for roll button
        @@game_screen.button.register_event(:activate, ->(screen) {
            @@game.dados_cup.roll_dados()
        })

        @@cursor = @@game_screen.selection_cursor
        @@console = @@game_screen.info_line


        while true do 
            
            @@game_screen.draw
            
            @@reader.read_keypress
        
        end

    end

    end
end