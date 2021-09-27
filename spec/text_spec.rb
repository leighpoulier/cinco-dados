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
        expect(Text.centre_middle(rows2, "Hello", style)).to eq([
            
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

