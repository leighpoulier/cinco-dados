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
        ROW_INTERNAL_BORDERS_AT = [COLUMN_TOP_BORDER_WIDTH + 1, COLUMN_TOP_BORDER_WIDTH + 1 + SCORE_CATEGORIES_UPPER.length + 1, COLUMN_TOP_BORDER_WIDTH + 1 + SCORE_CATEGORIES_UPPER.length + 4, COLUMN_TOP_BORDER_WIDTH + 1 + SCORE_CATEGORIES_UPPER.length + 6,  COLUMN_TOP_BORDER_WIDTH + 1 + SCORE_CATEGORIES_UPPER.length + 6 + SCORE_CATEGORIES_LOWER.length + 1, COLUMN_TOP_BORDER_WIDTH + 1 + SCORE_CATEGORIES_UPPER.length + 6 + SCORE_CATEGORIES_LOWER.length + 3 ]

        ROW_HEADING_TEXT_WIDTH = SCORE_CATEGORIES.map do |category|
            category.to_s.length
        end.max
        PLAYER_SCORE_WIDTH = 5



        SCORE_CARD_HEIGHT = 27

        def initialize(x,y,players_names)
            super(x, y, "score_card")
            @width = ROW_LEFT_BORDER_WIDTH + ROW_HEADING_TEXT_WIDTH + (players_names.length * (PLAYER_SCORE_WIDTH + ROW_INTERNAL_BORDER_WIDTH)) + ROW_RIGHT_BORDER_WIDTH
            @height = SCORE_CARD_HEIGHT

            @column_internal_borders_at = [ROW_LEFT_BORDER_WIDTH + ROW_HEADING_TEXT_WIDTH]
            (0...players_names.length).each do |player_counter|
                @column_internal_borders_at << ROW_LEFT_BORDER_WIDTH + ROW_HEADING_TEXT_WIDTH + (PLAYER_SCORE_WIDTH + COLUMN_INTERNAL_BORDER_WIDTH) * player_counter
            end

            decorate_control(players_names)
        end

        def decorate_control(players_names)

            style = [:white, :on_black]

            initial_fill({char: :transparent, style: style})

            # horizontal border (top and bottom)

            (1...@width-1).each do |col|
                if col > ROW_HEADING_TEXT_WIDTH + ROW_LEFT_BORDER_WIDTH
                    @rows[0][col] = { char: LINE_BOLD_HORIZONTAL, style: style}             #top row (except top left empty box)
                end
            @rows[@height - 1][col] = { char: LINE_BOLD_HORIZONTAL, style: style}           #bottom row
            end

            # vertical border (top and bottom)

            (1...@height-1).each do |row|
                if row > COLUMN_TOP_BORDER_WIDTH + 1
                    @rows[row][0] = { char: LINE_BOLD_VERTICAL, style: style}               # left side (except top left empty box)
                end
                @rows[row][@width - 1 ] = { char: LINE_BOLD_VERTICAL, style: style}         # right side
            end
    
            # 5 corners

            @rows[0][ROW_HEADING_TEXT_WIDTH + ROW_LEFT_BORDER_WIDTH] = { char: LINE_BOLD_CORNER_TOP_LEFT, style: style}     #top left corner names
            @rows[COLUMN_TOP_BORDER_WIDTH + 1][0] = { char: LINE_BOLD_CORNER_TOP_LEFT, style: style}                        #top left corner categories
            @rows[0][@width - 1] = { char: LINE_BOLD_CORNER_TOP_RIGHT, style: style}                                        #top right corner
            @rows[@height - 1][0] = { char: LINE_BOLD_CORNER_BOTTOM_LEFT, style: style}                                     #bottom left corner
            @rows[@height - 1][@width - 1] = { char: LINE_BOLD_CORNER_BOTTOM_RIGHT, style: style}                           #bottom left corner


            # Vertical internal lines and players names




            # Row headers
            

            decorate_rows(style)
            decorate_columns(players_names, style)
            

        end

        def decorate_rows(style)
            top_offset = ROW_INTERNAL_BORDERS_AT[0]
            left_offset = ROW_LEFT_BORDER_WIDTH
            heading_width = ROW_HEADING_TEXT_WIDTH
            decorate_horizontal_line_bold(style, top_offset)
            top_offset+=1
            decorate_categories(SCORE_CATEGORIES_UPPER, style, heading_width, top_offset, left_offset)
            top_offset+=SCORE_CATEGORIES_UPPER.length
            decorate_horizontal_line(style, top_offset)
            top_offset+=1
            decorate_text_right("Subtotal", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_text_right("Bonus (min #{GameModel::UPPER_SCORE_BONUS_THRESHOLD})", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_horizontal_line(style, top_offset)
            top_offset+=1
            decorate_text_right("Upper Total", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_horizontal_line_bold(style, top_offset)
            top_offset+=1
            decorate_categories(SCORE_CATEGORIES_LOWER, style, heading_width, top_offset, left_offset)
            top_offset+=SCORE_CATEGORIES_LOWER.length
            decorate_horizontal_line(style, top_offset)
            top_offset+=1
            decorate_text_right("Lower Total", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_horizontal_line_bold(style, top_offset)
            top_offset+=1
            decorate_text_right("GRAND TOTAL", style, heading_width, top_offset, left_offset)
            top_offset+=1
        end

        def decorate_categories(categories, style, width, top_offset, left_offset)
            categories.each do |category|
                # category_text=category.to_s.gsub("_", " ").split.each do |word| 
                #     unless ["a", "of", "in", "and", "or"].include?(word)
                #         word.capitalize!
                #     end
                # end.join(" ")
                decorate_text_right(category, style, width, top_offset, left_offset)
                top_offset+=1
            end

        end

        def decorate_horizontal_line_bold(style, top_offset)
            decorate_horizontal_line(style, top_offset, :bold)
        end

        def decorate_horizontal_line(style, top_offset, weight = :light)
            
            # overwrite left outer border to join horizontal line to outer border
            if @rows[top_offset][0][:char] == LINE_BOLD_VERTICAL
                if weight == :bold
                    @rows[top_offset][0][:char] = T_LEFT_BOLD_VERTICAL_BOLD_HORIZONTAL
                else
                    @rows[top_offset][0][:char] = T_LEFT_BOLD_VERTICAL_LIGHT_HORIZONTAL
                end
            elsif @rows[top_offset][0][:char] == LINE_LIGHT_VERTICAL
                if weight == :bold
                    @rows[top_offset][0][:char] = T_LEFT_LIGHT_VERTICAL_BOLD_HORIZONTAL
                else
                    @rows[top_offset][0][:char] = T_LEFT_LIGHT_VERTICAL_LIGHT_HORIZONTAL
                end
            end


            (1...@width-1).each do |column|
                if @column_internal_borders_at.include?(column)
                    if weight == :bold
                        if @rows[top_offset][column][:char] == LINE_BOLD_VERTICAL || @rows[top_offset][column][:char] == CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL
                            @rows[top_offset][column][:char] = CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL
                        else
                            @rows[top_offset][column] = {char: CROSS_LIGHT_VERTICAL_BOLD_HORIZONTAL, style: style}
                        end
                    else
                        if @rows[top_offset][column][:char] == LINE_BOLD_VERTICAL || @rows[top_offset][column][:char] == CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL
                            @rows[top_offset][column][:char] = CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL
                        elsif @rows[top_offset][column][:char] == :transparent
                            @rows[top_offset][column] = {char: CROSS_LIGHT_VERTICAL_LIGHT_HORIZONTAL, style: style}
                        end
                    end


                    # if @rows[top_offset][column][:char] == LINE_BOLD_VERTICAL || @rows[row][left_offset][:char] == CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL
                    #     if weight == :bold
                    #         @rows[top_offset][column][:char] = CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL
                    #     else
                    #         @rows[top_offset][column][:char] = CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL
                    #     end
                    # # elsif @rows[top_offset][column][:char] == LINE_LIGHT_VERTICAL
                    # else
                    #     if weight == :bold
                    #         @rows[top_offset][column] = {char: CROSS_LIGHT_VERTICAL_BOLD_HORIZONTAL, style: style}
                    #     else
                    #         @rows[top_offset][column] = {char: CROSS_LIGHT_VERTICAL_LIGHT_HORIZONTAL, style: style}
                    #     end
                    # end
                else
                    if weight == :bold
                        @rows[top_offset][column] = {char: LINE_BOLD_HORIZONTAL, style: style}
                    else
                        @rows[top_offset][column] = {char: LINE_LIGHT_HORIZONTAL, style: style}
                    end
                end
            end

            # overwrite right outer border to join horizontal line to outer border
            if @rows[top_offset][@width-1][:char] == LINE_BOLD_VERTICAL
                if weight == :bold
                    @rows[top_offset][@width-1][:char] = T_RIGHT_BOLD_VERTICAL_BOLD_HORIZONTAL
                else
                    @rows[top_offset][@width-1][:char] = T_RIGHT_BOLD_VERTICAL_LIGHT_HORIZONTAL
                end
            elsif @rows[top_offset][@width-1][:char] == LINE_LIGHT_VERTICAL
                if weight == :bold
                    @rows[top_offset][@width-1][:char] = T_RIGHT_LIGHT_VERTICAL_BOLD_HORIZONTAL
                else
                    @rows[top_offset][@width-1][:char] = T_RIGHT_LIGHT_VERTICAL_LIGHT_HORIZONTAL
                end
            end

        end

        def decorate_text(text, style, width, top_offset, left_offset, alignment = :centre)
            # column_counter = 0
            # blank_spaces = width - text.length
            # while column_counter < blank_spaces
            #     @rows[top_offset][left_offset+column_counter] = {char: :transparent, style: style}
            #     column_counter+=1
            # end
            # while column_counter < width
            #     @rows[top_offset][left_offset+column_counter] = {char: text[column_counter-blank_spaces], style: style}
            #     column_counter+=1
            # end
            row = Array.new(width, {char: :transparent, style: style})
            if alignment == :left
                row = Text.left_single(row, text, style)
            elsif alignment == :right
                row = Text.right_single(row, text, style)
            else
                row = Text.centre_single(row, text, style)
            end
            @rows[top_offset][left_offset...(left_offset+width)] = row
        end


        def decorate_text_left(text, style, width, top_offset, left_offset)
            decorate_text(text, style, width, top_offset, left_offset, :left)
        end
        def decorate_text_centre(text, style, width, top_offset, left_offset)
            decorate_text(text, style, width, top_offset, left_offset, :centre)
        end
        def decorate_text_right(text, style, width, top_offset, left_offset)
            decorate_text(text, style, width, top_offset, left_offset, :right)
        end


        def decorate_columns(players_names, style)

            
            left_offset = ROW_LEFT_BORDER_WIDTH + ROW_HEADING_TEXT_WIDTH
            counter = 0
            players_names.each do |player_name|
                if counter == 0
                    decorate_vertical_line_bold(style, left_offset)
                else 
                    decorate_vertical_line(style, left_offset)
                end
                left_offset+=1
                decorate_player_name(player_name, style, PLAYER_SCORE_WIDTH, COLUMN_TOP_BORDER_WIDTH, left_offset)
                left_offset+=PLAYER_SCORE_WIDTH
                counter+=1
            end

            # players_names.each do |players_name|
            #     #convert intersections in top border
            #     @rows[0][left_offset] = {char: T_TOP_LIGHT_VERTICAL_BOLD_HORIZONTAL, style: style}

            #     # Add player names while we are here
            #     @rows[1][(left_offset + 1)..(left_offset + PLAYER_SCORE_WIDTH)] = Text.centre_single(Array.new(PLAYER_SCORE_WIDTH, {char: :transparent, style: style}), players_name, style)

            #     # Repeated vertical lines for most of the table
            #     (1...@rows.length-1).each do |row|
            #         if ROW_INTERNAL_BORDERS_AT.include?(row)
            #             @rows[row][left_offset][:char] = CROSS_LIGHT_VERTICAL_LIGHT_HORIZONTAL
            #         else
            #             @rows[row][left_offset][:char] = LINE_LIGHT_VERTICAL
            #         end
            #     end
            #     @rows[@rows.length-1][left_offset]

            #     # convert to intersections in bottom border
            #     @rows[@rows.length-1][left_offset][:char] = T_BOTTOM_LIGHT_VERTICAL_BOLD_HORIZONTAL

            #     left_offset += PLAYER_SCORE_WIDTH + COLUMN_INTERNAL_BORDER_WIDTH
            # end
        end

        def decorate_vertical_line_bold(style, left_offset)
            decorate_vertical_line(style, left_offset, weight = :bold)
        end

        def decorate_vertical_line(style, left_offset, weight = :light)

            # overwrite top border with intersection
            if @rows[0][left_offset][:char] == LINE_BOLD_HORIZONTAL
                if weight == :bold
                    @rows[0][left_offset][:char] = T_TOP_BOLD_VERTICAL_BOLD_HORIZONTAL
                else
                    @rows[0][left_offset][:char] = T_TOP_LIGHT_VERTICAL_BOLD_HORIZONTAL
                end
            elsif @rows[0][left_offset][:char] == LINE_LIGHT_HORIZONTAL
                if weight == :bold
                    @rows[0][left_offset][:char] = T_TOP_BOLD_VERTICAL_LIGHT_HORIZONTAL
                else
                    @rows[0][left_offset][:char] = T_TOP_LIGHT_VERTICAL_LIGHT_HORIZONTAL
                end
            end

            (1...@height-1).each do |row|
                if ROW_INTERNAL_BORDERS_AT.include?(row)
                    if weight == :bold
                        if @rows[row][left_offset][:char] == LINE_BOLD_HORIZONTAL || @rows[row][left_offset][:char] == CROSS_LIGHT_VERTICAL_BOLD_HORIZONTAL
                            @rows[row][left_offset][:char] = CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL
                        else
                            @rows[row][left_offset] = {char: CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL, style: style}
                        end
                    else
                        if @rows[row][left_offset][:char] == LINE_BOLD_HORIZONTAL || @rows[row][left_offset][:char] == CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL
                            @rows[row][left_offset][:char] = CROSS_LIGHT_VERTICAL_BOLD_HORIZONTAL
                        elsif @rows[row][left_offset][:char] == :transparent
                        # else
                            @rows[row][left_offset] = {char: CROSS_LIGHT_VERTICAL_LIGHT_HORIZONTAL, style: style}
                        end
                    end

                    # if @rows[row][left_offset][:char] == LINE_BOLD_HORIZONTAL || @rows[row][left_offset][:char] == CROSS_LIGHT_VERTICAL_BOLD_HORIZONTAL
                    #     if weight == :bold
                    #         @rows[row][left_offset][:char] = CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL
                    #     else
                    #         @rows[row][left_offset][:char] = CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL
                    #     end
                    # else
                    #     if weight == :bold
                    #         @rows[row][left_offset] = {char: CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL, style: style}
                    #     else
                    #         @rows[row][left_offset] = {char: CROSS_LIGHT_VERTICAL_LIGHT_HORIZONTAL, style: style}
                    #     end
                    # end
                else
                    if weight == :bold
                        @rows[row][left_offset] = {char: LINE_BOLD_VERTICAL, style: style}
                    else
                        @rows[row][left_offset] = {char: LINE_LIGHT_VERTICAL, style: style}
                    end
                end


            end

            # overwrite bottom border with intersection
            if @rows[height-1][left_offset][:char] == LINE_BOLD_HORIZONTAL
                if weight == :bold
                    @rows[height-1][left_offset][:char] = T_BOTTOM_BOLD_VERTICAL_BOLD_HORIZONTAL
                else
                    @rows[height-1][left_offset][:char] = T_BOTTOM_LIGHT_VERTICAL_BOLD_HORIZONTAL
                end
            elsif @rows[height-1][left_offset][:char] == LINE_LIGHT_HORIZONTAL
                if weight == :bold
                    @rows[height-1][left_offset][:char] = T_BOTTOM_BOLD_VERTICAL_LIGHT_HORIZONTAL
                else
                    @rows[height-1][left_offset][:char] = T_BOTTOM_LIGHT_VERTICAL_LIGHT_HORIZONTAL
                end
            end

        end

        def decorate_player_name(player_name, style, width, top_offset, left_offset)

            decorate_text(player_name, style, width, top_offset, left_offset)


            
        end
    end

    class ScoreCell < Control

        

    end
    
end
