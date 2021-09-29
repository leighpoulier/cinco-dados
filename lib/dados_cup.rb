require_relative "game"
require_relative "config"
require_relative "dado"

module CincoDados
    class DadosCup

        attr_reader :dados, :scores

        def initialize(game_screen, dados_count)
            @dados = []
            @dados_values = []
            @scores = {}

            previous_dado = nil
            (0...dados_count).each do |dados_counter|
                dado = Dado.new(game_screen, Config::GAME_SCREEN_LEFT_MARGIN, Config::GAME_SCREEN_TOP_MARGIN + dados_counter * (Dado::HEIGHT + Config::GAME_SCREEN_DADOS_VERTICAL_SPACING ), "dado" + dados_counter.to_s)
                @dados.push(dado)
                game_screen.add_control(dado)
                unless previous_dado.nil?
                    dado.add_link(NORTH, previous_dado, true)
                end
                previous_dado = dado
            end
            roll_dados()
        end


        def calculate_scores()

            # sort the array of dados here, saves doing it many times in the methods.
            # all subsequent methdos assume a sorted array
            dados_values = @dados_values.sort

            # if !dados_values.is_a?(Array) || dados_values.length != 5
            #     raise DadosError.new("dados_values must be an array of length 5")
            # end
            # dados_values.each do |dado|
            #     if !dado.instance_of?(Integer)
            #         raise DadosError.new("Dado value must be instance of Integer")
            #     end
            #     if dado < 1 || dado > 6
            #         raise DadosError.new("Dado value must be one of 1,2,3,4,5,6")
            #     end
            # end

            # dados_values.sort!

            return {
            ones: singles(dados_values, 1),
            twos: singles(dados_values, 2),
            threes: singles(dados_values, 3),
            fours: singles(dados_values, 4),
            fives: singles(dados_values, 5),
            sixes: singles(dados_values, 6),

            three_of_a_kind: of_a_kind(dados_values, 3),
            four_of_a_kind: of_a_kind(dados_values, 4),
            full_house: full_house(dados_values),
            small_straight: straight(dados_values,4),
            large_straight: straight(dados_values,5),
            cinco_dados: of_a_kind(dados_values,5),
            chance: sum(dados_values),
            }
            
        end

        # calculates the upper half of the scoreboard - filtering for a specific value 1-6 and then sum
        def singles(dados_values, value)

            #filter for the wanted value, then sum
            dados_values.filter do |dado|
                dado == value
            end.sum

        end

        # calculates 3 of a kind and 4 of a kind scores
        def of_a_kind(dados_values,count_of_a_kind)
            # tally gives a hash of { item => count of that item }
            tally = dados_values.tally

            # if the tally of anything is over the required count
            if
                tally.any? do |value, count|
                    count >= count_of_a_kind
                end

                #return the sum of the dados_values (3 or 4) or the CINCO_dados_values_SCORE

                return count_of_a_kind < 5 ? sum(dados_values) : Config::CINCO_DADOS_SCORE
            else
                return 0
            end

        end

        # calculate a full house (2 of something and 3 of something else)
        def full_house(dados_values)

            # tally gives a hash of { item => count of that item }
            tally = dados_values.tally
            # A full house contains only two unique items, so tally.length will == 2 and tally will contain values 2 and 3.
            if tally.length == 2 && tally.value?(3)
                return Config::FULL_HOUSE_SCORE
            else
                return 0
            end

        end

        # calculate a small or large straight
        def straight(dados_values,length)

            #chunk the dados_values in to arrays, based on the block returning true for each sequential pair
            sequences = dados_values.chunk_while do |i, j|
                i +1 == j
            end

            #sequences now contains arrays of arrays of sequences.  Loop through and see if we have any length > required length to return a score.
            sequences.each do |sequence|
                if sequence.length >= length
                    if length == 4
                        return Config::SMALL_STRAIGHT_SCORE
                    elsif length == 5
                        return Config::LARGE_STRAIGHT_SCORE
                    end
                end
            end
            return 0
        end

        # returns the sum of all dice, used for "chance" as well as inside the of_a_kind method
        def sum(dados_values)
            return dados_values.sum
        end


        def roll_dados()
            # status = []
            @dados.each do |dado|
            # for dado in dados
                if !dado.locked?
                    dado.roll
                end
                # status << dado.value
            end
            @dados_values = @dados.map do |dado|
                dado.value
            end
            @scores = calculate_scores()
        end

        def to_s()
            return @dados_values.to_s
        end

    end

end