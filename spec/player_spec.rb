require_relative("../lib/player.rb")
include(CincoDados)


describe "Player" do

    it "requires a player name" do
        expect {Player.new() }.to raise_error(ArgumentError)
    end

    player = Player.new("test")

    it "starts with an empty scorecard" do

        values_tally = player.player_scores.scores.values.map do |score_table_line|
            score_table_line.value
        end.tally

        expect(values_tally.length).to eq(1)
        expect(values_tally.keys).to eq([nil])
    
    end


end
