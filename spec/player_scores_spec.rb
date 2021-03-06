require_relative("../lib/player_scores")
include(CincoDados)

Logger.set_logging_handler(:file)

describe "PlayerScores" do

    before :all do
        
        @game = Game.new(GameScreen.new())
        @player = Player.new(@game, "test1")
        @player_scores = PlayerScores.new(@game, @player)

    end

    context "basic" do
        it "starts with an empty scorecard" do

            values_tally = @player_scores.scores.values.map do |score_table_line|
                score_table_line.value
            end.tally

            expect(values_tally.length).to eq(1)
            expect(values_tally.keys).to eq([nil])
        
        end

        it "rejects bad score categories" do
        
            # @player_scores = PlayerScores.new
            expect{@player_scores.add_score(:bad_category, 10)}.to raise_error(CincoDados::ScoreCategoryError)
            expect{@player_scores.get_score(:another_bad_category)}.to raise_error(CincoDados::ScoreCategoryError)
        
        end

        it "allows a valid category" do
            
            # @player_scores = PlayerScores.new
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES[5], 10)).to eq(10)
            expect(@player_scores.get_score(Config::SCORE_CATEGORIES[5])).to eq(10)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES[9], 10)).to eq(10)
            expect(@player_scores.get_score(Config::SCORE_CATEGORIES[9])).to eq(10)

        end

        it "rejects replacing an exising score" do
            # @player_scores = PlayerScores.new
            # expect(@player_scores.add_score(Config::SCORE_CATEGORIES[5], 10)).to eq(10)
            expect{@player_scores.add_score(Config::SCORE_CATEGORIES[5], 10) }.to raise_error(RuleError)
            # expect(@player_scores.add_score(Config::SCORE_CATEGORIES[9], 10)).to eq(10)
            expect{@player_scores.add_score(Config::SCORE_CATEGORIES[9], 10) }.to raise_error(RuleError)

        end
    end
    describe "#total_selective" do
        before :all do
            @game = Game.new(GameScreen.new())
            @player = Player.new(@game, "test1")
            @player_scores = PlayerScores.new(@game, @player)
        end

        it "returns correct totals" do
            # @player_scores = PlayerScores.new
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_UPPER)).to eq(0)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_UPPER[5], 10)).to eq(10)
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_UPPER)).to eq(10)

            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_LOWER)).to eq(0)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_LOWER[3], 30)).to eq(30)
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_LOWER)).to eq(30)

            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES)).to eq(40)
        end


        it "returns correct totals when provided with a hypothetical" do 
            # expect(@player_scores.add_score(Config::SCORE_CATEGORIES_UPPER[5], 10)).to eq(10)
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_UPPER, {ones: 3})).to eq(13)
            # expect(@player_scores.add_score(Config::SCORE_CATEGORIES_LOWER[3], 30)).to eq(30)
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_LOWER, {full_house: 25})).to eq(55)
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES_LOWER, {cinco_dados: 50})).to eq(80)
            expect(@player_scores.total_selective(Config::SCORE_CATEGORIES, {cinco_dados: 50})).to eq(90)
        end

        it "returns an error when provided with a hypothetical that already exists in the scores" do
            expect {@player_scores.total_selective(Config::SCORE_CATEGORIES_LOWER, {small_straight: 30})}.to raise_error(ArgumentError)
        end

    end

    
    
    
    
    context "totals" do

        before :each do
            @game = Game.new(GameScreen.new())
            @player = Player.new(@game, "test1")
            @player_scores = PlayerScores.new(@game, @player)
        end

        it "returns upper totals" do
            expect(@player_scores.total_upper()).to eq(0)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_UPPER[0], 3)).to eq(3)
            expect(@player_scores.total_upper()).to eq(3)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_UPPER[2], 9)).to eq(9)
            expect(@player_scores.total_upper()).to eq(12)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_UPPER[4], 15)).to eq(15)
            expect(@player_scores.total_upper()).to eq(27)

        end
        
        it "correctly calculates a successful bonus" do
            (1..6).each do |value|
                expect(@player_scores.bonus).to eq(nil)
            @player_scores.add_score(Config::SCORE_CATEGORIES[value -1], value * 3)
            end
            expect(@player_scores.subtotal_upper).to eq(63)
            expect(@player_scores.bonus).to eq(35)
        end

        it "correctly calculates a failed bonus" do
            (1..6).each do |value|
                expect(@player_scores.bonus).to eq(nil)
            @player_scores.add_score(Config::SCORE_CATEGORIES[value -1], value * 2)
            end
            expect(@player_scores.subtotal_upper).to eq(42)
            expect(@player_scores.bonus).to eq(0)
        end


        it "returns lower totals" do
            expect(@player_scores.total_lower()).to eq(0)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_LOWER[0],25)).to eq(25)
            expect(@player_scores.total_lower()).to eq(25)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_LOWER[1],30)).to eq(30)
            expect(@player_scores.total_lower()).to eq(55)
            expect(@player_scores.add_score(Config::SCORE_CATEGORIES_LOWER[2],40)).to eq(40)
            expect(@player_scores.total_lower()).to eq(95)
        end
    end

    context "full card detection" do

        before :each do
                    
            @game = Game.new(GameScreen.new())
            @player = Player.new(@game, "test1")
            @player_scores = PlayerScores.new(@game, @player)

        end

        it "detects a not full card" do
                    

            expect(@player_scores.full_card?).to eq(false)

        end

        it "detects a full card" do
                    


            Config::SCORE_CATEGORIES.each do |category|
                expect(@player_scores.full_card?).to eq(false)
            @player_scores.add_score(category, 10)
            end
            expect(@player_scores.full_card?).to eq(true)
        end
    end
end