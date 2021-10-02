require_relative "game"
require_relative "screen"
require "json"
module CincoDados
    class Controller


        def self.start()


            self.menu_main()
                    

        end

        def self.menu_main()
    
            @@main_menu_screen = MainMenuScreen.new()
            
            @@main_menu_screen.start()

            @@main_menu_screen.clean_up()

        end

        def self.main_menu_screen()
            @@main_menu_screen
        end

        def self.menu_new_game()

            @@player_count_menu_screen = PlayerCountMenuScreen.new()

            @@player_count = @@player_count_menu_screen.get_player_count()
            Logger.log.info("Player count: #{@player_count}")

            unless @@player_count.nil?

                # Create an array to hold the player names
                player_names = []

                # Get a player name for each player
                (0...@@player_count).each do |player_counter|
                    @@player_name_menu_screen = PlayerNameMenuScreen.new()

                    # print "Enter player #{player_counter + 1} name: (max 5 characters) "
                    player_name = @@player_name_menu_screen.get_player_name(player_counter)


                    player_names.push(player_name)
                    # players.push(Player.new(player_name))

                    Logger.log.info("Player Names: #{player_names.to_s}")
                end

                main_game(player_names)

               
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
                # player.add_score(:four_of_a_kind, 30)
                # player.add_score(:three_of_a_kind, 30)
                # player.add_score(:sixes, 30)
                # player.add_score(:fives, 25)
                # player.add_score(:fours, 16)
                # player.add_score(:threes, 9)
                # player.add_score(:twos, 4)
                # player.add_score(:ones, 3)
                # player.add_score(:chance, 30)

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

        def self.high_scores()

            @@high_scores_screen = HighScoresScreen.new()
            @@high_scores_screen.start()

        end

        def self.load_high_scores()

            # attempt to open high scores json file.
            begin
                high_scores_json = File.open("high_scores.json", "r").read
            rescue => e
                # if e.class == Errno::ENOENT  # file not found
                    # create new file
                    high_scores_json = ""
                    # else

            # else
            # ensure
            end

            # attempt to parse json file into json
            begin
                high_scores = JSON.parse(high_scores_json, {symbolize_names: true})
            rescue
                high_scores = {}
            end
            
            Logger.log.info("#{__method__}: Loaded high scores: #{@high_scores}")

            return high_scores.values.sort_by do |high_score|
                high_score[:score]
            end
            .reverse
            .each do |high_score|
                high_score[:new] = false
            end


        end

        def self.save_high_scores(high_scores_array)


            high_scores = high_scores_array.map.with_index do |high_score, index|
                [("high_score_%02d" % (index + 1)).to_sym, high_score]
            end.to_h
            
            Logger.log.info("#{__method__}: New high scores hash: #{@high_scores}")

            # begin
                high_scores_json = JSON.generate(high_scores)
            # rescue
                
            # end


            
            
            # attempt to save high scores json file.
            begin
                file = File.open("high_scores.json", "w")
                file.write(high_scores_json)
            rescue => e
            
                # unable to open file for writing?
            
            # else
            # ensure
        
            end


        end

        def self.load_dados_stats()

            # attempt to open high scores json file.
            begin
                dados_stats_json = File.open("dados_stats.json", "r").read
            rescue => e
                # if e.class == Errno::ENOENT  # file not found
                    # create new file
                    dados_stats_json = ""
                    # else

            # else
            # ensure
            end

            # attempt to parse json file into json
            begin
                dados_stats = JSON.parse(dados_stats_json, {symbolize_names: true})
            rescue
                dados_stats = {}
            end
            
            Logger.log.info("#{__method__}: Loaded dados_stats: #{dados_stats}")

            return dados_stats
        end

        def self.save_dados_stats(dados_stats)

                # begin
                    dados_stats_json = JSON.generate(dados_stats)
                # rescue
                    
                # end

                
                # attempt to save high scores json file.
                begin
                    file = File.open("dados_stats.json", "w")
                    file.write(dados_stats_json)
                rescue => e
                
                    # unable to open file for writing?
                
                # else
                # ensure
                

                end


        end
    end

end