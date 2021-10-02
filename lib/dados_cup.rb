require_relative "game"
require_relative "config"
require_relative "dado"

module CincoDados
    class DadosCup

        attr_reader :dados, :scores, :dados_stats

        def initialize(game_screen, dados_count)
            @game_screen = game_screen
            @dados = []
            @scores = {}
            @dados_stats = {roll1: 0, roll2: 0, roll3: 0, roll4: 0, roll5: 0, roll6: 0}

            previous_dado = nil
            (0...dados_count).each do |dados_counter|
                dado = Dado.new(game_screen, self, Config::GAME_SCREEN_LEFT_MARGIN, Config::GAME_SCREEN_TOP_MARGIN + dados_counter * (Dado::HEIGHT + Config::GAME_SCREEN_DADOS_VERTICAL_SPACING ), "dado" + dados_counter.to_s)
                @dados.push(dado)
                game_screen.add_control(dado)
                unless previous_dado.nil?
                    dado.add_link(NORTH, previous_dado, true)
                end
                previous_dado = dado
            end

            update_dados_values()
        end


        def calculate_scores(dados_values = @dados_values)

            # sort the array of dados here, saves doing it many times in the methods.
            # all subsequent methdos assume a sorted array
            # dados_values = @dados_values.sort
            
            if !dados_values.is_a?(Array) || dados_values.length != 5
                raise DadosError.new("dados_values must be an array of length 5")
            end
            dados_values.each do |dado|
                if !dado.instance_of?(Integer)
                    raise DadosError.new("Dado value must be instance of Integer")
                end
                if dado < 1 || dado > 6
                    raise DadosError.new("Dado value must be one of 1,2,3,4,5,6")
                end
            end

            dados_values.sort!

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

                return count_of_a_kind < 5 ? sum(dados_values) : Config::SCORE_CINCO_DADOS  
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
                return Config::SCORE_FULL_HOUSE
            else
                return 0
            end

        end

        # calculate a small or large straight
        def straight(dados_values,length)

            #chunk the dados_values in to arrays, based on the block returning true for each sequential pair
            #uniq is required to remove repeats, which will break the 1+i test
            sequences = dados_values.uniq.chunk_while do |i, j|
                i +1 == j
            end

            #sequences now contains arrays of arrays of sequences.  Loop through and see if we have any length > required length to return a score.
            sequences.each do |sequence|
                if sequence.length >= length
                    if length == 4
                        return Config::SCORE_SMALL_STRAIGHT
                    elsif length == 5
                        return Config::SCORE_LARGE_STRAIGHT
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
            roll_dados_delay(0.5)
        end

        def roll_dados_no_delay()
            roll_dados_delay(0)
        end

        def roll_dados_delay(delay)

            # get the unlocked dados
            unlocked_dados = @dados.reject(&:locked?)

            unlocked_dados.each do |dado|
                # if @game_screen.has_control?(dado)
                #     @game_screen.delete_control(dado)
                # end
                dado.hide
            end

            @game_screen.draw()
            
            unlocked_dados.each do |dado|
                sleep delay
                dado.roll
                # @game_screen.add_control(dado)
                dado.show
                dado.enable
                @game_screen.draw()
            end

            update_dados_values()

            # @dados_values = [6,6,6,6,6]
            
            if cinco_dados()
                flash_dados(0.2, 2)
            end
            
            @scores = calculate_scores()
        end

        def cinco_dados()
            
            if @dados_values.tally.length == 1
                return true
            else
                return false
            end

        end

        def update_dados_values()

            @dados_values = @dados.map do |dado|
                dado.value
            end

        end

        def flash_dados(flash_delay, repeats)
            if !repeats.is_a?(Integer) || repeats < 1
                raise ArgumentError.new("repeats must be a positive integer greater than 0")
            end

            if !flash_delay.is_a?(Numeric) || flash_delay <= 0
                raise ArgumentError.new("flash_delay must be a positive number")
            end

            repeats.times do 
                sleep flash_delay
                hide_all_dados()
                hide_locks()
                @game_screen.draw()
                sleep flash_delay
                show_all_dados()
                show_locks()
                @game_screen.draw()
            end
        end

        def bonus_qualifying_upper_scores()
            return @scores.slice(*Config::SCORE_CATEGORIES_UPPER).filter do |category, score|
                score >= Config::SCORE_CATEGORIES_BONUS_MINIMUMS[category]
            end
        end

        def remove_all_locks()
            @dados.filter(&:locked?).each do |dado|
                dado.remove_lock()
            end
        end

        def disable_all_dados()
            @dados.each do |dado|
                dado.disable()
            end
        end

        def enable_all_dados()
            @dados.each do |dado|
                dado.enable()
            end
        end

        def hide_all_dados()
            @dados.each do |dado|
                # if @game_screen.has_control?(dado)
                #     @game_screen.delete_control(dado)
                # end
                dado.hide()
            end
        end

        def show_all_dados()
            @dados.each do |dado|
                # if !@game_screen.has_control?(dado)
                #     @game_screen.add_control(dado)
                # end
                dado.show()
            end
        end

        def hide_locks()
            @dados.filter(&:locked?).each(&:hide_lock)
        end

        def show_locks()
            @dados.filter(&:locked?).each(&:show_lock)
        end

        def all_locked?()
            @dados.each do |dado|
                if !dado.locked?
                    return false
                end
            end
            return true
        end

        def increment_dados_stats(value)
            Logger.log.info("#{__method__}: Increment dados_stats for dado: #{value}, current: #{@dados_stats[value]}")
            @dados_stats[value] += 1
            Logger.log.info("#{__method__}: Increment dados_stats for dado: #{value}, new: #{@dados_stats[value]}")
        end

        def to_s()
            return @dados_values.to_s
        end

    end

end