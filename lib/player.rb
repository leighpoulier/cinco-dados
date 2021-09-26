require_relative("exceptions")

module CincoDados
    class Player


        def initialize
            @scores =
            {
            ones: nil,
            twos: nil,
            threes: nil,
            fours: nil,
            fives: nil,
            sixes: nil,

            three_of_a_kind: nil,
            four_of_a_kind: nil,
            full_house: nil,
            small_straight: nil,
            large_straight: nil,
            cinco_dados: nil,
            chance: nil,
            }
        end

        def valid_category?(category)
            CincoDados::GameModel::SCORE_CATEGORIES.contains?(category)
        end

        def set_score(category, score)
            if valid_category?(category)
                if @scores[category].nil?
                    @scores[category] = score
                else
                    raise RuleError.new("This score is already allocated")
                end
            else
                raise CategoryError.new("Invalid category: #{category}")
            end
        end

    end
end

leigh = CincoDados::Player.new

