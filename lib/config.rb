
module CincoDados
    class Config

    MAX_PLAYERS = 4

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

    UNICODE_DICE = {
        ones: "\u{2680}",
        twos: "\u{2681}",
        threes: "\u{2682}",
        fours: "\u{2683}",
        fives: "\u{2684}",
        sixes: "\u{2685}",
    }

    # SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING = SCORE_CATEGORIES.map.with_index.sort_by do |value, index|
    #      ((SCORE_CATEGORIES.length+1)/2 - 1 - index).abs 
    # end.map(&:first)

    # SCORE_CATEGORIES_EXCLUDE_FROM_RECOMMENDATION = 
    # [
    #     :chance,
    # ]

    SCORE_CATEGORIES_BONUS_MINIMUMS = SCORE_CATEGORIES_UPPER.map.with_index do |category, index|
        [category, (index+1) * 3]
    end.to_h

    
    SCORE_FULL_HOUSE = 25
    SCORE_SMALL_STRAIGHT = 30
    SCORE_LARGE_STRAIGHT = 40
    SCORE_CINCO_DADOS = 50
    # SCORE_CINCO_DADOS_BONUS = 100

    UPPER_SCORE_BONUS_THRESHOLD = 63
    UPPER_SCORE_BONUS_SCORE = 35

    MAX_ROLLS_PER_TURN = 3

    MAX_HIGH_SCORE_ENTRIES = 10




        # convert the categories lists (symbols) into nice printable strings.  Returns a hash of { :category => "category nice" }
        def self.nice_categories_upper()

            nice_categories_upper =  Config::SCORE_CATEGORIES_UPPER.zip(Config::SCORE_CATEGORIES_UPPER.map do |category|
                category.to_s.gsub("_"," ").split.each do |word|
                    unless ["a", "of", "in", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end
                .join(" ")
                # .sub("three of","3 of")
                # .sub("four of","4 of")
            end).to_h

            UNICODE_DICE.each do |category, unicode|
                # nice_categories_upper[category] = unicode * 3 + " " * (8-nice_categories_upper[category].length) + nice_categories_upper[category]
                nice_categories_upper[category] = nice_categories_upper[category] + " " + unicode * 3 
            end

            return nice_categories_upper

        end


        def self.nice_categories_lower()
            return Config::SCORE_CATEGORIES_LOWER.zip(Config::SCORE_CATEGORIES_LOWER.map do |category|
                category.to_s.gsub("_"," ").split.each do |word|
                    unless ["a", "of", "in", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end
                .join(" ")
                .sub("Three of","3 of")
                .sub("Four of","4 of")
            end).to_h
        end

        def self.nice_categories()
            return self.nice_categories_upper().merge(self.nice_categories_lower())
        end


    end
end