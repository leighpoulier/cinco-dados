# require_relative("exceptions")
require_relative("cursor_map")
require_relative("text")
require "tty-font"
include CincoDados
include CompassDirections

module CincoDados

    class Control < SelectionCursorMapNode

        BLOCK_FULL = "\u{2588}"
        BLOCK_SHADED = "\u{2592}"

        LINE_BOLD_HORIZONTAL = "\u{2501}"
        LINE_BOLD_VERTICAL = "\u{2503}"

        LINE_BOLD_CORNER_TOP_LEFT = "\u{250F}"
        LINE_BOLD_CORNER_TOP_RIGHT = "\u{2513}"
        LINE_BOLD_CORNER_BOTTOM_LEFT = "\u{2517}"
        LINE_BOLD_CORNER_BOTTOM_RIGHT = "\u{251B}"

        LINE_LIGHT_HORIZONTAL = "\u{2500}"
        LINE_LIGHT_VERTICAL = "\u{2502}"
        
        LINE_LIGHT_CORNER_TOP_LEFT = "\u{250e}"
        LINE_LIGHT_CORNER_TOP_RIGHT = "\u{2512}"
        LINE_LIGHT_CORNER_BOTTOM_LEFT = "\u{2516}"
        LINE_LIGHT_CORNER_BOTTOM_RIGHT = "\u{251A}"

        T_LEFT_LIGHT_VERTICAL_LIGHT_HORIZONTAL = "\u{251C}"
        T_LEFT_LIGHT_VERTICAL_BOLD_HORIZONTAL = "\u{251D}"
        T_LEFT_BOLD_VERTICAL_LIGHT_HORIZONTAL = "\u{2520}"
        T_LEFT_BOLD_VERTICAL_BOLD_HORIZONTAL = "\u{2523}"

        T_RIGHT_LIGHT_VERTICAL_LIGHT_HORIZONTAL = "\u{2524}"
        T_RIGHT_LIGHT_VERTICAL_BOLD_HORIZONTAL = "\u{2525}"
        T_RIGHT_BOLD_VERTICAL_LIGHT_HORIZONTAL = "\u{2528}"
        T_RIGHT_BOLD_VERTICAL_BOLD_HORIZONTAL = "\u{252B}"

        T_TOP_LIGHT_VERTICAL_LIGHT_HORIZONTAL = "\u{252C}"
        T_TOP_LIGHT_VERTICAL_BOLD_HORIZONTAL = "\u{252F}"
        T_TOP_BOLD_VERTICAL_LIGHT_HORIZONTAL = "\u{2530}"
        T_TOP_BOLD_VERTICAL_BOLD_HORIZONTAL = "\u{2533}"

        T_BOTTOM_LIGHT_VERTICAL_LIGHT_HORIZONTAL = "\u{2534}"
        T_BOTTOM_LIGHT_VERTICAL_BOLD_HORIZONTAL = "\u{2537}"
        T_BOTTOM_BOLD_VERTICAL_LIGHT_HORIZONTAL = "\u{2538}"
        T_BOTTOM_BOLD_VERTICAL_BOLD_HORIZONTAL = "\u{253B}"

        CROSS_LIGHT_VERTICAL_LIGHT_HORIZONTAL = "\u{253C}"
        CROSS_LIGHT_VERTICAL_BOLD_HORIZONTAL = "\u{253F}"
        CROSS_BOLD_VERTICAL_LIGHT_HORIZONTAL = "\u{2542}"
        CROSS_BOLD_VERTICAL_BOLD_HORIZONTAL = "\u{254B}"

        attr_reader :height, :width, :x, :y, :screen, :x_margin, :y_margin, :visible, :selection_type, :border_style, :on_pages
        # attr_accessor :is_selected

        def initialize(name)
            super(name)
            # @x = x
            # @y = y
            @x_margin = 0
            @y_margin = 0
            # @printed_rows = 0
            @visible = true
            @on_pages = [1]
            @selection_type = :box
            @border_style = [:green, :on_black]
            # @pastel = Pastel.new
        end

        def set_position(x,y)
            # Logger.log.info("Setting position of control: #{self} to x: #{x}, y:#{y} ")
            @x = x
            @y = y
        end

            # fill is a hash of {char: fill_char, style: [array of styles] }
        def initial_fill(fill)
            
            fill_row = Array.new(@width) { fill }
            @rows = []
            for i in (0...@height)
                @rows[i] = fill_row.clone
            end
        end

        def draw(cursor, pastel, x_offset, y_offset)
            if @x.nil? || @y.nil?
                raise ConfigurationError.new("Unable to draw control: #{self} with x: #{@x.inspect} and y: #{@y.inspect}")
            end
            # Logger.log.info("Drawing control: #{self} at x:#{@x} y:#{@y} with rows: #{@rows.length}")
            print cursor.move_to(@x + x_offset, @y + y_offset)
            @rows.each do |row|
                row.each do |charhash|
                    if charhash[:char] == :transparent
                        print cursor.move(1,0)
                    else
                        print pastel.decorate(charhash[:char], *charhash[:style])
                    end
                end
                print cursor.move(-1 * row.length, -1)

            end
        end

        def show()
            @visible = true
        end

        def hide()
            @visible = false
        end

        def inspect
            # return "x: #{@x}, y: #{@y}, width: #{@width}, height: #{@height}"
            return "class=#{self.class}, name=#{@name}"
        end

        def set_border_style(style)
            @border_style = style
        end


        def set_fill_style(style)
            @fill[:style] = style
        end

        def set_fill_style_selected(style)
            @fill_selected[:style] = style
        end

        def set_text_style(style)
            @text_style = style
        end

        def set_text_style_selected(style)
            @text_style_selected = style
        end

        def set_pages(pages)
            @on_pages = pages
        end

        def set_page(page)
            @on_pages = [page]
        end

        def <=>(other)

            # Logger.log.info("Comparing control #{self} of class #{self.class.name} with other control #{other} of class #{other.class.name}")

            case
            when self.is_a?(BackgroundControl)
                case
                when other.is_a?(BackgroundControl)
                    return 0
                when other.is_a?(Control)
                    return -1
                end
            when self.is_a?(BorderControl)
                case
                when other.is_a?(BackgroundControl)
                    return +1
                when other.is_a?(BorderControl)
                    return 0
                when other.is_a?(SelectionCursor)
                    return -1
                when other.is_a?(Control)
                    return +1
                else
                    return nil
                end
            when self.is_a?(SelectionCursor)
                case
                when other.is_a?(SelectionCursor)
                    return 0
                when other.is_a?(BackgroundControl) || other.is_a?(BorderControl)
                    return +1
                when other.is_a?(Control)
                    return +1
                else
                    return nil
                end
            when self.is_a?(Control)
                case
                when other.is_a?(BackgroundControl)
                    return +1
                when other.is_a?(BorderControl) || other.is_a?(SelectionCursor)
                    return -1
                when other.is_a?(Control)
                    return 0
                else
                    return nil
                end
            else
                return nil
            end
        end

    end

    class BackgroundControl < Control

        def initialize(x,y,name)
            super(name)
            set_position(x,y)
        end

    end

    class Button < Control

        def initialize(x, y, width, height, text)
            super(text)
            set_position(x,y)
            @width = width
            @height = height
            @text = text
            @events = {}
            
            @fill = {char: BLOCK_FULL, style: [:white, :on_black]}
            @fill_selected = {char: BLOCK_FULL, style: [:green, :on_black]}
            @fill_disabled = {char: BLOCK_SHADED, style: [:white, :on_black]}

            @text_style = [:white, :on_black, :inverse]
            @text_style_selected = [:green, :on_black, :inverse]


            initial_fill(@fill)
            add_text_overlay(@text_style)

        end

        def add_text_overlay(style)

            @rows = Text.multi_row_align(@rows,@text,:middle, :centre, style)

        end

        def decorate_control()
            initial_fill(@fill)
            add_text_overlay(@style)
        end

        def register_event(event_name, event_block)
            @events[event_name] = event_block
        end


        def on_selected()
            initial_fill(@fill_selected)
            add_text_overlay(@text_style_selected)
        end

        def on_deselected()
            initial_fill(@fill)
            add_text_overlay(@text_style)
        end

        def on_activate()
            if @enabled
                unless @events[:activate].nil?
                    @events[:activate].call()
                end
            end
        end

        def disable()
            super()
            initial_fill(@fill_disabled)
        end

        def enable()
            super()
            initial_fill(@fill)
            add_text_overlay(@text_style)
        end



        

    end

    class RollButton < Button

        ON_ACTIVATE_DESCRIPTION = "roll"

        def initialize(x, y, width, height, text)
            super
        end



        #override
        def get_on_activate_description()
            ON_ACTIVATE_DESCRIPTION
        end



    end

    class BackButton < Button

        ON_ACTIVATE_DESCRIPTION = "go back"

        def initialize(x, y, width, height, text)
            super
            @border_style = [:yellow, :on_black]
            @fill_selected = {char: BLOCK_FULL, style: [:yellow, :on_black]}
            @text_style_selected = [:yellow, :on_black, :inverse]
        end



        #override
        def get_on_activate_description()
            ON_ACTIVATE_DESCRIPTION
        end



    end

    class InfoLine < Control
        def initialize(width, vertical_position)
            super("infoLine")
            set_position(0,vertical_position)

            @height = 1
            @width = width

            initial_fill({char: " ", style: [:white, :on_black]})

            @left_indent = 1

        end

        @style = [:white, :on_black]
        def display_message(message)
            (0...@width-@left_indent).each do |char_count|
                @rows[0][@left_indent + char_count] = {char: message[char_count], style: @style}
            end
            Logger.log.info("InfoLine displayed message: #{message}")
        end
    end

    class BannerText < Control
        def initialize(y, text, screen_width)
            super(text)
            
            font = TTY::Font.new(:standard)
            @raw_rows = font.write(text).split("\n")

            rows_tally = @raw_rows.map(&:length).tally
            if !rows_tally.length == 1
                raise ConfigurationError.new("For some reason the generated ascii art is not square!")
            end
            
            @width = rows_tally.first.first
            @height = rows_tally.first.last


            set_position((screen_width - @width)/ 2,y)


            @style = [:white, :on_black]


            initial_fill({char: :transparent, style: @style})

            (0...@height).each do |row|
                (0...@width).each do |column|
                    if @raw_rows[row][column] != " "
                        @rows[row][column] = {char: @raw_rows[row][column], style: @style} 
                    end
                end
            end
        end
    end

    class TextControl < Control

        def initialize(x, y, width, height, vertical_alignment, horizontal_alignment, text)
        
            super(text)
            set_position(x, y)
            @width = width
            @height = height
            @vertical_alignment = vertical_alignment
            @horizontal_alignment = horizontal_alignment
            @style = [:white, :on_black]
            @fill = {char: :transparent , style: @style}
            @text = text
            decorate_control()
        end

        def initial_fill()
            super(@fill)
        end

        def decorate_control()
            # Logger.log.info("entered decorate_control function for score #{self} with category #{category}")
            initial_fill()
            unless @text == ""

                rows = Text.multi_row_align(@rows, @text, @vertical_alignment, @horizontal_alignment, @style)

                # case @alignment
                # when :left
                #     @rows = Text.left_middle(@rows,@text,@style)
                # when :centre
                #     @rows = Text.centre_middle(@rows,@text,@style)
                # when :right
                #     @rows = Text.right_middle(@rows,@text,@style)
                # end
            end
        end

    end

    class CentredTextControl < TextControl

        def initialize(y, width, height, vertical_alignment, horizontal_alignment, text,screen_width)

            @x = (screen_width - width)/ 2
            super(@x, y, width, height, vertical_alignment, horizontal_alignment, text)


        end

    end


    class ParagraphCentredTextControl < CentredTextControl

        def initialize(y, width, horizontal_alignment, text, screen_width)

            height = Text.get_minimum_rows_count(text, width)
            super(y, width, height, :top, horizontal_alignment, text, screen_width)

        end

    end
end