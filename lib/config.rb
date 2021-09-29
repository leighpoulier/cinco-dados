
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

    SCORE_CATEGORIES = SCORE_CATEGORIES_UPPER + SCORE_CATEGORIES_LOWER

    SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING = SCORE_CATEGORIES.map.with_index.sort_by do |value, index|
         ((SCORE_CATEGORIES.length+1)/2 - 1 - index).abs 
    end.map(&:first)

    
    FULL_HOUSE_SCORE = 25
    SMALL_STRAIGHT_SCORE = 30
    LARGE_STRAIGHT_SCORE = 40
    CINCO_DADOS_SCORE = 50
    # CINCO_DADOS_BONUS_SCORE = 100

    UPPER_SCORE_BONUS_THRESHOLD = 63
    UPPER_SCORE_BONUS_SCORE = 35

    MAX_ROLLS_PER_TURN = 3


        # convert the categories lists (symbols) into nice printable strings.  Returns a hash of { :category => "category_nice" }
        def self.nice_categories_upper()

            return Config::SCORE_CATEGORIES_UPPER.zip(Config::SCORE_CATEGORIES_UPPER.map do |category|
                category.to_s.gsub("_"," ").split.each do |word|
                    unless ["a", "of", "in", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end.join(" ").sub("three of","3 of").sub("four of","4 of")
            end).to_h
        end


        def self.nice_categories_lower()
            return Config::SCORE_CATEGORIES_LOWER.zip(Config::SCORE_CATEGORIES_LOWER.map do |category|
                category.to_s.gsub("_"," ").split.each do |word|
                    unless ["a", "of", "in", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end.join(" ").sub("Three of","3 of").sub("Four of","4 of")
            end).to_h
        end

    end
end