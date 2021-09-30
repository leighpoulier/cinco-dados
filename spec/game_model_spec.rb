require_relative("../lib/game")
require_relative("../lib/controller")
include(CincoDados)

describe "Game Model" do

    game_screen = CincoDados::GameScreen.new()

    players = [Player.new("test")]

    game = CincoDados::Game.new(game_screen, players)

    it "detects straights" do
        expect(game.dados_cup.calculate_scores([1,2,3,4,5])).to eq({
            ones: 1, twos: 2, threes: 3, fours: 4, fives: 5, sixes: 0,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: Config::SCORE_SMALL_STRAIGHT, large_straight: Config::SCORE_LARGE_STRAIGHT, cinco_dados: 0, chance: 15
        })
        expect(game.dados_cup.calculate_scores([2,3,4,5,6])).to eq({
            ones: 0, twos: 2, threes: 3, fours: 4, fives: 5, sixes: 6,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: Config::SCORE_SMALL_STRAIGHT, large_straight: Config::SCORE_LARGE_STRAIGHT, cinco_dados: 0, chance: 20
        })
    end

    it "detects full house and three of a kind" do
        expect(game.dados_cup.calculate_scores([1,1,1,2,2])).to eq({
            ones: 3, twos: 4, threes: 0, fours: 0, fives: 0, sixes: 0,
            three_of_a_kind: 7, four_of_a_kind: 0, full_house: Config::SCORE_FULL_HOUSE,
            small_straight: 0, large_straight: 0, cinco_dados: 0, chance: 7
        })
        expect(game.dados_cup.calculate_scores([6,5,6,5,6])).to eq({
            ones: 0, twos: 0, threes: 0, fours: 0, fives: 10, sixes: 18,
            three_of_a_kind: 28, four_of_a_kind: 0, full_house: Config::SCORE_FULL_HOUSE,
            small_straight: 0, large_straight: 0, cinco_dados: 0, chance: 28
        })

    end
    
    it "detects three of a kind and four of a kind" do
        expect(game.dados_cup.calculate_scores([1,2,1,1,1])).to eq({
            ones: 4, twos: 2, threes: 0, fours: 0, fives: 0, sixes: 0,
            three_of_a_kind: 6, four_of_a_kind: 6, full_house: 0,
            small_straight: 0, large_straight: 0, cinco_dados: 0, chance: 6
        })
        expect(game.dados_cup.calculate_scores([3,3,4,3,3])).to eq({
            ones: 0, twos: 0, threes: 12, fours: 4, fives: 0, sixes: 0,
            three_of_a_kind: 16, four_of_a_kind: 16, full_house: 0,
            small_straight: 0, large_straight: 0, cinco_dados: 0, chance: 16
        })

    end
    
    it "detects small straights" do
        expect(game.dados_cup.calculate_scores([1,4,1,2,3])).to eq({
            ones: 2, twos: 2, threes: 3, fours: 4, fives: 0, sixes: 0,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: 30, large_straight: 0, cinco_dados: 0, chance: 11
        })
        expect(game.dados_cup.calculate_scores([2,3,5,4,2])).to eq({
            ones: 0, twos: 4, threes: 3, fours: 4, fives: 5, sixes: 0,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: 30, large_straight: 0, cinco_dados: 0, chance: 16
        })
        expect(game.dados_cup.calculate_scores([6,3,5,4,4])).to eq({
            ones: 0, twos: 0, threes: 3, fours: 8, fives: 5, sixes: 6,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: 30, large_straight: 0, cinco_dados: 0, chance: 22
        })
    end

    it "detects large straights" do
        expect(game.dados_cup.calculate_scores([6,2,4,3,5])).to eq({
            ones: 0, twos: 2, threes: 3, fours: 4, fives: 5, sixes: 6,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: 30, large_straight: 40, cinco_dados: 0, chance: 20
        })
        expect(game.dados_cup.calculate_scores([5,2,1,4,3])).to eq({
            ones: 1, twos: 2, threes: 3, fours: 4, fives: 5, sixes: 0,
            three_of_a_kind: 0, four_of_a_kind: 0, full_house: 0,
            small_straight: 30, large_straight: 40, cinco_dados: 0, chance: 15
        })
    end

    it "detects cinco dados" do
        expect(game.dados_cup.calculate_scores([1,1,1,1,1])).to eq({
            ones: 5, twos: 0, threes: 0, fours: 0, fives: 0, sixes: 0,
            three_of_a_kind: 5, four_of_a_kind: 5, full_house: 0,
            small_straight: 0, large_straight: 0, cinco_dados: Config::SCORE_CINCO_DADOS, chance: 5
        })
        expect(game.dados_cup.calculate_scores([4,4,4,4,4])).to eq({
            ones: 0, twos: 0, threes: 0, fours: 20, fives: 0, sixes: 0,
            three_of_a_kind: 20, four_of_a_kind: 20, full_house: 0,
            small_straight: 0, large_straight: 0, cinco_dados: Config::SCORE_CINCO_DADOS, chance: 20
        })
    end

    it "gives exceptions for bad dados array data" do
        expect { game.dados_cup.calculate_scores([]) }.to raise_error(CincoDados::DadosError)
        expect { game.dados_cup.calculate_scores(["a", "b", "c"]) }.to raise_error(CincoDados::DadosError)
        expect { game.dados_cup.calculate_scores("String") }.to raise_error(CincoDados::DadosError)
        expect { game.dados_cup.calculate_scores(5) }.to raise_error(CincoDados::DadosError)
        expect { game.dados_cup.calculate_scores(8.23) }.to raise_error(CincoDados::DadosError)
        expect { game.dados_cup.calculate_scores({test: "hash"}) }.to raise_error(CincoDados::DadosError)
    end         
end