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

            # exit

            # # new game setup screen

            # # get number of players
            # num_players = nil
            # while num_players.nil? || num_players < 1 || num_players > 4
            #     print "enter number of players: (1-4) "
            #     num_players = gets.to_i
            #     # p num_players
            # end
            # puts
            
            # players = []

            # # ask for their names?
            
            # while players.length < num_players


            #     player_name = nil
            #     while player_name.nil? || player_name.length < 1 || player_name.length > ScoreCard::PLAYER_SCORE_WIDTH || !(/[^#{regex}]/ =~ player_name).nil?
            #         print "Enter player #{players.length + 1} name: (max 5 characters) "
            #         player_name = gets.strip
            #         p player_name
            #     end

            #     # add the player to the list
            #     players.push(Player.new(player_name))
            # end
                    



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
    
            @@menu_screen = MainMenuScreen.new()
            
            @@menu_screen.start()

            @@menu_screen.clean_up()

        end

        def self.menu_new_game()

            @@player_count_menu_screen = PlayerCountMenuScreen.new()

            @@player_count = @@player_count_menu_screen.get_player_count()
            Logger.log.info("Player count: #{@player_count}")

            unless @@player_count.nil?

                # players = []
                player_names = []
                (0...@@player_count).each do |player_counter|
                    @@player_name_menu_screen = PlayerNameMenuScreen.new()

                    # print "Enter player #{player_counter + 1} name: (max 5 characters) "
                    player_name = @@player_name_menu_screen.get_player_name(player_counter)


                    player_names.push(player_name)
                    # players.push(Player.new(player_name))

                    Logger.log.info("Player Names: #{player_names.to_s}")
                end

                game_result = main_game(player_names)
                Logger.log.info("#{game_result}")

                # congratulations message

                # high score processing

                # then it returns up the stack to the main menu
                
                if game_result.nil?  # Game was aborted
                    Logger.log.info("Game aborted, no winner")
                else  # game was fully completed, results returned
                    winning_player_result = game_result.sort_by do |player_result|
                        player_result[:totals][:grand_total]
                    end.last
                    
                    Logger.log.info("The winner is: #{winning_player_result[:name]} with score #{winning_player_result[:totals][:grand_total]}")
                end
            end

        end

        def self.main_game(player_names)

            # screen must come first, ready to receive the controls created in game
            # includes creation of roll button, infoline, selection cursor
            @@game_screen = GameScreen.new()

            # after screen is created, create game. This includes controls such as dados and players scores
            @@game = Game.new(@@game_screen)

            player_names.each do |player_name|

                # Player requires a reference to the game, so that the player_name control can know if it is the current player.
                player = Player.new(@@game, player_name)

                # player.add_score(:cinco_dados, Config::SCORE_CINCO_DADOS)
                # player.add_score(:large_straight, Config:: SCORE_LARGE_STRAIGHT)
                # player.add_score(:small_straight, Config:: SCORE_SMALL_STRAIGHT)
                # player.add_score(:full_house, Config:: SCORE_FULL_HOUSE)
                # player.add_score(:four_of_a_kind, 3000)
                # player.add_score(:three_of_a_kind, 30)
                # player.add_score(:sixes, 30)
                # player.add_score(:fives, 25)
                # player.add_score(:fours, 16)
                # player.add_score(:threes, 9)
                # player.add_score(:twos, 4)

                @@game.add_player(player)
            end

            # link the game screen to the game, so that screen controls can trigger game events
            @@game_screen.set_game(@@game)


            game_result = @@game.play(@@game_screen.reader)

            return game_result

        end

        def self.how_to_play()

            @@how_to_play_screen = HowToPlayScreen.new()

            @@how_to_play_screen.start()

        end
    end

end