require_relative "game"
require_relative "logger"
require_relative "control"
include CincoDados
module CincoDados

    class PlayerScores

        attr_reader :scores, :totals

        def initialize(game, player)
            @game = game
            @player = player
            Logger.log.info("PlayerScores holds a @player variable which currently points to #{@player} with name #{@player.name}")
            @scores = {}

            # Add a control for the player's name at the top of the score card

            player_name_control = PlayerName.new(@game, @player)
            @scores[:player_name] = player_name_control

            previous_score = nil
            Config::SCORE_CATEGORIES.each do |category|
                # create new score object
                new_score = Score.new(self, player.name + "_" + category.to_s, category)

                # link it to the above score object (for navigation as control)
                unless previous_score.nil?
                    new_score.add_link(NORTH, previous_score, true)
                end

                # add to @scores hash
                @scores[category] = new_score

                # prepare for next loop
                previous_score = new_score
            end
            ScoreCard::ROW_HEADINGS_TOTALS.keys.each do |row_headings_totals_category|
                new_total = Total.new(player.name + "_" + row_headings_totals_category.to_s, row_headings_totals_category)
                @scores[row_headings_totals_category] = new_total
            end
            # Logger.log.info("scores: #{@scores}")
        end

        def valid_category?(category)
            (Config::SCORE_CATEGORIES + ScoreCard::ROW_HEADINGS_TOTALS.keys).include?(category)
        end

        def add_score(category, score)
            Logger.log.info("add_score for category: #{category} with score: #{score}")
            if valid_category?(category)
                if @scores[category].value.nil?
                    return_value = @scores[category].set_value(score)
                    @scores[category].update_score()
                    update_totals()
                    return return_value
                else
                    raise RuleError.new("This score is already allocated")
                end
            else
                raise ScoreCategoryError.new("Invalid score category: #{category}")
            end
        end

        def get_score(category)
            if valid_category?(category)
                return @scores[category].value
            else
                raise ScoreCategoryError.new("Invalid score category: #{category}")
            end
        end

        def total(hypothetical = {})
            return total_selective(Config::SCORE_CATEGORIES,hypothetical)
        end

        def subtotal_upper(hypothetical = {})
            return total_selective(Config::SCORE_CATEGORIES_UPPER,hypothetical)
        end

        def bonus(hypothetical = {})
            if subtotal_upper(hypothetical) >= Config::UPPER_SCORE_BONUS_THRESHOLD
                return Config::UPPER_SCORE_BONUS_SCORE
            else
                if full_section?(Config::SCORE_CATEGORIES_UPPER, hypothetical)
                    return 0
                else
                    return nil
                end
            end
        end

        def total_upper(hypothetical = {})
            bonus = bonus(hypothetical)
            if bonus.nil?
                return subtotal_upper(hypothetical)
            else
                return subtotal_upper(hypothetical) + bonus(hypothetical)
            end
        end

        def total_lower(hypothetical = {})
            return total_selective(Config::SCORE_CATEGORIES_LOWER,hypothetical)
        end

        def grand_total(hypothetical = {})
            return total_upper(hypothetical) + total_lower(hypothetical)
        end

        def total_selective(categories, hypothetical = {})
            sanitize_hypothetical(categories, hypothetical)

            # Logger.log.info("Scores: #{@scores}")
            @scores.keys.zip(@scores.values.map do |score|
                score.value
            end).to_h
            .merge(hypothetical)
            .slice(*categories)
            .values
            .compact
            .sum
        end
        
        def full_card?()
            @scores.values.filter do |score|
                score.is_a?(Score)
            end.map do |score|
                score.value
            end.tally[nil].nil?
        end

        def full_section?(categories, hypothetical = {})
            @scores.merge(hypothetical).slice(*categories).values.map do |score|
                score.value
            end.tally[nil].nil?
        end

        def sanitize_hypothetical(categories, hypothetical)
            if hypothetical.length > 0
                if !hypothetical.instance_of?(Hash)
                    raise ArgumentError.new("Hypothetical score must be a hash { category: score }")
                end
                if hypothetical.length != 1
                    raise ArgumentError.new("Hypothetical score must be a hash of length 1, actual length: #{hypothetical.length}")
                end
                if !categories.include?(hypothetical.keys[0])
                    raise ArgumentError.new("Hypothetical category must be a member of the relevent categories list.  Categories list: #{categories} category: #{hypothetical.keys[0]}")
                end
                if !scores[hypothetical.keys[0]].value.nil?
                    raise ArgumentError.new("Hypothetical category must not be already entered in players scores.  Player's score for category #{hypothetical.keys[0]} is already set to value: #{scores[hypothetical.keys[0]]}")
                end
                if !hypothetical.values[0].instance_of?(Integer)
                    raise ArgumentError.new("Hypothetical value must be an integer.  Actual instance_of: #{hypothetical.values[0].class}")
                end
            end
        end

        def position_scores(game_screen, positions)
            if !positions.instance_of?(Hash)
                raise ArgumentError.new("positions must be a hash: positions.class: #{positions.class}")
            end
            if !positions.length == Config::SCORE_CATEGORIES.length
                raise ArgumentError.new("hash must contain the same number of entries as Config::SCORE_CATEGORIES. positions.length: #{positions.length}")
            end
            if !positions.keys == Config::SCORE_CATEGORIES
                raise ArgumentError.new("hash must contain the same keys as Config::SCORE_CATEGORIES. positions.keys: #{positions.keys}")
            end
            positions.each do |category, position|
                Logger.log.info("setting position for score category: #{category}, for score: #{@scores[category]}, to [ #{position[:x]}, #{position[:y]} }")
                @scores[category].set_position(position[:x], position[:y])

                # check if this control has already been added to the screen (in case scores have already been positioned), and if not, add them
                unless game_screen.has_control?(@scores[category])
                    game_screen.add_control(@scores[category])
                end
                
                # link each selectable score (not totals) to the button to WEST
                if @scores[category].instance_of?(Score)
                    # Logger.log.info("Add link to button on score: #{scores[category]}")
                    @scores[category].add_link(WEST, game_screen.roll_button, false)
                end
            end
        end

        def set_dados_cup(dados_cup)
            # Logger.log.info("Enter set_dados_cup, going to set dados cup for scores: #{scores}")
            unless dados_cup.is_a?(DadosCup)
                raise ArgumentError.new("set_dados_cup must be passed a DadosCup instance")
            end
            @scores.each do |category, score_cell|
                # Logger.log.info("Inside loop.  Testing class of scorecell #{score_cell} with class #{score_cell.class.name}")
                if score_cell.instance_of?(Score)
                    score_cell.set_dados_cup(dados_cup)
                    # Logger.log.info("Set score_cell #{score_cell} dados_cup to dados_cup #{dados_cup}")
                end
            end

        end

        def update_scores()
            @scores.each do |category, score|
                score.update_score()
            end
        end

        def update_name_control()
            @scores[:player_name].update_score()
        end

        def update_totals()
            totals = @scores.filter do |total_name, total|
                total.instance_of?(Total)
            end
            totals.each do |total_name, score|
                score.set_value(self.send(total_name))
                score.update_score()
                # Logger.log.info("Total: #{score.name} given value: #{score.value}")
            end
        end

        def test_update_all_scores()
            @scores.each do |category,score|
                score.set_value("999")
                score.update_score()
            end
        end

        def get_empty_categories()
            get_empty_categories_from(Config::SCORE_CATEGORIES)
        end

        def get_empty_categories_upper()
            get_empty_categories_from(Config::SCORE_CATEGORIES_UPPER)
        end

        def get_empty_categories_lower()
            get_empty_categories_from(Config::SCORE_CATEGORIES_LOWER)
        end

        def get_empty_categories_from(categories)
            Config::SCORE_CATEGORIES.filter do |category|
                @scores[category].value.nil?
            end
        end

        def count_empty_categories()
            return get_empty_categories().length
        end


        def get_all_scores()

            return {scores: get_all(Score), totals: get_all(Total)}

        end

        def get_all(classss)
            scores = @scores.filter do |category, score|
                score.is_a?(classss)
            end

            return scores.keys.zip(scores.values.map do |score|
                score.value
            end).to_h
        end

    end

    class ScoreCardCell < Control

        attr_reader :value


        def initialize(name, category)
            super(name)
            @category = category
            # @dados_cup = dados_cup
            @style = [:white, :on_black]
            @fill = {char: :transparent , style: @style}
            @value = nil
            @width = ScoreCard::PLAYER_SCORE_WIDTH
            @height = ScoreCard::PLAYER_SCORE_HEIGHT

            initial_fill(@fill)
        end

        def set_value(value)
            raise StandardError.new("Should not be calling this superclass method!")
        end

        def inspect()
            self.class.name + " " + @value.inspect
        end

        def update_score()
            decorate_control(@value, @style)
        end

        # def initial_fill()
        #     super(@fill)
        # end

        def decorate_control(value, style)
            Logger.log.info("entered decorate_control function for score #{self} with category #{@category}")
            initial_fill(@fill)
            unless value.nil?
                value_string = value.to_s
                while value_string.length < 3
                    value_string = " " + value_string
                end
                @rows = Text.multi_row_align(@rows, value_string, :middle, :centre, style)
            end
        end
    end
    
    class Score < ScoreCardCell


        CONTEXT_HELP_WITH_ROLL_BUTTON = "Navigate with #{Screen::UNICODE_LEFT_ARROW}#{Screen::UNICODE_UP_ARROW}#{Screen::UNICODE_DOWN_ARROW} and Enter/Space to commit score."
        CONTEXT_HELP_NO_ROLL_BUTTON = "Navigate with #{Screen::UNICODE_UP_ARROW}#{Screen::UNICODE_DOWN_ARROW} and Enter/Space to commit score."

        def initialize(player_scores, name, category)
            super(name,category)
            @player_scores = player_scores
            @dados_cup = nil
            @selection_type = :none
        end

        def set_value(value)
            if @value.nil?
                # Logger.log.info("set_value of score #{self} to score: #{value}")
                @enabled = false
                return @value = value
            else
                raise RuleError.new("Cannot allocate to an already allocated score")
            end
        end

        def set_dados_cup(dados_cup)
            @dados_cup = dados_cup
        end

        def on_selected()
            if @dados_cup.is_a?(DadosCup)

                # get the score for the current dados
                dados_value = @dados_cup.scores[@category]

                # if the score is 0, style it yellow
                if dados_value == 0
                    style = [:yellow, :on_black, :inverse]
                else
                    style = [:green, :on_black, :inverse]
                end

                decorate_control(dados_value, style)
                Logger.log.info("Decorate score: #{self} with value #{dados_value}")
            else
                raise ConfigurationError.new("Dados cup is not a DadosCup object, it is a #{@dados_cup.class.name} class of value #{@dados_cup.inspect}")
            end
        end

        def on_deselected()
            update_score()
        end

        def on_activate()
            dados_value = @dados_cup.scores[@category]
            if dados_value == 0
                # somehow display an "are you sure" modal?
                modal = Modal.new()
                if modal.yes_no("Are you sure you want to record a zero score for #{Config::nice_categories()[@category]}?")
                    @player_scores.add_score(@category, dados_value)
                end
            else
                @player_scores.add_score(@category, dados_value)
            end
        end

        #override
        def get_context_help()
            Logger.log.info("Returning custom context help, for object #{self} of class #{self.class.name}")
            if links[WEST].disabled?
                CONTEXT_HELP_NO_ROLL_BUTTON
            else
                CONTEXT_HELP_WITH_ROLL_BUTTON
            end
        end

    end

    class Total < ScoreCardCell

        def initialize(name, category)
            super(name, category)
        end

        def set_value(value)
            return @value = value
        end
    end

    class PlayerName < ScoreCardCell

        def initialize(game, player)  # category only :player_name
            super(player.name, :player_name)
            @game = game
            @player = player
            @fill = {char: :transparent , style: @style}

            # Logger.log.info("PlayerName object passed in player: #{player} with name :#{player.name}")

        end

        def update_score()
            decorate_control()
        end

        def decorate_control()
            
            if @game.current_player == @player && @game.player_count > 1
                style = [:bright_blue, :on_black]
            else
                style = [:white, :on_black]
            end
            
            @fill = {char: " ", style: style}
            initial_fill(@fill)
            
            # @rows = Text.centre_middle(@rows,@player.name,style)
            @rows = Text.multi_row_align(@rows, @player.name, :middle, :centre, style)

            # Logger.log.info("PlayerName control has rows #{@rows}")

        end

    end
end
