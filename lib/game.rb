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

            @players = []
            @current_player = nil
            @current_player_roll_count = 0
            @turn_counter = 0
            @exit_flag = false
            @new_high_scores = false
            
            # create the dados cup
            @dados_cup = DadosCup.new(@game_screen, Config::DADOS_COUNT)

            # link dados to roll button
            @dados_cup.dados.each do |dado|
                dado.add_link(EAST, @game_screen.roll_button, false)
            end


            # create score card, empty to start with.  Players must be added to it as they are added to the game
            # ScoreCard requires a reference to game_screen so it can pass it to the score controls so they can be added to the screen for drawing  
            @score_card = ScoreCard.new(38,1,@game_screen)
            @game_screen.add_control(@score_card)

            
        end

        # Add a new player to the game

        def add_player(player)

            # Add player to the games array of players
            @players.push(player)

            # If player is the first player added
            if @players.length == 1
                # Set that player to be the current player, the game will start with them
                Logger.log.info("First player added. Set current player to #{player}")
                @current_player = player
            end

            # Add the player to the scorecard, generating the player name heading at the top of the card, and widening the card by one column
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

        def set_exit_flag()
            @exit_flag = true
            Logger.log.info("#{__method__}: game exit_flag: #{@exit_flag}")
        end

        def set_roll_button_link()

            begin
                # attempt automatic algorithm for best category for current dados
                recommended_category = get_recommended_score_category()
                Logger.log.error("Recommended Score SUCCESSFUL, moving selection cursor to #{recommended_category}")
                # Logger.log.info("Would have moved the cursor to: #{Config::SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING.intersection(@current_player.player_scores.get_empty_categories()).first}")
                
            rescue
                # if automatic algorithm fails, use backup fixed list of priorities
                recommended_category = Config::SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING.intersection(@current_player.player_scores.get_empty_categories()).first
                Logger.log.error("Recommended Score category FAILED, instead moving selection cursor to #{recommended_category}")
            end

            control_to_link = @current_player.player_scores.scores[recommended_category]
            @game_screen.roll_button.add_link(EAST, control_to_link ,false)
            Logger.log.info("Add link on button to #{@current_player.name} score: #{control_to_link}")
            
            

        end

        # def delete_roll_button_link()
        #     @game_screen.roll_button.delete_link(EAST)
        # end

        def increment_current_player_roll_count()
            @current_player_roll_count += 1
            Logger.log.info("Current Player roll count: #{@current_player_roll_count}")
            if @current_player_roll_count > 3
                raise StandardError.new("Somehow #{@current_player} has had #{@current_player_roll_count} rolls")
            end
        end

        # def get_recommended_score_category(exclude = Config::SCORE_CATEGORIES_EXCLUDE_FROM_RECOMMENDATION)
        def get_recommended_score_category(exclude = [])

            Logger.log.info("All dados_cup scores: #{@dados_cup.scores}")
            Logger.log.info("Current player empty categories dados cup scores: #{@dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories)}")

            unless exclude.is_a?(Array)
                raise ArgumentError.new("excluded categories must be passed as an array of symbols. Use an empty array if necessary to avoid exclusion")
            end

            Logger.log.info("Attempting to exclude categories #{exclude.to_s}, which is a #{exclude.class.name} with value: #{exclude.inspect}")

            # Filter out excluded categories and non_zero categoriries
            filtered_scores = @dados_cup.scores.slice(*@current_player.player_scores.get_empty_categories).reject do |category, score|
                exclude.include?(category)
            end

            # if only one score, no need to go further. Recommend single score
            if filtered_scores.length == 1  
                return filtered_scores.first.first
            end
            
            filtered_scores_non_zero = filtered_scores.reject do |category, score|
                score == 0
            end

            if filtered_scores_non_zero.length > 0  #there are non-zero scores to recommend

                # First see if the filtered categories includes a "Cinco Dados", and recommend it
                if filtered_scores_non_zero.keys.include?(:cinco_dados)
                    Logger.log.info("#{__method__}: Recommending cinco_dados")
                    return :cinco_dados
                end

                # Next see if there are any scores which would help towards achieving the upper bonus
                # bonus_qualifying_upper_scores = @dados_cup.bonus_qualifying_upper_scores().slice(*@current_player.player_scores.get_empty_categories_upper())
                bonus_qualifying_upper_scores = @dados_cup.bonus_qualifying_upper_scores().slice(*filtered_scores_non_zero.keys)
                Logger.log.info("Bonus qualifying upper scores: #{bonus_qualifying_upper_scores}")
                
                # if a bonus qualifying score is achieved, recommend it
                if bonus_qualifying_upper_scores.length > 0
                    Logger.log.info("Recommending bonus qualifying upper score")
                    return bonus_qualifying_upper_scores.sort_by do |category, score|
                        score
                    end.last.first
                end

                # next recommend fixed scores from the lower section, in descending order
                lower_fixed_scores = filtered_scores_non_zero.slice(*Config::SCORE_CATEGORIES_LOWER_FIXED.keys)
                if lower_fixed_scores.length > 0
                    Logger.log.info("Recommending lower fixed score")
                    return lower_fixed_scores.sort_by do |category, score|
                        score
                    end.last.first
                end

                # next recommend four of a kind
                if filtered_scores_non_zero.keys.include?(:four_of_a_kind)
                    Logger.log.info("#{__method__}: Recommending four_of_a_kind")
                    return :four_of_a_kind
                end

                # next recommend three of a kind
                if filtered_scores_non_zero.keys.include?(:three_of_a_kind)
                    Logger.log.info("#{__method__}: Recommending three_of_a_kind")
                    return :three_of_a_kind
                end

                # next recommend non_bonus achieving 1-2-3
                upper_non_bonus_ones_twos_threes = filtered_scores_non_zero.slice(:ones, :twos, :threes)
                if upper_non_bonus_ones_twos_threes.length > 0
                    Logger.log.info("#{__method__}: Recommending non bonus 1-2-3")
                    return upper_non_bonus_ones_twos_threes.sort_by do |category, score|
                        Config::SCORE_CATEGORIES_BONUS_MINIMUMS[category] - score
                    end.first.first
                end

                # recommend chance > 20
                if filtered_scores_non_zero.keys.include?(:chance) && filtered_scores_non_zero[:chance] > 20
                    Logger.log.info("#{__method__}: Recommending chance >20")
                    return :chance
                end

                # next recommend non_bonus achieving 4-5-6
                upper_non_bonus_fours_fives_sixes = filtered_scores_non_zero.slice(:fours, :fives, :sixes)
                if upper_non_bonus_fours_fives_sixes.length > 0
                    Logger.log.info("#{__method__}: Recommending non bonus 4-5-6")
                    return upper_non_bonus_fours_fives_sixes.sort_by do |category, score|
                        Config::SCORE_CATEGORIES_BONUS_MINIMUMS[category] - score
                    end.first.first
                end

                # recommend chance <= 20
                if filtered_scores_non_zero.keys.include?(:chance)
                    Logger.log.info("#{__method__}: Recommending chance <=20")
                    return :chance
                end

                # recommend any score that we haven't already covered ?
                # recommend the highest score achievable from the filtered categories
                return any_left_non_zero_score = filtered_scores_non_zero.sort_by do |category, score|
                    score
                end.last.first

            else  # No non-zero scores available to recommend

                #recommend zeroing the upper section
                filtered_scores
                upper_zero_scores = Config::SCORE_CATEGORIES_UPPER.map.with_index do |category, index|
                    [category, (index+1) * 3]
                end.to_h.slice(*filtered_scores)
                if upper_zero_scores.length > 0
                    return upper_zero_scores.sort_by do | category, foregone_score |
                        foregone_score
                    end.first.first
                end

                #recommend zeroing in order of least probable to most probable
                lower_fixed_zero_scores = Config::SCORE_CATEGORIES_LOWER_FIXED.slice(*filtered_scores.keys)  # filtered_scores only contains zero scores
                if lower_fixed_zero_scores.length > 0
                    Logger.log.info("#{__method__}: Recommending lower zero score")
                    return lower_fixed_zero_scores.sort_by do |category, foregone_score|
                        foregone_score
                    end.last.first
                end

                # what's left?
                if filtered_scores.include?(:four_of_a_kind)
                    return :four_of_a_kind
                elsif filtered_scores.include?(:three_of_a_kind)
                    return :three_of_a_kind
                end

                # return ANYTHING
                if filtered_scores.length > 0
                    return filtered_scores.first.first
                end

            end

            raise CincoDadosError("Recommending a score category failed =(")
    
        end

        def play_turn(reader)
            @current_player_roll_count = 0
            @current_player_count_empty_categories = @current_player.player_scores.count_empty_categories()
            Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")

            # Update the player name headings for highlighting current player
            @players.each do |player|
                player.update_player_name_control()
            end

            Logger.log.info("1. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")

            # Enable the roll button in case it was disabled after the previous turn
            @game_screen.roll_button.enable()
            # Show the roll button in case it was hidden
            @game_screen.roll_button.show()
            Logger.log.info("2. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")

            # Position the cursor on the roll button
            @game_screen.selection_cursor.select_control(@game_screen.roll_button)
            Logger.log.info("3. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")

            # Hide all the dados
            @dados_cup.hide_all_dados()

            # Disable all the dados
            @dados_cup.disable_all_dados()
            Logger.log.info("4. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")


            # while a new score isn't added, and the roll count < 3
            while !@exit_flag && @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories() && @current_player_roll_count < Config::MAX_ROLLS_PER_TURN

                # Update context help
                rolls_left = Config::MAX_ROLLS_PER_TURN - @current_player_roll_count
                @game_screen.display_message("#{@current_player}'s turn. #{rolls_left} #{rolls_left == 1 ? "roll" : "rolls"} left. #{@game_screen.get_context_help()}")
                
                Logger.log.info("5. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")
                @game_screen.draw
                reader.read_keypress
            end

            # Cleanup all locks, they aren't needed any more for this turn.
            @dados_cup.remove_all_locks()

            # 3 turns are over, but still no score added
            # Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")
            if  !@exit_flag && @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()

                #select the recommended control
                begin
                    # attempt automatic algorithm for best category for current dados
                    recommended_category = get_recommended_score_category()
                    Logger.log.error("Recommended Score SUCCESSFUL, moving selection cursor to #{recommended_category}")
                    # Logger.log.info("Would have moved the cursor to: #{Config::SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING.intersection(@current_player.player_scores.get_empty_categories()).first}")
                    
                rescue
                    # if automatic algorithm fails, use backup fixed list of priorities
                    recommended_category = Config::SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING.intersection(@current_player.player_scores.get_empty_categories()).first
                    Logger.log.error("Recommended Score category FAILED, instead moving selection cursor to #{recommended_category}")
                end
                control_to_select = @current_player.player_scores.scores[recommended_category]
                @game_screen.selection_cursor.select_control(control_to_select)



                # Disable the roll buton
                @game_screen.roll_button.disable()
                # Hide the roll button
                @game_screen.roll_button.hide()

                Logger.log.info("7. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")
                # Disable all the dados
                @dados_cup.disable_all_dados()

                Logger.log.info("8. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")
                # Loop until player commits a score
                while  !@exit_flag && @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()

                    # Update context help
                    rolls_left = Config::MAX_ROLLS_PER_TURN - @current_player_roll_count
                    @game_screen.display_message("#{@current_player}'s turn. #{rolls_left} #{rolls_left == 1 ? "roll" : "rolls"} left. #{@game_screen.get_context_help()}")

                    @game_screen.draw
                    reader.read_keypress
                    Logger.log.info("9. Roll button EAST link to control: #{@game_screen.roll_button.links[EAST]}")
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


            # -------------------------------- main game loop -------------------------------------

            while turns_remaining?() && !@exit_flag do 
                                
                play_turn(reader)

                next_player()
            
            end

            @game_screen.draw


            #  ------------------------------ post game actions -------------------------------------

            # ---------------------------- increment dados statistics file ----------------------------

            dados_stats = Controller.load_dados_stats
            Logger.log.info("#{__method__}: Loaded dados stats: #{dados_stats}")
            Logger.log.info("#{__method__}: Dados_stats: #{@dados_cup.dados_stats}")

            # For each dado value count, add it to the data loaded from disk
            @dados_cup.dados_stats.each do |value, stat|

                if dados_stats[value].nil?  # data doesn't yet exist for that dado value
                    dados_stats[value] = @dados_cup.dados_stats[value]
                else  # data exists, add to it
                    dados_stats[value] = dados_stats[value] + @dados_cup.dados_stats[value]
                end
            end

            Logger.log.info("#{__method__}: New dados stats: #{dados_stats}")
            
            # Save the updated dados statistics to disk
            Controller.save_dados_stats(dados_stats)

            #  ------------------------------ game summary presentation -----------------------------------

            if turns_remaining?()  # game aborted before finishing, no high score processing or congratulatory messages
                return nil
            else

                # Declutter screen in preparation for displaying modal below. 
                # Removes the dados and the roll button
                @dados_cup.hide_all_dados()
                @game_screen.roll_button.hide()
                @game_screen.selection_cursor.hide()
                @game_screen.draw()


                # sort the players by final score descending
                players_sorted = players.sort_by do |player|
                    player.get_score(:grand_total)
                end.reverse

                # -------------------------------- high score processing --------------------------

                #load high scores from disk
                @high_scores_array = Controller.load_high_scores()  #array is already sorted reverse


                # check each player_score game result element to see if it qualifies to be added to the high scores
                players_sorted.each do |player|

                    # if the player result qualifies to be added to the high score
                    if @high_scores_array.length < Config::MAX_HIGH_SCORE_ENTRIES || player.get_score(:grand_total) > @high_scores_array.last[:score]

                        Logger.log.info("#{__method__}: Adding player_result #{player}: #{player.get_score(:grand_total)} to the high_scores_array")

                        # flag for congratulations message
                        player.set_new_high_score()
                        @new_high_scores = true

                        # add it
                        @high_scores_array.push({name: player.name(), score: player.get_score(:grand_total), new: true})

                        # sort the high scores
                        @high_scores_array = @high_scores_array.sort_by do |high_score|
                            high_score[:score]
                        end.reverse

                        #truncate the array if necessary
                        if @high_scores_array.length > Config::MAX_HIGH_SCORE_ENTRIES
                            @high_scores_array = @high_scores_array[0, Config::MAX_HIGH_SCORE_ENTRIES]
                        end

                        Logger.log.info("#{__method__}: @high_scores_array: #{@high_score_array}")
                    end
                end

                # Save the updated high scores to disk
                Controller.save_high_scores(@high_scores_array)


                
                # ---------------------------------- congratulations message -------------------------------------------


                # An array to hold one line per player, containing their finishing rank, score and whether they achieved a high score
                score_table = []

                if players.length > 1  # multiplayer game
                    
                    # Build up congratulations message
                    congratulations_message = "Congratulations #{players_sorted.first.name}!\n\nYou Win!"
                    players_sorted.each do |player|

                        # Add ordinal ranking of the player (1st, 2nd, 3rd etc)
                        if score_table.length == 0
                            score_table_line = "1st"
                        elsif score_table.length == 1
                            score_table_line = "2nd"
                        elsif score_table.length == 2
                            score_table_line = "3rd"
                        else
                            score_table_line = "#{score_table.length + 1}th"
                        end

                        # Add the player's score, and if they are tagged with a new high score flag (during high score processing above) add a HIGH SCORE indicator
                        score_table_line << ":%4d  %-5s #{player.new_high_score?() ? " HIGH SCORE" : "" }" % [player.get_score(:grand_total),player.name]
                        # Add the line to an array of player results
                        score_table.push(score_table_line)
                    end

                else  # single player game
                    # Just a congratulations message and final score, and HIGH SCORE indicator if applicable
                    congratulations_message = "Congratulations #{@players.first.name}!\n\nYou scored #{@players.first.get_score(:grand_total)}!#{@players.first.new_high_score?() ? "\nNEW HIGH SCORE" : "" }"
                end

                # ---------------------------------- display game summary ------------------------------------


                # Create a new modal to display the message
                modal = Modal.new()
                modal.final_scores(congratulations_message, score_table)

                if @new_high_scores
                    Controller.high_scores()
                end


            end

        end

    end
end