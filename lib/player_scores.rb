require_relative "game"
require_relative "logger"
require_relative "control"
include CincoDados
module CincoDados

    class PlayerScores

        attr_reader :scores, :totals

        def initialize(game, player_name)
            @game = game
            @scores = {}
            # @totals = {}
            previous_score = nil
            Config::SCORE_CATEGORIES.each do |category|
                new_score = Score.new(player_name + "_" + category.to_s)
                unless previous_score.nil?
                    new_score.add_link(NORTH, previous_score, true)
                end
                new_score.initial_fill
                @scores[category] = new_score
                previous_score = new_score
            end
            Logger.log.info("scores: #{@scores}")
            ScoreCard::ROW_HEADINGS_TOTALS.keys.each do |totals_row_heading|
                new_total = Total.new(player_name + "_" + totals_row_heading.to_s)
                new_total.initial_fill
                @scores[totals_row_heading] = new_total
            end
        end

        def valid_category?(category)
            Config::SCORE_CATEGORIES.include?(category)
        end

        def add_score(category, score)
            # Logger.log.info("add_score for category: #{category} with score: #{score}")
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
                return 0
            end
        end

        def total_upper(hypothetical = {})
            return subtotal_upper(hypothetical) + bonus(hypothetical)
        end

        def total_lower(hypothetical = {})
            return total_selective(Config::SCORE_CATEGORIES_LOWER,hypothetical)
        end

        def grand_total(hypothetical = {})
            return total_upper(hypothetical) + total_lower(hypothetical)
        end

        def total_selective(categories, hypothetical = {})
            sanitize_hypothetical(categories, hypothetical)

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
            @scores.values.map do |score|
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

        def position_scores(positions)
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
                @game.screen.add_control(@scores[category])
            end
        end

        def update_scores()
            @scores.each do |category, score|
                score.update_score()
            end
        end

        def update_totals()
            totals = @scores.filter do |total_name, total|
                total.instance_of?(Total)
            end
            totals.each do |total_name, score|
                score.set_value(self.send(total_name))
                score.update_score()
                Logger.log.info("Total: #{score.name} given value: #{score.value}")
            end
        end

        def test_update_all_scores()
            @scores.each do |category,score|
                score.set_value("999")
                score.update_score()
            end
        end

    end
    
    class Score < Control

        attr_reader :value
        @@style = [:white, :on_black]
        @@fill = {char: :transparent, style: @@style}

        def initialize(name)
            super(name)
            @value = nil
            @width = ScoreCard::PLAYER_SCORE_WIDTH
            @height = ScoreCard::PLAYER_SCORE_HEIGHT
        end

        def set_value(value)
            if @value.nil?
                # Logger.log.info("set_value of score #{self} to score: #{value}")
                return @value = value
            else
                raise RuleError.new("Cannot allocate to an already allocated score")
            end
        end

        def inspect()
            @value.inspect
        end

        def update_score()
            decorate_control()
        end

        def decorate_control()
            # Logger.log.info("entered decorate_control function for score #{self} with category #{category}")
            initial_fill()
            unless @value.nil?
                value_string = @value.to_s
                while value_string.length < 3
                    value_string = " " + value_string
                end
                Logger.log.info("Decorating Score Control for score: #{self} with text: #{value_string} in style: #{@@style} height: #{@height} width: #{@width}")
                @rows = Text.centre_middle(@rows,value_string,@@style)
                Logger.log.info("Resulting rows:\n#{@rows}")
            end
        end

        def initial_fill()
            super(@@fill)
        end

    end

    class Total < Score

        def initialize(name)
            super(name)
        end

        def set_value(value)
            return @value = value
        end
    end
end
