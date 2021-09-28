
module CincoDados
    class Config

    GAME_SCREEN_WIDTH = 80
    GAME_SCREEN_HEIGHT = 30

    GAME_SCREEN_LEFT_MARGIN = 6
    GAME_SCREEN_TOP_MARGIN = 4
    GAME_SCREEN_DADOS_VERTICAL_SPACING = 1


    DADOS_COUNT = 5


    SCORE_CATEGORIES_UPPER = 
    [
        :ones,
        :twos,
        :threes,
        :fours,
        :fives,
        :sixes,
    ]
    SCORE_CATEGORIES_LOWER =
    [
        :three_of_a_kind,
        :four_of_a_kind,
        :full_house,
        :small_straight,
        :large_straight,
        :cinco_dados,
        :chance,
    ]

    SCORE_CATEGORIES = SCORE_CATEGORIES_UPPER.chain(SCORE_CATEGORIES_LOWER).to_a
    
    FULL_HOUSE_SCORE = 25
    SMALL_STRAIGHT_SCORE = 30
    LARGE_STRAIGHT_SCORE = 40
    CINCO_DADOS_SCORE = 50
    # CINCO_DADOS_BONUS_SCORE = 100

    UPPER_SCORE_BONUS_THRESHOLD = 63
    UPPER_SCORE_BONUS_SCORE = 35

    MAX_ROLLS_PER_TURN = 3


    end
end