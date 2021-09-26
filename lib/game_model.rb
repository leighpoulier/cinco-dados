require_relative("exceptions")
module CincoDados
    class GameModel

        FULL_HOUSE_SCORE = 25
        SMALL_STRAIGHT_SCORE = 30
        LARGE_STRAIGHT_SCORE = 40
        CINCO_DADOS_SCORE = 50
        # CINCO_DADOS_BONUS_SCORE = 100

        def calculate_scores(dados)

            if dados.length != 5 || !dados.is_a?(Array)
                raise DadosError.new("Dados must be an array of length 5")
            end
            dados.each do |dado|
                if !dado.instance_of?(Integer)
                    raise DadosError.new("Dado value must be instance of Integer")
                end
                if dado < 1 || dado > 6
                    raise DadosError.new("Dado value must be one of 1,2,3,4,5,6")
                end
            end

            # sort the array of dados here, saves doing it many times in the methods.
            # all subsequent methdos assume a sorted array
            dados.sort!

            return\
            {
            ones: singles(dados, 1),
            twos: singles(dados, 2),
            threes: singles(dados, 3),
            fours: singles(dados, 4),
            fives: singles(dados, 5),
            sixes: singles(dados, 6),

            three_of_a_kind: of_a_kind(dados, 3),
            four_of_a_kind: of_a_kind(dados, 4),
            full_house: full_house(dados),
            small_straight: straight(dados,4),
            large_straight: straight(dados,5),
            cinco_dados: of_a_kind(dados,5),
            chance: sum(dados),
            }
            
        end

        # calculates the upper half of the scoreboard - filtering for a specific value 1-6 and then sum
        def singles(dados, value)

            dados.filter do |dado|
                dado == value
            end.sum

        end

        # calculates 3 of a kind and 4 of a kind scores
        def of_a_kind(dados,count_of_a_kind)
            tally = dados.tally

            if
                tally.any? do |value, count|
                    count >= count_of_a_kind
                end

                return count_of_a_kind < 5 ? sum(dados) : CINCO_DADOS_SCORE
            else
                return 0
            end

        end

        # calculate a full house (2 of something and 3 of something else)
        def full_house(dados)

            # tally gives a hash of { item => count of that item }
            tally = dados.tally
            # A full house contains only two unique items, so tally.length will == 2 and tally will contain values 2 and 3.
            if tally.length == 2 && tally.value?(3)
                return FULL_HOUSE_SCORE
            else
                return 0
            end

        end

        # calculate a small or large straight
        def straight(dados,length)
            sequences = dados.chunk_while do |i, j|
                i +1 == j
            end
            sequences.each do |sequence|
                if sequence.length >= length
                    if length == 4
                        return SMALL_STRAIGHT_SCORE
                    elsif length == 5
                        return LARGE_STRAIGHT_SCORE
                    end
                end
            end
            return 0
        end

        # returns the sum of all dice, used for "chance" as well as inside the of_a_kind method
        def sum(dados)
            return dados.sum
        end

    end
end