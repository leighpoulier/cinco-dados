require_relative("exceptions")
require_relative("config")
require_relative("dados_cup")

module CincoDados
    class GameModel


        attr_reader :game_screen

        def initialize

            @game_screen = Screen.new(Config::GAME_SCREEN_WIDTH, Config::GAME_SCREEN_HEIGHT)
            @dados_cup = DadosCup.new(self, Config::DADOS_COUNT)

            button = Button.new(20, 14, 6, 3, "\u{1FB99}", "ROLL", "roll")
            @dados_cup.dados.each do |dado|
                dado.add_link(EAST, button, false)
            end
            button.add_link(WEST, @dados_cup.dados[2], false)
            button.register_event(:activate, ->(screen) {
                @dados_cup.roll_dados()
            })
            @game_screen.add_control(button)
            
            selection_cursor = SelectionCursor.new(button, "cursor")
            @game_screen.add_control(selection_cursor)
            @game_screen.set_selection_cursor(selection_cursor)
            
            info_line = InfoLine.new(@game_screen.columns, @game_screen.rows-1)
            @game_screen.add_control(info_line)
            @game_screen.set_info_line(info_line)
            
            
            players = []
            
            player_wendy = Player.new("RC")
            player_wendy.add_score(:ones, 3)
            player_wendy.add_score(:fives, 15)
            player_wendy.add_score(:three_of_a_kind, 18)
            player_wendy.add_score(:small_straight, 30)
            player_wendy.add_score(:chance, 24)
            
            player_russ = Player.new("W")
            player_russ.add_score(:twos, 8)
            player_russ.add_score(:fives, 15)
            player_russ.add_score(:four_of_a_kind, 26)
            player_russ.add_score(:large_straight, 40)
            
            player_leigh = Player.new("L")
            player_leigh.add_score(:threes, 12)
            player_leigh.add_score(:sixes, 24)
            player_leigh.add_score(:full_house, 25)
            player_leigh.add_score(:cinco_dados, 50)
            
            players.push(player_wendy, player_russ, player_leigh)
            
            
            @game_screen.add_control(ScoreCard.new(self, 38,1,players))
            
            reader = TTY::Reader.new(interrupt: Proc.new do
                @game_screen.clean_up()
                puts "Exiting ... Goodbye!"
                exit
            end)
            
            reader.subscribe(selection_cursor)
            
            while true do 
            
                @game_screen.draw
                reader.read_keypress
            
            end
            
        end

        # def add_dados_cup(dados_cup)
        #     if dados_cup.instance_of? DadosCup
        #         @dados_cup=dados_cup
        #     else
        #         raise ArgumentError.new("Control must be an instance of DadosCup")
        #     end
        # end

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