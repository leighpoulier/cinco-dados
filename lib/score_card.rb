require_relative("game_model")
include CincoDados
module CincoDados

    class ScoreCard

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
                raise CategoryError.new("Invalid category: #{category}")
            end
        end

        def get_score(category)
            if valid_category?(category)
                return @scores[category]
            else
                raise CategoryError.new("Invalid category: #{category}")
            end
        end


    end
    
end
