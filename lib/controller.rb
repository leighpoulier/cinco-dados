require_relative "game"
module CincoDados
    class Controller


    def self.start()

        #Game should be instantiated with players, after player names are input from terminal


        @@reader = TTY::Reader.new(interrupt: Proc.new do
            @@screen.clean_up()
            puts "Ctrl-C pressed: Exiting ... Goodbye!"
            exit
        end)
        
        @@reader.subscribe(self)


        main_game()
        


    end

    def self.screen()
        @@screen
    end

    def self.game()
        @@game
    end

    def self.keypress(event)  # implements subscription of TTY::Reader
        Logger.log.info("keypress event: key.name = #{event.key.name}, event.value = #{event.value}")
        case
        when event.key.name == :up || event.value == "w"
            @@cursor.move(NORTH)
        when event.key.name == :right || event.value == "d"
            @@cursor.move(EAST)
        when event.key.name == :down || event.value == "s"
            @@cursor.move(SOUTH)
        when event.key.name == :left || event.value == "a"
            @@cursor.move(WEST)
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

    def self.main_game()

        @@screen = Screen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)
        @@game = GameModel.new()

        @@game.dados_cup.dados.each do |dado|
            @@screen.add_control(dado)
        end

        # create roll button
        button = Button.new(20, 14, 8, 3, "\u{1FB99}", "ROLL", "roll")\

        # link dados to roll button
        @@game.dados_cup.dados.each do |dado|
            dado.add_link(EAST, button, false)
        end

        # link button to middle dado
        button.add_link(WEST, @@game.dados_cup.dados[2], false)

        # register activate event for roll button
        button.register_event(:activate, ->(screen) {
            @@game.dados_cup.roll_dados()
        })
        @@screen.add_control(button)
            
        # create selection cursor
        selection_cursor = SelectionCursor.new(button, "cursor")
        @@screen.add_control(selection_cursor)
        @@screen.set_selection_cursor(selection_cursor)
        
        # create info_line
        info_line = InfoLine.new(@@screen.columns, @@screen.rows-1)
        @@screen.add_control(info_line)
        @@screen.set_info_line(info_line)

        # create score card
        @@screen.add_control(ScoreCard.new(38,1,@@game.players))
            
        @@cursor = selection_cursor
        @@console = info_line


        while true do 
        
            @@screen.draw
            
            @@reader.read_keypress
        
        end

    end

    end
end