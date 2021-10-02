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
            @exit_flag = false
            @new_high_scores = false
            
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

        def set_exit_flag()
            @exit_flag = true
            Logger.log.info("#{__method__}: exit_flag: #{@exit_flag}")
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
            while !@exit_flag && @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories() && @current_player_roll_count < Config::MAX_ROLLS_PER_TURN
                rolls_left = Config::MAX_ROLLS_PER_TURN - @current_player_roll_count
                @game_screen.display_message("#{@current_player}'s turn. #{rolls_left} #{rolls_left > 1 ? "rolls" : "roll"} left.  Press Enter/Space to #{@game_screen.selection_cursor.enclosed_control.get_on_activate_description()}.")
                @game_screen.draw
                reader.read_keypress
            end

            # Cleanup all locks, they aren't needed any more for this turn.
            @dados_cup.remove_all_locks()

            # 3 turns are over, but still no score added
            # Logger.log.info("#{@current_player} empty categories: #{@current_player_count_empty_categories}")
            if  !@exit_flag && @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()

                #select the recommended control
                @game_screen.selection_cursor.select_control(@current_player.player_scores.scores[get_recommended_score_category()])


                # Disable the roll buton
                @game_screen.roll_button.disable()
                # Hide the roll button
                @game_screen.roll_button.hide()

                # Disabled all the dice
                @dados_cup.disable_all_dados()

                # Loop until player commits a score
                while  !@exit_flag && @current_player_count_empty_categories == @current_player.player_scores.count_empty_categories()
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


            # game loop

            while turns_remaining?() && !@exit_flag do 
                
                # @@game_screen.draw()
                
                play_turn(reader)

                next_player()
            
            end

            @game_screen.draw


            dados_stats = Controller.load_dados_stats
            Logger.log.info("#{__method__}: Loaded dados stats: #{dados_stats}")
            Logger.log.info("#{__method__}: Dados_stats: #{@dados_cup.dados_stats}")
            @dados_cup.dados_stats.each do |value, stat|
                if dados_stats[value].nil?
                    dados_stats[value] = @dados_cup.dados_stats[value]
                else
                    dados_stats[value] = dados_stats[value] + @dados_cup.dados_stats[value]
                end
            end
            Logger.log.info("#{__method__}: New dados stats: #{dados_stats}")
            Controller.save_dados_stats(dados_stats)




            if turns_remaining?()  # game aborted before finishing, no high score processing or congratulatory messages
                return nil
            else

                @dados_cup.hide_all_dados()
                @game_screen.roll_button.hide()
                @game_screen.selection_cursor.hide()
                @game_screen.draw()
                # sleep 5


                # sort the players by final score
                players_sorted = players.sort_by do |player|
                    player.get_score(:grand_total)
                end.reverse



                # high score processing

                #load high scores
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

                Controller.save_high_scores(@high_scores_array)


                
                # congratulations message
                score_table = []

                if players.length > 1  # multiplayer game
                    # players_sorted = players.sort_by do |player|
                    #     player.get_score(:grand_total)
                    # end.reverse
                    congratulations_message = "Congratulations #{players_sorted.first.name}!\n\nYou Win!"
                    players_sorted.each do |player|
                        if score_table.length == 0
                            score_table_line = "1st"
                        elsif score_table.length == 1
                            score_table_line = "2nd"
                        elsif score_table.length == 2
                            score_table_line = "3rd"
                        else
                            score_table_line = "#{score_table.length + 1}th"
                        end
                        score_table_line << ":%4d  %-5s #{player.new_high_score?() ? " HIGH SCORE" : "" }" % [player.get_score(:grand_total),player.name]
                        score_table.push(score_table_line)
                    end

                else  # single player game
                    congratulations_message = "Congratulations #{@players.first.name}!\n\nYou scored #{@players.first.get_score(:grand_total)}!#{@players.first.new_high_score?() ? "\nNEW HIGH SCORE" : "" }"
                end

                modal = Modal.new()
                modal.final_scores(congratulations_message, score_table)

                if @new_high_scores
                    Controller.high_scores()
                end


            end

        end

    end
end