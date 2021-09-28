require_relative("player_scores")
include CincoDados

module CincoDados
    class Player

        attr_reader :score_card, :name, :score_card_column

        def initialize(game, name)
            @game = game
            @name = name
            @score_card = PlayerScores.new(@game, @name)
            @roll_count = 0
        end

        def add_score(category, score)
            @score_card.add_score(category, score)
            # Logger.log.info("Score: #{category} for player #{@name} is now #{get_score(category)}")
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

        def position_score_card(positions)
            @score_card.position_scores(positions)
        end

        def update_score_card()
            @score_card.update_scores()
        end

        def test_update_score_card()
            @score_card.test_update_all_scores()
        end
    end
end
