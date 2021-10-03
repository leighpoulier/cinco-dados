require_relative("../lib/player.rb")
include(CincoDados)


describe "Player" do

    @screen = GameScreen.new()
    @game = Game.new(@screen)

    it "requires a player name" do
        expect {Player.new(@game) }.to raise_error(ArgumentError)
    end

    player = Player.new(@game, "test")

    it "starts with an empty scorecard" do

        values_tally = player.player_scores.scores.values.map do |score_table_line|
            score_table_line.value
        end.tally

        expect(values_tally.length).to eq(1)
        expect(values_tally.keys).to eq([nil])
    
    end


end
