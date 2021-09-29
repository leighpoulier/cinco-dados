require_relative("player_scores")
include CincoDados

module CincoDados
    class Player

        attr_reader :player_scores, :name, :player_scores_column, :roll_count

        def initialize(name)
            unless name.is_a?(String)
                raise ArgumentError.new("Please provide a string for your name.  provided name is a #{name.class.name}")
            end
            if name.length > 5
                raise ArgumentError.new("Maximum Length of name is 5 characters.  Provided name \"#{name}\" length: #{name.length}")
            end
            @name = name
            @player_scores = PlayerScores.new(@name)
        end

        def add_score(category, score)
            @player_scores.add_score(category, score)
            # Logger.log.info("Score: #{category} for player #{@name} is now #{get_score(category)}")
        end

        def get_score(category)
            @player_scores.get_score(category)
        end

        def full_card?()
            @player_scores.full_card?()
        end

        def turns_remaining?()
            return !full_card?()
        end

        def set_player_scores_column(column)
            @player_scores_column = column
        end

        def position_player_scores(game_screen, positions)
            @player_scores.position_scores(game_screen, positions)
        end

        def update_player_scores()
            @player_scores.update_scores()
        end

        def test_update_player_scores()
            @player_scores.test_update_all_scores()
        end

        def to_s()
            return @name
        end
    end
end
