require_relative "game"
require_relative "screen"
module CincoDados
    class Controller


        def self.start()

            # @@reader = TTY::Reader.new(interrupt: Proc.new do
            #     puts "Ctrl-C pressed: Exiting ... Goodbye!"
            #     exit
            # end)
            
            # @@reader.subscribe(self)

            # @@console = nil
            # @@cursor = nil

            # display main menu
            #New game
            #High Scores
            #Exit

            self.menu_main()

            exit

            # new game setup screen

            # get number of players
            num_players = nil
            while num_players.nil? || num_players < 1 || num_players > 4
                print "enter number of players: (1-4) "
                num_players = gets.to_i
                # p num_players
            end
            puts
            
            players = []

            # ask for their names?
            
            while players.length < num_players

                puts Regexp.escape("`~!@#$%^&*()-_=+[]{}\|;:'\",.<>\/?")

                player_name = nil
                while player_name.nil? || player_name.length < 1 || player_name.length > ScoreCard::PLAYER_SCORE_WIDTH || !(/[^`~!@#$%^&*()-_=+\[\]{}\\|;:'",.<>\/?A-Za-z0-9]/ =~ player_name).nil?
                    print "Enter player #{players.length + 1} name: (max 5 characters) "
                    player_name = gets.strip
                    p player_name
                end

                # add the player to the list
                players.push(Player.new(player_name))
            end
                    
            players.each do |player|
                player.add_score(:cinco_dados, Config::SCORE_CINCO_DADOS)
                player.add_score(:large_straight, Config:: SCORE_LARGE_STRAIGHT)
                player.add_score(:small_straight, Config:: SCORE_SMALL_STRAIGHT)
                player.add_score(:full_house, Config:: SCORE_FULL_HOUSE)
                player.add_score(:four_of_a_kind, 30)
                player.add_score(:three_of_a_kind, 30)
                player.add_score(:sixes, 30)
                player.add_score(:fives, 25)
                player.add_score(:fours, 16)
                player.add_score(:threes, 9)
                player.add_score(:twos, 4)
            end



            game_result = main_game(players)
            


        end

        # def self.screen()
        #     @@game_screen
        # end

        # def self.game()
        #     @@game
        # end

        # def self.keypress(event)  # implements subscription of TTY::Reader
        #     # Logger.log.info("keypress event: key.name = #{event.key.name}, event.value = #{event.value}")
        #     case
        #     when event.key.name == :up || event.value == "w"
        #         @@cursor.move(NORTH)
        #     when event.key.name == :left || event.value == "a"
        #         @@cursor.move(WEST)
        #     when event.key.name == :down || event.value == "s"
        #         @@cursor.move(SOUTH)
        #     when event.key.name == :right || event.value == "d"
        #         @@cursor.move(EAST)
        #     when event.key.name == :return || event.key.name == :space
        #         @@cursor.on_activate()
        #     when event.key.name == :escape
        #         Logger.log.info("Escape key pressed but not yet implemented")
        #         @@console.display_message("Escape pressed but not yet implemented")
        #     end
        # end


        def self.menu_main()
    
            @@menu_screen = MenuScreen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)
            @@menu_screen.setup_menu(:main)
    
            @@menu_screen.start()

            @@menu_screen.clean_up()

        end

        def self.menu_new_game()

            @@setup_menu_screen = MenuScreen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)
            @@setup_menu_screen.setup_menu(:player_count)

            @@new_game_data = {}
            @@new_game_data.merge!(@@setup_menu_screen.start())
            Logger.log.info("#{@@new_game_data}")
            Logger.log.info("Player count: #{@@new_game_data[:player_count]}")


        end

        def self.main_game(players)

            # screen must come first, ready to receive the controls created in game
            # includes creation of roll button, infoline, selection cursor
            @@game_screen = GameScreen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)

            # after screen is created, create game. This includes controls such as dados and players scores
            @@game = Game.new(@@game_screen, players)

            # link (screen) button to (game) middle dado
            @@game_screen.roll_button.add_link(WEST, @@game.dados_cup.dados[2], false)

            # register activate event for roll button
            @@game_screen.roll_button.register_event(:activate, ->() {
                display_message("Rolling !")
                @@game.roll()
            })

            game_result = @@game.play(@@game_screen.reader)

            winning_player_result = game_result.sort_by do |player_result|
                player_result[:totals][:grand_total]
            end.last

            puts "The winner is: #{winning_player_result[:name]} with score #{winning_player_result[:totals][:grand_total]}"

            @@game_screen.clean_up()

        end
    end

end