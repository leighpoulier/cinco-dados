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


        attr_reader :players, :current_player, :dados_cup, :score_card, :current_player_roll_count, :current_player_turn_complete

        def initialize(game_screen, players)
            @game_screen = game_screen

            if players.length < 1 || players.length > 4
                raise ArgumentError.new("Only 1-4 players are accepted")
            end

            @players = players
            @current_player = players[0]
            @current_player_index = 0
            @current_player_roll_count = 0
            @turn_counter = 0
            
            # create the dados cup
            @dados_cup = DadosCup.new(@game_screen, Config::DADOS_COUNT)

            # link dados to roll button
            @dados_cup.dados.each do |dado|
                dado.add_link(EAST, @game_screen.button, false)
            end

            # link the dados cup to the the players score cells for hypothetical display
            @players.each do |player|
                Logger.log.info("Set dados_cup #{@dados_cup} on player: #{player}")
                player.player_scores.set_dados_cup(@dados_cup)
            end
            
            # create score card
            # requires a reference to game_screen so it can pass it to the score controls   
            @score_card = ScoreCard.new(38,1,@players, @game_screen)
            @game_screen.add_control(@score_card)
            
            # set_roll_button_link()
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
            #         @game_screen.button.add_link(EAST, @current_player.player_scores.scores[category], false)
            #         Logger.log.info("Add link on button to #{@current_player.name} score: #{player.player_scores.scores[category]}")
            #         break
            #     end
            # end
            @game_screen.button.add_link(EAST, @current_player.player_scores.scores[get_recommended_score_category()] ,false)
            Logger.log.info("Add link on button to #{@current_player.name} score: #{@current_player.player_scores.scores[get_recommended_score_category()]}")
            
        end

        def delete_roll_button_link()
            @game_screen.button.remove_link(EAST)
        end

        def increment_current_player_roll_count()
            @current_player_roll_count += 1
            Logger.log.info("Current Player roll count: #{@current_player_roll_count}")
            if @current_player_roll_count > 3
                raise StandardError.new("Somehow #{@current_player} has had #{@current_player_roll_count} rolls")
            end
        end

        def get_recommended_score_category(exclude = Config::SCORE_CATEGORIES_EXCLUDE_FROM_RECOMMENDATION)
            Logger.log.info("All dados_cup scores: #{@dados_cup.scores}")
            Logger.log.info("Filtered dados cup scores: #{@dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories)}")
            if exclude.nil?
                Logger.log.info("not excluding base on exclude is a #{exclude.class.name} with value: #{exclude.inspect}")
                recommended_category = @dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories).sort_by do |category, score|
                    score
                end.last.first
            else
                unless exclude.is_a?(Array)
                    raise ArgumentError.new("excluded categories must be passed as an array of symbols")
                end
                Logger.log.info("Attempting to exclude categories #{exclude.to_s}, which is a #{exclude.class.name} with value: #{exclude.inspect}")
                recommended_category = @dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories).reject do |category, score|
                    exclude.include?(category)
                end.sort_by do |category, score|
                    score
                end.last.first
            end
            Logger.log.info("Filtered dados cup scores, sorted descending: #{recommended_category}")
            return recommended_category
        end

        def play_turn(reader)
            @current_player_roll_count = 0
            @current_player_count_empty_categories = @current_player.player_scores.count_empty_categories()
            Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")

            # while a new score isn't added, and the roll count < 3
            while @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories() && @current_player_roll_count < Config::MAX_ROLLS_PER_TURN
                Controller.display_message("#{@current_player}'s turn. #{Config::MAX_ROLLS_PER_TURN - @current_player_roll_count} rolls left.  Navigate with \u{2190}\u{2191}\u{2193}\u{2192} and Enter/Space to select.")
                @game_screen.draw
                reader.read_keypress
            end

            # Cleanup all locks, they aren't needed any more for this turn.
            @dados_cup.remove_all_locks()

            # 3 turns are over, but still no score added
            Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")
            if @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()

                #select the recommended control
                @game_screen.selection_cursor.select_control(@current_player.player_scores.scores[get_recommended_score_category()],EAST)


                # Disable the roll buton
                @game_screen.button.disable()

                # Disabled all the dice
                @dados_cup.disable_all_dados()

                
                while @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()
                    Controller.display_message("#{@current_player}'s turn. #{Config::MAX_ROLLS_PER_TURN - @current_player_roll_count} rolls left.  Navigate with \u{2190}\u{2191}\u{2193}\u{2192} and Enter/Space to select.")
                    Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")
                    @game_screen.draw
                    reader.read_keypress
                end
            end

        end

        def next_player()
            @turn_counter += 1
            @current_player = @players[@turn_counter % @players.length]
            Logger.log.info("Player is now #{@current_player}")

            # Set the link on the button to the appropriate column based on @current_player
            # set_roll_button_link()

            # Enable the roll button in case it was disabled after the previous turn
            @game_screen.button.enable()

            # Position the cursor on the roll button
            @game_screen.selection_cursor.select_control(@game_screen.button, WEST)

            # Hide all the dados
            @dados_cup.hide_all_dados()

            # Enable all the dados 
            # @dados_cup.enable_all_dados()

        end

    end
end