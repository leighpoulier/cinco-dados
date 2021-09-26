require_relative("../lib/score_card.rb")
include(CincoDados)


describe "ScoreCard" do

    score_card = ScoreCard.new

    it "starts with an empty scorecard" do

        expect(score_card.scores.values.tally.length).to eq(1)
        expect(score_card.scores.values.tally.keys).to eq([nil])
    
    end

    it "rejects bad score categories" do
    
        expect {score_card.add_score(:bad_category, 10)}.to raise_error(CincoDados::CategoryError)
        expect {score_card.get_score(:another_bad_category)}.to raise_error(CincoDados::CategoryError)
    
    end

    it "allows a valid category" do
        
        expect(score_card.add_score(GameModel::SCORE_CATEGORIES[5], 10)).to eq(10)
        expect(score_card.get_score(GameModel::SCORE_CATEGORIES[5])).to eq(10)
        expect(score_card.add_score(GameModel::SCORE_CATEGORIES[9], 10)).to eq(10)
        expect(score_card.get_score(GameModel::SCORE_CATEGORIES[9])).to eq(10)

    end

    it "rejects replacing an exising score" do
        expect {score_card.add_score(GameModel::SCORE_CATEGORIES[5], 10) }.to raise_error(RuleError)
        expect {score_card.add_score(GameModel::SCORE_CATEGORIES[9], 10) }.to raise_error(RuleError)

    end

    score_card_2 = ScoreCard.new

    it "detects a not full card" do

        expect(score_card_2.full_card?).to eq(false)

    end

    it "detects a full card" do


        GameModel::SCORE_CATEGORIES.each do |category|
            expect(score_card_2.full_card?).to eq(false)
            score_card_2.add_score(category, 10)
        end
        expect(score_card_2.full_card?).to eq(true)
    end

end