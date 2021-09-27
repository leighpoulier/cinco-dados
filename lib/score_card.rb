require_relative "screen"
require_relative "control"
require_relative "logging"
require_relative "game_model"
require "tty-reader"
include CincoDados

module CincoDados

    class ScoreCard < BackgroundControl
            
        ROW_HEADING_WIDTH = 14
        PLAYER_SCORE_WIDTH = 6
        ROW_FOOTER_WIDTH = 1

        SCORE_CARD_HEIGHT = 25

        def initialize(x,y,player_count)
            super(x, y, "score_card")
            @width = ROW_HEADING_WIDTH + (player_count * PLAYER_SCORE_WIDTH) + ROW_FOOTER_WIDTH
            @height = SCORE_CARD_HEIGHT
            decorate_control()
        end

        def decorate_control()

            style = [:white, :on_black]

            initial_fill({char: :transparent, style: style})

            # shorizontal border (top and bottom)

            (0...@width).each do |col|
                @rows[0][col] = { char: LINE_BOLD_HORIZONTAL, style: style}               #top row
                @rows[@height - 1][col] = { char: LINE_BOLD_HORIZONTAL, style: style}     #bottom row
            end

            # vertical border (top and bottom)

            (0...@height).each do |row|
                @rows[row][0] = { char: LINE_BOLD_VERTICAL, style: style}               # left side
                @rows[row][@width - 1 ] = { char: LINE_BOLD_VERTICAL, style: style}     # right side
            end
    
            # 4 corners

            @rows[0][0] = { char: LINE_BOLD_CORNER_TOP_LEFT, style: style}                     #top left corner
            @rows[0][@width - 1] = { char: LINE_BOLD_CORNER_TOP_RIGHT, style: style}            #top right corner
            @rows[@height - 1][0] = { char: LINE_BOLD_CORNER_BOTTOM_LEFT, style: style}           #bottom left corner
            @rows[@height - 1][@width - 1] = { char: LINE_BOLD_CORNER_BOTTOM_RIGHT, style: style} #bottom left corner

            # Row headers
            
            width = GameModel::SCORE_CATEGORIES.map do |category|
                category.to_s.length
            end.max

            # start_row = 1
            # row_counter = 0 + start_row
            # left_offset = 1

            print_row_headers(1,1, width, style)

        end

        def print_row_headers(top_offset, left_offset, width, style)
            top_offset = print_categories(GameModel::SCORE_CATEGORIES_UPPER, style, width, top_offset, left_offset)
            top_offset = print_horizontal_line(style, width, top_offset, left_offset)
            top_offset = print_text("Subtotal", style, width, top_offset, left_offset)
            top_offset = print_text("Bonus (min #{GameModel::UPPER_SCORE_BONUS_THRESHOLD})", style, width, top_offset, left_offset)
            top_offset = print_horizontal_line(style, width, top_offset, left_offset)
            top_offset = print_text("Upper Total", style, width, top_offset, left_offset)
            top_offset = print_horizontal_line(style, width, top_offset, left_offset)
            top_offset = print_categories(GameModel::SCORE_CATEGORIES_LOWER, style, width, top_offset, left_offset)
            top_offset = print_horizontal_line(style, width, top_offset, left_offset)
            top_offset = print_text("Lower Total", style, width, top_offset, left_offset)
            top_offset = print_horizontal_line(style, width, top_offset, left_offset)
            top_offset = print_text("GRAND TOTAL", style, width, top_offset, left_offset)
        end

        def print_player_column(top_offset, left_offset, width, style)
            
        end

        def print_categories(categories, style, width, top_offset, left_offset)
            categories.each do |category|
                category_text=category.to_s.gsub("_", " ").split.each do |word| 
                    unless ["a", "of", "in", "of", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end.join(" ")
                top_offset = print_text(category_text, style, width, top_offset, left_offset)

            end
            return top_offset

        end

        def print_horizontal_line(style, width, top_offset, left_offset)
            
            # overwrite outer border to join horizontal line to outer border, if possible
            if left_offset > 0
                if @rows[top_offset][left_offset-1][:char] == LINE_BOLD_VERTICAL
                    @rows[top_offset][left_offset-1][:char] = T_LEFT_BOLD_VERTICAL_LIGHT_HORIZONTAL     
                elsif 
                    @rows[top_offset][left_offset-1][:char] == LINE_LIGHT_VERTICAL
                    @rows[top_offset][left_offset-1][:char] = T_LEFT_LIGHT_VERTCIAL_LIGHT_HORIZONTAL
                end
            end


            column_counter = 0
            while column_counter < width
                @rows[top_offset][left_offset+column_counter] = {char: LINE_LIGHT_HORIZONTAL, style: style}
                column_counter+=1
            end
            top_offset+=1
            return top_offset
        end

        def print_text(text, style, width, top_offset, left_offset)
            column_counter = 0
            blank_spaces = width - text.length
            while column_counter < blank_spaces
                @rows[top_offset][left_offset+column_counter] = {char: :transparent, style: style}
                column_counter+=1
            end
            while column_counter < width
                @rows[top_offset][left_offset+column_counter] = {char: text[column_counter-blank_spaces], style: style}
                column_counter+=1
            end
            top_offset+=1
            return top_offset
        end

    end
    
end

Logger.set_logging_handler(:file)

screen = Screen.new(80,30)
reader = TTY::Reader.new(interrupt: Proc.new do
    screen.clean_up()
    puts "Exiting ... Goodbye!"
    exit
end)

screen.add_control(ScoreCard.new(38,2,4))

while true do 

    screen.draw
    reader.read_keypress

end
