require_relative("../lib/player.rb")
include(CincoDados)


describe "Player" do

    player = CincoDados::Player.new

    it "starts with an empty scorecard" do

        expect(player.scores.values.tally.length).to eq(1)
        expect(player.scores.values.tally.keys).to eq([nil])
    
    end

    

end