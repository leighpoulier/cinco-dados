require_relative("../lib/player_scores")
include(CincoDados)


describe "PlayerScores" do

    player_scores = PlayerScores.new

    it "starts with an empty scorecard" do

        expect(player_scores.scores.values.tally.length).to eq(1)
        expect(player_scores.scores.values.tally.keys).to eq([nil])
    
    end

    it "rejects bad score categories" do
    
        expect {player_scores.add_score(:bad_category, 10)}.to raise_error(CincoDados::CategoryError)
        expect {player_scores.get_score(:another_bad_category)}.to raise_error(CincoDados::CategoryError)
    
    end

    it "allows a valid category" do
        
        expect(player_scores.add_score(GameModel::SCORE_CATEGORIES[5], 10)).to eq(10)
        expect(player_scores.get_score(GameModel::SCORE_CATEGORIES[5])).to eq(10)
        expect(player_scores.add_score(GameModel::SCORE_CATEGORIES[9], 10)).to eq(10)
        expect(player_scores.get_score(GameModel::SCORE_CATEGORIES[9])).to eq(10)

    end

    it "rejects replacing an exising score" do
        expect {player_scores.add_score(GameModel::SCORE_CATEGORIES[5], 10) }.to raise_error(RuleError)
        expect {player_scores.add_score(GameModel::SCORE_CATEGORIES[9], 10) }.to raise_error(RuleError)

    end

    player_scores_2 = ScoreCard.new

    it "detects a not full card" do

        expect(player_scores_2.full_card?).to eq(false)

    end

    it "detects a full card" do


        GameModel::SCORE_CATEGORIES.each do |category|
            expect(player_scores_2.full_card?).to eq(false)
            player_scores_2.add_score(category, 10)
        end
        expect(player_scores_2.full_card?).to eq(true)
    end

end