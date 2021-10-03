require_relative("../lib/text.rb")
include(CincoDados)


describe "Text::centre_single" do
    style = [:white, :on_black]
    row = Array.new(10, {char: :transparent, style: style})
    
    it "should centre text correctly on single line" do
        expect(Text.centre_single(row, "Hello", style)).to eq([
            {char: :transparent, style: style},
            {char: :transparent, style: style},
            {char: "H", style: style},
            {char: "e", style: style},
            {char: "l", style: style},
            {char: "l", style: style},
            {char: "o", style: style},
            {char: :transparent, style: style},
            {char: :transparent, style: style},
            {char: :transparent, style: style},
        ])
    end    
end

describe "Tex::right_single" do
    style = [:white, :on_black]
    row = Array.new(8, {char: :transparent, style: style})

    it "should right align correctly on a single line" do
        expect(Text.right_single(row, "Wassup", style)).to eq([
            {char: :transparent, style: style},
            {char: :transparent, style: style},
            {char: "W", style: style},
            {char: "a", style: style},
            {char: "s", style: style},
            {char: "s", style: style},
            {char: "u", style: style},
            {char: "p", style: style},
        ])
    end
end

describe "Text::centre_middle" do
    style = [:white, :on_black]
    rows2 = [
        Array.new(10, {char: :transparent, style: style}),
        Array.new(10, {char: :transparent, style: style}),
        Array.new(10, {char: :transparent, style: style}),
        Array.new(10, {char: :transparent, style: style}),
        ]
    

    it "should centre text correctly on multiple lines line" do
        expect(Text.multi_row_align(rows2, "Hello",:middle, :centre, style)).to eq([
            
        Array.new(10, {char: :transparent, style: style}),
        [
            {char: :transparent, style: style},
            {char: :transparent, style: style},
            {char: "H", style: style},
            {char: "e", style: style},
            {char: "l", style: style},
            {char: "l", style: style},
            {char: "o", style: style},
            {char: :transparent, style: style},
            {char: :transparent, style: style},
            {char: :transparent, style: style},
        ],
        Array.new(10, {char: :transparent, style: style}),
        Array.new(10, {char: :transparent, style: style}),
        ])
    end
end

describe "All same width" do
    
    it "should detect an array of arrays of all same length" do
        expect(Text.all_same_width([[1,2,3,4,5],[2,3,4,5,6],[3,4,5,6,7]])).to eq(true)
        expect(Text.all_same_width([["a","b","c"],["d","e","f"],["g","h","i"]])).to eq(true)
    end

    it "should detect an array of arrays of different lengths" do
        expect(Text.all_same_width([[1,2,3,4],[2,3,4,5,6],[3,4,5,6,7,8]])).to eq(false)
        expect(Text.all_same_width([["a","b"],["c","d","e","f"],["g","h","i"]])).to eq(false)
    end


end

describe "#split_long_words" do

    it "should correctly split a long word into chunks according to width" do
        expect(Text.split_long_word("Supercalifragilisticexpialidocious", 6)).to eq(["Super-", "calif-", "ragil-", "istic-", "expia-", "lidoc-", "ious",])
    end

    it "should do nothing for a word less than the width" do
        expect(Text.split_long_word("Short", 5)).to eq(["Short"])
    end

end

describe "#split_text_into_words_with_max_width" do
    it "should split text containing long words correctly" do
        expect(Text.split_text_into_words_with_max_width("This is a really long sentence and some of the words are longer than permitted, for example Supercalifragilisticexpialidocious is waaaaaaay too long", 12)).to eq(["This", "is", "a", "really", "long", "sentence", "and", "some", "of", "the", "words", "are", "longer", "than", "permitted,", "for", "example", "Supercalifr-", "agilisticex-", "pialidocious", "is", "waaaaaaay", "too", "long"])
    end
end

describe "#get_minimum_rows_count" do
    it "should calculate the rows to contain a paragraph" do
        expect(Text.get_minimum_rows_count("Please enter a name. Maximum 5 characters!", 42)).to eq(1)
        expect(Text.get_minimum_rows_count("This is a really long sentence and some of the words are longer than permitted, for example Supercalifragilisticexpialidocious is waaaaaaay too long", 12)).to eq(15)
        expect(Text.get_minimum_rows_count("This is a really long sentence and some of the words are longer than permitted, for example Supercalifragilisticexpialidocious is waaaaaaay too long", 20)).to eq(9)
        expect(Text.get_minimum_rows_count("This is a really long sentence and some of the words are longer than permitted, for example Supercalifragilisticexpialidocious is waaaaaaay too long", 30)).to eq(6)
        expect(Text.get_minimum_rows_count("This is a really long sentence and some of the words are longer than permitted, for example Supercalifragilisticexpialidocious is waaaaaaay too long", 40)).to eq(5)
    end

end


describe "#evenly_distributed_rows" do
    it "should distrubute text evenly across multiple rows" do
        expect(Text.get_evenly_distrubuted_rows("This is a really long sentence and some of the words are longer than permitted, for example Supercalifragilisticexpialidocious is waaaaaaay too long", 5)).to eq(["This is a really long sentence", "and some of the words are longer", "than permitted, for example", "Supercalifragilisticexpialidocious", "is waaaaaaay too long"])
    end
end
