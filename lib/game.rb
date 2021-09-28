require "tty-reader"
require_relative "exceptions"
require_relative "config"
require_relative "dados_cup"
require_relative "screen"
require_relative "border_control"
require_relative "player"
require_relative "score_card"

module CincoDados
    class GameModel


        attr_reader :screen

        def initialize

            @screen = Screen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)
            @dados_cup = DadosCup.new(self, Config::DADOS_COUNT)

            button = Button.new(20, 14, 8, 3, "\u{1FB99}", "ROLL", "roll")
            @dados_cup.dados.each do |dado|
                dado.add_link(EAST, button, false)
            end
            button.add_link(WEST, @dados_cup.dados[2], false)
            button.register_event(:activate, ->(screen) {
                @dados_cup.roll_dados()
            })
            @screen.add_control(button)
            
            selection_cursor = SelectionCursor.new(button, "cursor")
            @screen.add_control(selection_cursor)
            @screen.set_selection_cursor(selection_cursor)
            
            info_line = InfoLine.new(@screen.columns, @screen.rows-1)
            @screen.add_control(info_line)
            @screen.set_info_line(info_line)
            
            
            players = []
            
            player_iryna = Player.new(self,"Iryna")
            player_iryna.add_score(:ones, 3)
            player_iryna.add_score(:fives, 15)
            player_iryna.add_score(:three_of_a_kind, 18)
            player_iryna.add_score(:small_straight, 30)
            player_iryna.add_score(:chance, 24)
            
            player_james = Player.new(self,"James")
            player_james.add_score(:twos, 8)
            player_james.add_score(:fives, 15)
            player_james.add_score(:four_of_a_kind, 26)
            player_james.add_score(:large_straight, 40)
            
            player_leigh = Player.new(self,"Leigh")
            player_leigh.add_score(:threes, 12)
            player_leigh.add_score(:fours, 16)
            player_leigh.add_score(:fives, 15)
            player_leigh.add_score(:sixes, 24)
            player_leigh.add_score(:full_house, 25)
            player_leigh.add_score(:cinco_dados, 50)
            
            players.push(player_iryna, player_james, player_leigh)
            
            
            @screen.add_control(ScoreCard.new(self, 38,1,players))
            

            
        end

        # convert the categories lists (symbols) into nice printable strings.  Returns a hash of { :category => "category_nice" }
        def nice_categories_upper()

            return Config::SCORE_CATEGORIES_UPPER.zip(Config::SCORE_CATEGORIES_UPPER.map do |category|
                category.to_s.gsub("_"," ").split.each do |word|
                    unless ["a", "of", "in", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end.join(" ").sub("three of","3 of").sub("four of","4 of")
            end).to_h
        end


        def nice_categories_lower()
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