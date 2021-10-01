require "tty-reader"
require_relative "exceptions"
require_relative "config"
require_relative "dados_cup"
require_relative "screen"
require_relative "border_control"
require_relative "player"
require_relative "score_card"

module CincoDados
    class Game


        attr_reader :players, :current_player, :dados_cup, :score_card, :current_player, :current_player_roll_count, :current_player_turn_complete

        def initialize(game_screen)
            @game_screen = game_screen

            # if players.length < 1 || players.length > 4
            #     raise ArgumentError.new("Only 1-4 players are accepted")
            # end

            
            # adding players comes later.  moved this initialisation until after first player added.
                # @players = players
                # @current_player = players[0]

                # link the dados cup to the the players score cells for hypothetical display
                # @players.each do |player|
                #     Logger.log.info("Set dados_cup #{@dados_cup} on player: #{player}")
                #     player.player_scores.set_dados_cup(@dados_cup)
                # end

                # # create score card
                # # requires a reference to game_screen so it can pass it to the score controls   
                # @score_card = ScoreCard.new(38,1,@players, @game_screen)
                # @game_screen.add_control(@score_card)
                

            @players = []
            @current_player = nil
            @current_player_roll_count = 0
            @turn_counter = 0
            
            # create the dados cup
            @dados_cup = DadosCup.new(@game_screen, Config::DADOS_COUNT)

            # link dados to roll button
            @dados_cup.dados.each do |dado|
                dado.add_link(EAST, @game_screen.roll_button, false)
            end


            # create score card, empty to start with.  Players must be added to it as they are added to the game
            # requires a reference to game_screen so it can pass it to the score controls   
            @score_card = ScoreCard.new(38,1,@game_screen)
            @game_screen.add_control(@score_card)

            
        end

        def add_player(player)
            @players.push(player)

            if @players.length == 1
                Logger.log.info("First player added. Set current player to #{player}")
                @current_player = player
            end

            @score_card.add_player(player)

            # link the dados cup to the the players score cells for hypothetical display
            Logger.log.info("Set dados_cup #{@dados_cup} on player: #{player}")
            player.player_scores.set_dados_cup(@dados_cup)

        end

        def player_count()
            return @players.length
        end

        def turns_remaining?()
            @players.each do |player|
                if player.turns_remaining?
                    return true
                end
            end
            Logger.log.info("No Player Turns Remaining - end of game")
            return false
        end

        def set_roll_button_link()
            # Set the EAST link from the roll button to one of the cells of the first player
            # Config::SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING.each do |category|
            #     if @current_player.player_scores.scores[category].enabled
            #         @game_screen.roll_button.add_link(EAST, @current_player.player_scores.scores[category], false)
            #         Logger.log.info("Add link on button to #{@current_player.name} score: #{player.player_scores.scores[category]}")
            #         break
            #     end
            # end

            @game_screen.roll_button.add_link(EAST, @current_player.player_scores.scores[get_recommended_score_category()] ,false)
            Logger.log.info("Add link on button to #{@current_player.name} score: #{@current_player.player_scores.scores[get_recommended_score_category()]}")
            
        end

        def delete_roll_button_link()
            @game_screen.roll_button.remove_link(EAST)
        end

        def increment_current_player_roll_count()
            @current_player_roll_count += 1
            Logger.log.info("Current Player roll count: #{@current_player_roll_count}")
            if @current_player_roll_count > 3
                raise StandardError.new("Somehow #{@current_player} has had #{@current_player_roll_count} rolls")
            end
        end

        # def get_recommended_score_category(exclude = Config::SCORE_CATEGORIES_EXCLUDE_FROM_RECOMMENDATION)
        def get_recommended_score_category(exclude = [])

            # Logger.log.info("All dados_cup scores: #{@dados_cup.scores}")
            # Logger.log.info("Filtered dados cup scores: #{@dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories)}")

            unless exclude.is_a?(Array)
                raise ArgumentError.new("excluded categories must be passed as an array of symbols. Use an empty array if necessary to avoid exclusion")
            end

            Logger.log.info("Attempting to exclude categories #{exclude.to_s}, which is a #{exclude.class.name} with value: #{exclude.inspect}")

            # Filter out the past in excluded categories
            filtered_categories = @dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories).reject do |category, score|
                exclude.include?(category)
            end

            # First see if there are any scores which would help towards achieving the upper bonus
            bonus_qualifying_upper_scores = @dados_cup.bonus_qualifying_upper_scores().slice(*@current_player.player_scores.get_empty_categories_upper())
            Logger.log.info("Bonus qualifying upper scores: #{bonus_qualifying_upper_scores}")
            
            # if at bonus qualifying score is achieved, recommend it
            if bonus_qualifying_upper_scores.length > 0
                Logger.log.info("Recommending bonus qualifying upper score")
                return bonus_qualifying_upper_scores.sort_by do |category, score|
                    score
                end.last.first
            end

            # otherwise recommend the highest score achievable from the filtered categories
            recommended_category = filtered_categories.sort_by do |category, score|
                score
            end.last.first

            if recommended_category.nil?
                raise CincoDadosError("Recommending a score category failed =(")
            end

            Logger.log.info("Filtered dados cup scores, sorted descending: #{recommended_category}")
            return recommended_category
        end

        def play_turn(reader)
            @current_player_roll_count = 0
            @current_player_count_empty_categories = @current_player.player_scores.count_empty_categories()
            Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")

            # Update the player name headings for highlighting current player
            @players.each do |player|
                player.update_player_name_control()
            end

            # Enable the roll button in case it was disabled after the previous turn
            @game_screen.roll_button.enable()
            # Show the roll button in case it was hidden
            @game_screen.roll_button.show()

            # Position the cursor on the roll button
            @game_screen.selection_cursor.select_control(@game_screen.roll_button)

            # Hide all the dados
            @dados_cup.hide_all_dados()

            # Enable all the dados 
            # @dados_cup.enable_all_dados()


            # while a new score isn't added, and the roll count < 3
            while @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories() && @current_player_roll_count < Config::MAX_ROLLS_PER_TURN
                @game_screen.display_message("#{@current_player}'s turn. #{Config::MAX_ROLLS_PER_TURN - @current_player_roll_count} rolls left.  Press Enter/Space to #{@game_screen.selection_cursor.enclosed_control.get_on_activate_description()}.")
                @game_screen.draw
                reader.read_keypress
            end

            # Cleanup all locks, they aren't needed any more for this turn.
            @dados_cup.remove_all_locks()

            # 3 turns are over, but still no score added
            # Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")
            if @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()

                #select the recommended control
                @game_screen.selection_cursor.select_control(@current_player.player_scores.scores[get_recommended_score_category()])


                # Disable the roll buton
                @game_screen.roll_button.disable()
                # Hide the roll button
                @game_screen.roll_button.hide()

                # Disabled all the dice
                @dados_cup.disable_all_dados()

                # Loop until player commits a score
                while @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()
                    @game_screen.display_message("#{@current_player}'s turn. #{Config::MAX_ROLLS_PER_TURN - @current_player_roll_count} rolls left.  Navigate with \u{2190}\u{2191}\u{2193}\u{2192} and Enter/Space to select.")
                    # Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")

                    @game_screen.draw
                    reader.read_keypress
                end
            end

        end

        def next_player()
            @turn_counter += 1
            @current_player = @players[@turn_counter % @players.length]
            Logger.log.info("Player is now #{@current_player}")

        end

        def roll()

            @game_screen.roll_button.hide()
            @game_screen.selection_cursor.hide()
            @dados_cup.roll_dados()
            increment_current_player_roll_count()
            set_roll_button_link()
            @game_screen.roll_button.show()
            @game_screen.selection_cursor.show()

        end

        def play(reader)

            if @players.length < 1
                raise ConfigurationError.new("Can't start playing with less than 1 player!")
            end

            while turns_remaining?() do 
                
                # @@game_screen.draw()
                
                play_turn(reader)

                next_player()
            
            end

            @game_screen.draw

            game_results = []

            players.each do |player|
                game_results.push({name: player.name}.merge(player.get_all_scores()))
            end

            return game_results
            

        end

    end
end