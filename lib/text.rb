module CincoDados

    class Text

        # Aligns a single line of text over a square array of styled characters

        def self.left_single(row,text,style)
            self.sanitize_arguments_single_line(row,text)
            width = row.length
            starting_column = 0
            return self.apply_text_single(text,row,starting_column,style)
        end

        def self.centre_single(row,text,style)

            self.sanitize_arguments_single_line(row,text)

            width = row.length
            starting_column = self.start_column_centre(text,width)
            return self.apply_text_single(text,row,starting_column, style)

        end

        def self.right_single(row,text,style)
            self.sanitize_arguments_single_line(row,text)
            width = row.length
            starting_column = self.start_column_right(text,width)
            return self.apply_text_single(text,row,starting_column,style)
        end

        def self.left_middle(rows,text,style)

            self.sanitize_arguments_multi_line(rows,text)

            width = rows[0].length

            middle_row = self.middle_row(rows)
            starting_column = 0
            self.apply_text_multi(text, rows, middle_row, starting_column, style)

        end

        def self.centre_middle(rows,text,style)

            # check for invalid inputs
            self.sanitize_arguments_multi_line(rows,text)

            # get the rows width, since passing the check above, all rows must be the same length
            width = rows[0].length

            middle_row = self.middle_row(rows)
            starting_column = self.start_column_centre(text, width)

            
            return self.apply_text_multi(text, rows, middle_row, starting_column, style)
        end

        def self.right_middle(rows,text,style)

            self.sanitize_arguments_multi_line(rows,text)

            width = rows[0].length

            middle_row = self.middle_row(rows)
            starting_column = self.start_column_right(text,width)
            self.apply_text_multi(text, rows, middle_row, starting_column, style)

        end

        def self.sanitize_arguments_common(row,text)
            if !row.instance_of?(Array)
                raise ArgumentError.new("rows must be an Array: rows is a #{row.class}")
            end

            if !text.instance_of?(String)
                raise ArgumentError.new("text must be a String: text is a #{text.class}")
            end  

            if text.length < 1
                raise ArgumentError.new("text must be a String of at least length:1. text.length: #{text.length}")
            end
        end

        def self.sanitize_arguments_single_line(row, text)

            self.sanitize_arguments_common(row,text)

            if text.length > row.length
                raise ArgumentError.new("text length must be less than or equal to the row length.  text.length: #{text.length}, row.length #{row.length}")
            end
        
        end

        def self.sanitize_arguments_multi_line(rows,text)

            self.sanitize_arguments_common(rows,text)

            rows.each do |row|
                if !row.instance_of?(Array)
                    raise ArgumentError.new("rows must be an Array of Arrays: one row is a #{row.class}")
                end
            end

            if !self.all_same_width(rows)
                raise ArgumentError.new("rows must contain an Array of arrays which are all the same length")
            end

            if rows.length < 1
                raise ArgumentError.new("rows must contain at least one line of styled characters. rows.length: #{rows.length}")
            end  
                
            if text.length < 1
                raise ArgumentError.new("text must be a String of at least length:1. text.length: #{text.length}")
            elsif text.length > rows[0].length
                raise ArgumentError.new("text length must be less than or equal to the max row length.  text.length: #{text.length}, row length: #{rows[0].length}")
            end

        end

        def self.all_same_width(rows)
            return rows.map do |row| row.length end.tally.length == 1
        end

        def self.middle_row(rows)
            return (rows.length-1)/2
        end

        def self.start_column_centre(text, width)
            # return ((width-1)/2 - (text.length-1)/2)
            # return ((width-1)/2 - (text.length)/2)
            if text.length == width
                return 0
            elsif (width % 2) == (text.length % 2)
                return (width/2 - text.length/2)
            else
                return ((width)/2 - (text.length+1)/2)
            end
        end

        def self.start_column_right(text, width)
            return width - text.length
        end

        def self.apply_text_single(text, row, starting_column, style)
            (0...text.length).each do |char_count|
                row[starting_column + char_count] = {char: text[char_count], style: style}
            end
            return row
        end

        def self.apply_text_multi(text, rows, middle_row, starting_column, style)
            (0...text.length).each do |char_count|
                rows[middle_row][starting_column + char_count] = {char: text[char_count], style: style}
            end
            return rows
        end
    end


end