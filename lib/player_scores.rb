require_relative "game"
require_relative "logger"
require_relative "control"
include CincoDados
module CincoDados

    class PlayerScores

        attr_reader :scores

        def initialize(player_name)
            @scores = {}
            previous_score = nil
            Config::SCORE_CATEGORIES.each do |category|
                new_score = Score.new(player_name + category.to_s)
                unless previous_score.nil?
                    new_score.add_link(NORTH, previous_score, true)
                end
                scores[category] = new_score
                previous_score = new_score
            end
            Logger.log.info("scores: #{@scores}")
        end

        def valid_category?(category)
            Config::SCORE_CATEGORIES.include?(category)
        end

        def add_score(category, score)
            if valid_category?(category)
                if @scores[category].value.nil?
                    return @scores[category].set_value(score)
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

        def bonus_upper(hypothetical = {})
            if subtotal_upper(hypothetical) >= Config::UPPER_SCORE_BONUS_THRESHOLD
                return Config::UPPER_SCORE_BONUS_SCORE
            else
                return 0
            end
        end

        def total_upper(hypothetical = {})
            return subtotal_upper(hypothetical) + bonus_upper(hypothetical)
        end

        def total_lower(hypothetical = {})
            return total_selective(Config::SCORE_CATEGORIES_LOWER,hypothetical)
        end

        def total_selective(categories, hypothetical = {})
            sanitize_hypothetical(categories, hypothetical)

            # Logger.log.info("@scores = #{@scores}")
            # Logger.log.info("hypothetical = #{hypothetical}")
            # Logger.log.info("@scores.merge(hypothetical) = #{@scores.merge(hypothetical)}")
            # Logger.log.info("*categories = #{categories}")
            # Logger.log.info("@scores.merge(hypothetical).slice(*categories) = #{@scores.merge(hypothetical).slice(*categories)}")
            # Logger.log.info("@scores.merge(hypothetical).slice(*categories).values = #{@scores.merge(hypothetical).slice(*categories).values}")
            # Logger.log.info("@scores.merge(hypothetical).slice(*categories).values.compact = #{@scores.merge(hypothetical).slice(*categories).values.compact}")
            # Logger.log.info("@scores.merge(hypothetical).slice(*categories).values.compact.sum = #{@scores.merge(hypothetical).slice(*categories).values.compact.sum}")

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

    end
    
    class Score < Control

        attr_reader :value

        def initialize(name)
            super(name)
            @value = nil
        end

        def set_value(value)
            if @value.nil?
                return @value = value
            else
                raise RuleError.new("Cannot allocate to an already allocated score")
            end
        end


    end
end
