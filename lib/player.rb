require_relative("exceptions")
require_relative("player_scores")
include CincoDados

module CincoDados
    class Player

        attr_reader :scores, :name

        def initialize(name)
            @name = name
            @scores = PlayerScores.new
            @roll_count = 0
        end

        def add_score(category, score)
            @scores.add_score(category, score)
        end

        def get_score(category)
            @scores.get_score(category)
        end

        def full_card?()
            @scores.full_card?()
        end



    end
end
