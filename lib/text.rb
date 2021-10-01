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
            starting_column = self.start_column(text.length,width, :centre)
            return self.apply_text_single(text,row,starting_column, style)

        end

        def self.right_single(row,text,style)
            self.sanitize_arguments_single_line(row,text)
            width = row.length
            starting_column = self.start_column(text.length,width, :right)
            return self.apply_text_single(text,row,starting_column,style)
        end

        # def self.left_middle(rows,text,style)

        #     self.sanitize_arguments_multi_line(rows,text)

        #     width = rows[0].length

        #     middle_row = self.middle_row(rows)
        #     starting_column = 0

        #     rows[middle_row] = self.apply_text_single(text, rows[middle_row], starting_column, style)
        #     return rows
        # end

        def self.multi_row_align(rows,text,vertical_alignment,horizontal_alignment,style)

            if !vertical_alignment.is_a?(Symbol) || ![:top, :middle, :bottom].include?(vertical_alignment)
                raise ArgumentError.new("#{__method__}: Vertical alignment \"#{vertical_alignment}\" invalid: is_a #{vertical_alignment.class.name}. Must be one of :top, :middle, :bottom")
            end
            if !horizontal_alignment.is_a?(Symbol) || ![:left, :centre, :right].include?(horizontal_alignment)
                raise ArgumentError.new("#{__method__}: Horizontal alignment \"#{horizontal_alignment}\" invalid: is_a #{horizontal_alignment.class.name}. Must be one of :left, :centre, :right")
            end
        
            # check for invalid inputs
            self.sanitize_arguments_multi_line(rows,text)

            # get the rows width, since passing the check above, all rows must be the same length
            width = rows[0].length

            if text.length > width # needs to wrap!

                Logger.log.info("#{__method__}: Attempting to wrap text: \"#{text}\" in #{rows.length} rows")

                if vertical_alignment == :top || vertical_alignment == :bottom
                    # top or bottom vertical_alignment in minimum rows
                    text_rows = get_minimum_rows(text, width)

                elsif vertical_alignment == :middle
                    # middle alignment in distrubuted rows.
                    minimum_rows_count = self.get_minimum_rows_count(text,width)
                    text_rows = self.get_evenly_distrubuted_rows(text,rows.length)
                    if text_rows.length > rows.length
                        raise ArgumentError.new("The minimum rows for text \"#{text}\" is #{text_rows.length}, you have asked for #{rows.length}.  Rows: #{text_rows}")
                    end

                end

                # calculate the vertical starting row
                start_row = self.start_row(text_rows.length, rows.length, vertical_alignment)

                # applay style to each character to build up styled character array
                (0...text_rows.length).each do |text_row_counter|

                    starting_column = self.start_column(text_rows[text_row_counter].length, width, horizontal_alignment)
                    rows[start_row + text_row_counter] = self.apply_text_single(text_rows[text_row_counter], rows[start_row + text_row_counter], starting_column, style)
                end


            else
                # fits on single row
                middle_row = self.start_row(1, rows.length, vertical_alignment)
                starting_column = self.start_column(text.length, width, horizontal_alignment)

                rows[middle_row] = self.apply_text_single(text, rows[middle_row], starting_column, style)
            end

            Logger.log.info("#{__method__}: Wrapped text: #{rows}")

            return rows

        end

        def self.get_evenly_distrubuted_rows(text, target_row_count)

            # Logger.log.info("#{__method__}: Attempting to evenly distribute \"#{text}\" in #{target_row_count} rows")

            if target_row_count > text.split.length
                # Logger.log.info("#{__method__}: Word count: #{text.split.length} < target_row_count: #{target_row_count}.  Resetting target to word count")
                target_row_count = text.split.length
                # Logger.log.info("#{__method__}: target_row_count #{target_row_count}")
            end

            target_characters_per_line = text.length / target_row_count
            # Logger.log.info("#{__method__}: target_characters_per_line: #{target_characters_per_line}")
            
            continue_loop = true
            while continue_loop
    
                rows = []
                starting_offset = 0
                split_at_character = target_characters_per_line

                while rows.length < target_row_count -1
                    # Logger.log.info("#{__method__}: rows.length: #{rows.length}, remaining text: #{text[starting_offset, split_at_character-starting_offset]}")

                    even_odd = 1
    
                    while text[split_at_character] != " "
                        # Logger.log.info("#{__method__}: Split at character: #{split_at_character}: #{text[split_at_character]}")
                        if even_odd % 2 == 0
                            #fan out searching...
                            #move back one
                            # Logger.log.info("#{__method__}: even, old split_at_character: #{split_at_character}")
                            # Logger.log.info("#{__method__}: even, even_odd: #{even_odd}")
                            split_at_character -= even_odd
                            # Logger.log.info("#{__method__}: even, new split_at_character: #{split_at_character}")
                        else
                            #move forward two, etc.
                            # Logger.log.info("#{__method__}: odd, old split_at_character: #{split_at_character}")
                            # Logger.log.info("#{__method__}: odd, even_odd: #{even_odd}")
                            split_at_character += even_odd
                            # Logger.log.info("#{__method__}: odd, new split_at_character: #{split_at_character}")
                        end
                        if split_at_character == starting_offset
                            raise StandardError.new("This logic isn't right, split at character has reduced to starting offset: #{starting_offset}")
                        elsif split_at_character > (text.length - 1)
                            raise StandardError.new("This logic isn't right, split at character has increased to the end: #{starting_offset} ")
                        end
                        even_odd += 1
                        # Logger.log.info("#{__method__}: even_odd updated to: #{even_odd}")

                    end
                    # Logger.log.info("Found space to split at character #{split_at_character}")
                    rows.push(text[starting_offset, split_at_character - starting_offset])
                    starting_offset = split_at_character + 1
                    split_at_character = starting_offset + target_characters_per_line

                end
                
                rows.push(text[starting_offset, text.length - starting_offset])

                # Logger.log.info("#{__method__}: Achieved #{rows.length} rows with target line length: #{target_characters_per_line}")
                
                if rows.length > target_row_count
                    target_characters_per_line += 1
                else
                    continue_loop = false
                end
            end

            return rows
            
        end

        def self.get_minimum_rows(text, width)

            rows = []
            if text.length > width  #splitting required?
            
                line_count = 1
                words = self.split_text_into_words_with_max_width(text,width)
                
                this_line = ""
                
                words.each do |next_word|
                    if this_line.length + 1 + next_word.length < width
                        if this_line.length == 0
                            this_line <<  next_word
                        else
                            this_line << " " << next_word
                        end
                    else
                        rows.push(this_line)
                        this_line = next_word
                    end
                end
                rows.push(this_line)
                
            else
                rows.push(text)
            end
            Logger.log.info("get_minimum_rows: #{rows}")
            return rows
        end

        def self.get_minimum_rows_count(text, width)
            return self.get_minimum_rows(text, width).length
        end

        def self.split_long_word(word, width)
            if word.length > width
                replacement_words = []
                consumed_characters = 0
                while consumed_characters < word.length
                    remaining_characters = word.length - consumed_characters
                    if remaining_characters > width
                        replacement_words.push(word[consumed_characters, width -1 ] + "-")
                        consumed_characters += (width -1)
                    else
                        replacement_words.push(word[consumed_characters, remaining_characters])
                        consumed_characters += remaining_characters
                    end
                end
                return replacement_words
            else
                return [word]
            end

        end

        def self.split_text_into_words_with_max_width(text, width)
            words = text.split
            words_index = 0
            while words_index < words.length
                if words[words_index].length > width
                    puts "long word #{words[words_index]}"
                    replacement_words = self.split_long_word(words[words_index], width)
                    words.delete_at(words_index)
                    puts "replacing with #{replacement_words}"
                    words.insert(words_index, *replacement_words)
                    words_index += replacement_words.length
                else
                    words_index += 1
                end
            end
            return words
        end

        # def self.right_middle(rows,text,style)

        #     self.sanitize_arguments_multi_line(rows,text)

        #     width = rows[0].length

        #     middle_row = self.middle_row(rows)
        #     starting_column = self.start_column_right(text.length,width)

        #     rows[middle_row] = self.apply_text_single(text, row[middle_row], starting_column, style)
        #     return rows

        # end

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
            end

            minimum_rows_count = self.get_minimum_rows_count(text, rows[0].length)
            if minimum_rows_count > rows.length
                raise ArgumentError.new("minimum rows to display text: \"#{text}\" in width: #{rows[0].length} must be less than or equal to the number of rows.  rows.length: #{rows.length}, minimum_rows_count: #{minimum_rows_count}")
            end

        end

        def self.all_same_width(rows)
            return rows.map do |row| row.length end.tally.length == 1
        end

        # def self.middle_row(rows)
        #     return (rows.length-1)/2
        # end

        # def self.start_column_centre(text_width, width)
        #     return (width - text_width)/2
        # end

        # def self.start_column_right(text_width, width)
        #     return width - text_width
        # end

        def self.start_column(text_width, width, horiztonal_alignment)
            case horiztonal_alignment

            when :left
                return 0
            when :centre
                return (width - text_width)/2
            when :right
                return width - text_width
            end

        end

        def self.start_row(text_rows, rows, vertical_alignment)
            case vertical_alignment

            when :top
                return 0
            when :middle
                return (rows - text_rows)/2
            when :bottom
                return rows - text_rows
            end
        end

        def self.apply_text_single(text, row, starting_column, style)
            (0...text.length).each do |char_count|
                row[starting_column + char_count] = {char: text[char_count], style: style}
            end
            return row
        end

        def self.sanitize_string(string)

            regex = "^" + Regexp.escape("`~!@#$%^&*()-_=+[]{}\|;:'\",.<>\/?") + "0-9a-zA-z" + "\u{A0}-\u{FE}"
            return (/[#{regex}]/ =~ string).nil?

        end
    end


end