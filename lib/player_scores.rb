require_relative("game_model")
include CincoDados
module CincoDados

    class PlayerScores

        attr_reader :scores

        def initialize
            @scores = GameModel::SCORE_CATEGORIES.to_h do |category|
                [category, nil]
            end
        end

        def valid_category?(category)
            GameModel::SCORE_CATEGORIES.include?(category)
        end

        def add_score(category, score)
            if valid_category?(category)
                if @scores[category].nil?
                    return @scores[category] = score
                else
                    raise RuleError.new("This score is already allocated")
                end
            else
                raise ScoreCategoryError.new("Invalid score category: #{category}")
            end
        end

        def get_score(category)
            if valid_category?(category)
                return @scores[category]
            else
                raise ScoreCategoryError.new("Invalid score category: #{category}")
            end
        end

        def total(hypothetical = 0)
            return total_selective(GameModel::SCORE_CATEGORIES) + hypothetical
        end

        def total_upper(hypothetical = 0)
            return total_selective(GameModel::SCORE_CATEGORIES_UPPER) + hypothetical
        end

        def total_lower(hypothetical = 0)
            return total_selective(GameModel::SCORE_CATEGORIES_LOWER) + hypothetical
        end

        def total_selective(categories)
            return
                categories.inject(0) do |sum, category|
                sum + @scores[category]
            end
        end

        def bonus(hypothetical)
            if total_lower(hypothetical) >= GameModel::UPPER_SCORE_BONUS_THRESHOLD
                return GameModel::UPPER_SCORE_BONUS_SCORE
            else
                return 0
            end
        end
        
        def full_card?()
            @scores.values.tally[nil].nil?
        end


    end
    
end
