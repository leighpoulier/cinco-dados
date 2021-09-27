require_relative "screen"
require_relative "control"
require_relative "logging"
require_relative "text"
require_relative "game_model"
require "tty-reader"
include CincoDados

module CincoDados

    class ScoreCard < BackgroundControl

        SCORE_CATEGORIES_UPPER = GameModel.nice_categories_upper()
        SCORE_CATEGORIES_LOWER = GameModel.nice_categories_lower()
        SCORE_CATEGORIES = SCORE_CATEGORIES_UPPER.chain(SCORE_CATEGORIES_LOWER).to_a

        ROW_LEFT_BORDER_WIDTH = 1
        ROW_RIGHT_BORDER_WIDTH = 1
        ROW_INTERNAL_BORDER_WIDTH = 1
        
        COLUMN_TOP_BORDER_WIDTH = 1
        COLUMN_BOTTOM_BORDER_WIDTH = 1
        COLUMN_INTERNAL_BORDER_WIDTH = 1

        ROW_HEADING_TEXT_WIDTH = SCORE_CATEGORIES.map do |category|
            category.to_s.length
        end.max
        PLAYER_SCORE_WIDTH = 5


        SCORE_CARD_HEIGHT = 27

        def initialize(x,y,players_names)
            super(x, y, "score_card")
            @width = ROW_LEFT_BORDER_WIDTH + ROW_HEADING_TEXT_WIDTH + (players_names.length * (PLAYER_SCORE_WIDTH + ROW_INTERNAL_BORDER_WIDTH)) + ROW_RIGHT_BORDER_WIDTH
            @height = SCORE_CARD_HEIGHT
            decorate_control(players_names)
        end

        def decorate_control(players_names)

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


            # Vertical internal lines

            left_offset = ROW_LEFT_BORDER_WIDTH + ROW_HEADING_TEXT_WIDTH
            (0...players_names.length).each do |column|
                #convert intersections in top border

                @rows[0] 
            end


            # Row headers
            

            decorate_row_headers(COLUMN_TOP_BORDER_WIDTH,ROW_LEFT_BORDER_WIDTH, ROW_HEADING_TEXT_WIDTH, style)
            
            players_names.each do |player|
                decorate_player_score_column(player, COLUMN_TOP_BORDER_WIDTH,ROW_LEFT_BORDER_WIDTH+ROW_HEADING_TEXT_WIDTH+ROW_INTERNAL_BORDER_WIDTH, 5, style)

            end

        end

        def decorate_row_headers(top_offset, left_offset, width, style)
            top_offset += 1 # blank line
            top_offset = decorate_horizontal_line(style, width, top_offset, left_offset)
            top_offset = decorate_categories(SCORE_CATEGORIES_UPPER, style, width, top_offset, left_offset)
            top_offset = decorate_horizontal_line(style, width, top_offset, left_offset)
            top_offset = decorate_text("Subtotal", style, width, top_offset, left_offset)
            top_offset = decorate_text("Bonus (min #{GameModel::UPPER_SCORE_BONUS_THRESHOLD})", style, width, top_offset, left_offset)
            top_offset = decorate_horizontal_line(style, width, top_offset, left_offset)
            top_offset = decorate_text("Upper Total", style, width, top_offset, left_offset)
            top_offset = decorate_horizontal_line(style, width, top_offset, left_offset)
            top_offset = decorate_categories(SCORE_CATEGORIES_LOWER, style, width, top_offset, left_offset)
            top_offset = decorate_horizontal_line(style, width, top_offset, left_offset)
            top_offset = decorate_text("Lower Total", style, width, top_offset, left_offset)
            top_offset = decorate_horizontal_line(style, width, top_offset, left_offset)
            top_offset = decorate_text("GRAND TOTAL", style, width, top_offset, left_offset)
        end

        def decorate_player_score_column(player, top_offset, left_offset, width, style)

        end

        def decorate_categories(categories, style, width, top_offset, left_offset)
            categories.each do |category|
                category_text=category.to_s.gsub("_", " ").split.each do |word| 
                    unless ["a", "of", "in", "and", "or"].include?(word)
                        word.capitalize!
                    end
                end.join(" ")
                top_offset = decorate_text(category_text, style, width, top_offset, left_offset)

            end
            return top_offset

        end

        def decorate_horizontal_line(style, width, top_offset, left_offset)
            
            # overwrite left outer border to join horizontal line to outer border, if possible
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


            # overwrite right outer border to join horizontal line to outer border, if possible
            # if left_offset > 0
            #     if @rows[top_offset][left_offset-1][:char] == LINE_BOLD_VERTICAL
            #         @rows[top_offset][left_offset-1][:char] = T_LEFT_BOLD_VERTICAL_LIGHT_HORIZONTAL     
            #     elsif 
            #         @rows[top_offset][left_offset-1][:char] == LINE_LIGHT_VERTICAL
            #         @rows[top_offset][left_offset-1][:char] = T_LEFT_LIGHT_VERTCIAL_LIGHT_HORIZONTAL
            #     end
            # end



            top_offset+=1
            return top_offset
        end

        def decorate_text(text, style, width, top_offset, left_offset)
            column_counter = 0
            blank_spaces = width - text.length
            # while column_counter < blank_spaces
            #     @rows[top_offset][left_offset+column_counter] = {char: :transparent, style: style}
            #     column_counter+=1
            # end
            # while column_counter < width
            #     @rows[top_offset][left_offset+column_counter] = {char: text[column_counter-blank_spaces], style: style}
            #     column_counter+=1
            # end
            row = Array.new(width, {char: :transparent, style: style})
            row = Text.right_single(row, text, style)
            @rows[top_offset][left_offset...(left_offset+width)] = row

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

players = ["WRP", "LAP", "GLP", "MAP"]

screen.add_control(ScoreCard.new(38,1,players))

while true do 

    screen.draw
    reader.read_keypress

end
