require_relative("../lib/player.rb")
include(CincoDados)


describe "Player" do

    it "requires a player name" do
        expect {Player.new() }.to raise_error(ArgumentError)
    end

    player = Player.new("Player1")

    it "starts with an empty scorecard" do
        expect(player.score_card.scores.values.tally.length).to eq(1)
        expect(player.score_card.scores.values.tally.keys).to eq([nil])
    
    end

end
