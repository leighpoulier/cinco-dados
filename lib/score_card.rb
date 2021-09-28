require_relative "screen"
require_relative "control"
require_relative "logging"
require_relative "text"
require_relative "config"
# require_relative "game_model"
require "tty-reader"
include CincoDados

module CincoDados

    class ScoreCard < BackgroundControl



        SCORE_CARD_HEIGHT = 27
        PLAYER_SCORE_WIDTH = 5

        ROW_LEFT_BORDER_WIDTH = 1
        ROW_RIGHT_BORDER_WIDTH = 1
        ROW_INTERNAL_BORDER_WIDTH = 1

        COLUMN_TOP_BORDER_WIDTH = 1
        COLUMN_BOTTOM_BORDER_WIDTH = 1
        COLUMN_INTERNAL_BORDER_WIDTH = 1

        def initialize(game, x, y, players)
            super(x, y, "score_card")
            @game = game
            @score_categories_upper = @game.nice_categories_upper()
            @score_categories_lower = @game.nice_categories_lower()
            @score_categories = @score_categories_upper.merge(@score_categories_lower)
            @row_heading_text_width = @score_categories.values.map do |category|
                category.to_s.length
            end.max

            @row_internal_borders_at = [COLUMN_TOP_BORDER_WIDTH + 1, COLUMN_TOP_BORDER_WIDTH + 1 + @score_categories_upper.length + 1, COLUMN_TOP_BORDER_WIDTH + 1 + @score_categories_upper.length + 4, COLUMN_TOP_BORDER_WIDTH + 1 + @score_categories_upper.length + 6,  COLUMN_TOP_BORDER_WIDTH + 1 + @score_categories_upper.length + 6 + @score_categories_lower.length + 1, COLUMN_TOP_BORDER_WIDTH + 1 + @score_categories_upper.length + 6 + @score_categories_lower.length + 3 ]
    
            @width = ROW_LEFT_BORDER_WIDTH + @row_heading_text_width + (players.length * (PLAYER_SCORE_WIDTH + ROW_INTERNAL_BORDER_WIDTH)) + ROW_RIGHT_BORDER_WIDTH
            @height = SCORE_CARD_HEIGHT

            @column_internal_borders_at = [ROW_LEFT_BORDER_WIDTH + @row_heading_text_width]
            (0...players.length).each do |player_counter|
                @column_internal_borders_at << ROW_LEFT_BORDER_WIDTH + @row_heading_text_width + (PLAYER_SCORE_WIDTH + COLUMN_INTERNAL_BORDER_WIDTH) * player_counter
            end
            @category_row_locations = {}
            decorate_control(players)
        end

        def decorate_control(players)

            style = [:white, :on_black]

            initial_fill({char: :transparent, style: style})

            # horizontal border (top and bottom)

            (1...@width-1).each do |col|
                if col > @row_heading_text_width + ROW_LEFT_BORDER_WIDTH
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

            @rows[0][@row_heading_text_width + ROW_LEFT_BORDER_WIDTH] = { char: LINE_BOLD_CORNER_TOP_LEFT, style: style}     #top left corner names
            @rows[COLUMN_TOP_BORDER_WIDTH + 1][0] = { char: LINE_BOLD_CORNER_TOP_LEFT, style: style}                        #top left corner categories
            @rows[0][@width - 1] = { char: LINE_BOLD_CORNER_TOP_RIGHT, style: style}                                        #top right corner
            @rows[@height - 1][0] = { char: LINE_BOLD_CORNER_BOTTOM_LEFT, style: style}                                     #bottom left corner
            @rows[@height - 1][@width - 1] = { char: LINE_BOLD_CORNER_BOTTOM_RIGHT, style: style}                           #bottom left corner


            # Vertical internal lines and players names




            # Row headers
            

            decorate_rows(style)
            decorate_columns(players, style)
            Logger.log.info("@category_row_locations = #{@category_row_locations}")
            

        end

        def decorate_rows(style)
            top_offset = @row_internal_borders_at[0]
            left_offset = ROW_LEFT_BORDER_WIDTH
            heading_width = @row_heading_text_width
            decorate_horizontal_line_bold(style, top_offset)
            top_offset+=1
            decorate_categories(@score_categories_upper, style, heading_width, top_offset, left_offset)
            top_offset+=@score_categories_upper.length
            decorate_horizontal_line(style, top_offset)
            top_offset+=1
            decorate_text_right("Subtotal", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_text_right("Bonus (min #{Config::UPPER_SCORE_BONUS_THRESHOLD})", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_horizontal_line(style, top_offset)
            top_offset+=1
            decorate_text_right("Upper Total", style, heading_width, top_offset, left_offset)
            top_offset+=1
            decorate_horizontal_line_bold(style, top_offset)
            top_offset+=1
            decorate_categories(@score_categories_lower, style, heading_width, top_offset, left_offset)
            top_offset+=@score_categories_lower.length
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
            categories.each do |category, category_nice|
                # category_text=category.to_s.gsub("_", " ").split.each do |word| 
                #     unless ["a", "of", "in", "and", "or"].include?(word)
                #         word.capitalize!
                #     end
                # end.join(" ")
                decorate_text_right(category_nice, style, width, top_offset, left_offset)
                @category_row_locations[category] = top_offset
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

        def decorate_columns(players, style)

            
            left_offset = ROW_LEFT_BORDER_WIDTH + @row_heading_text_width
            counter = 0
            players.each do |player|
                player.set_score_card_column(left_offset)
                if counter == 0
                    decorate_vertical_line_bold(style, left_offset)
                else 
                    decorate_vertical_line(style, left_offset)
                end
                left_offset+=1
                decorate_player_name(player.name, style, PLAYER_SCORE_WIDTH, COLUMN_TOP_BORDER_WIDTH, left_offset)
                left_offset+=PLAYER_SCORE_WIDTH
                counter+=1
            end
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
                if @row_internal_borders_at.include?(row)
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

end
