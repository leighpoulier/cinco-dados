require "tty-reader"
require_relative "exceptions"
require_relative "config"
require_relative "dados_cup"
require_relative "screen"
require_relative "border_control"
require_relative "player"
require_relative "score_card"

module CincoDados
    class Game


        attr_reader :players, :dados_cup, :score_card

        def initialize(game_screen, players)
            @game_screen = game_screen
            @players = players
            
            # create the dados cup
            @dados_cup = DadosCup.new(@game_screen, Config::DADOS_COUNT)

            # link dados to roll button
            @dados_cup.dados.each do |dado|
                dado.add_link(EAST, @game_screen.button, false)
            end

            # link the dados cup to the the players score cells for hypothetical display
            @players.each do |player|
                Logger.log.info("Set dados_cup #{@dados_cup} on player: #{player}")
                player.player_scores.set_dados_cup(@dados_cup)
            end
            
            # create score card
            # requires a reference to game_screen so it can pass it to the score controls   
            @score_card = ScoreCard.new(38,1,@players, @game_screen)
            @game_screen.add_control(@score_card)
            
                        
            
            # Add a link from the roll button to the first players cells
            current_player = players[0]
            Config::SCORE_CATEGORIES_SORTED_FOR_ROLL_BUTTON_LINKING.each do |category|
                if current_player.player_scores.scores[category].enabled
                    @game_screen.button.add_link(EAST, current_player.player_scores.scores[category], false)
                    Logger.log.info("Add link on button to #{current_player.name} score: #{current_player.player_scores.scores[category]}")
                    break
                end
            end



            
        end

    end
end