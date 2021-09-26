require_relative("exceptions")

module CincoDados
    class Player

        attr_reader :score_card, :name

        def initialize(name)
            @name = name
            @score_card = CincoDados::ScoreCard.new
        end

        def add_score(category, score)
            @score_card.add_score(category, score)
        end

        def get_score(category)
            @score_card.get_score(category)
        end

    end
end
