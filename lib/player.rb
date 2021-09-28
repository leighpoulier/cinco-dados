require_relative("player_scores")
include CincoDados

module CincoDados
    class Player

        attr_reader :score_card, :name, :score_card_column

        def initialize(name)
            @name = name
            @score_card = PlayerScores.new(@name)
            @roll_count = 0
        end

        def add_score(category, score)
            @score_card.add_score(category, score)
        end

        def get_score(category)
            @score_card.get_score(category)
        end

        def full_card?()
            @score_card.full_card?()
        end

        def set_score_card_column(column)
            @score_card_column = column
        end

    end
end
