require_relative("exceptions")
require_relative("score_card")
include CincoDados

module CincoDados
    class Player

        attr_reader :score_card, :name

        def initialize(name)
            @name = name
            @score_card = ScoreCard.new
        end

        def add_score(category, score)
            @score_card.add_score(category, score)
        end

        def get_score(category)
            @score_card.get_score(category)
        end

    end
end

leigh = Player.new("Leigh")

leigh.get_score(GameModel::SCORE_CATEGORIES[0])