# require_relative("exceptions")
require_relative("cursor_map")
require_relative("text")
include CincoDados
include CompassDirections

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

    attr_reader :height, :width, :x, :y, :screen, :x_margin, :y_margin
    attr_accessor :is_selected

    def initialize(name)
        super(name)
        # @x = x
        # @y = y
        @x_margin = 0
        @y_margin = 0
        # @printed_rows = 0
        @pastel = Pastel.new
    end

    def set_position(x,y)
        # Logger.log.info("Setting position of control: #{self} to x: #{x}, y:#{y} ")
        @x = x
        @y = y
    end

        # fill is a hash of {char: fill_char, style: [array of styles] }
    def initial_fill(fill)
        # style = [:white, :on_black]
        # fill_row = Array.new(@width, {char: fill, style: style})
        fill_row = Array.new(@width) { fill }
        @rows = []
        for i in (0...@height)
            @rows[i] = fill_row.clone
        end
    end

    def draw(cursor)
        if @x.nil? || @y.nil?
            raise ConfigurationError.new("Unable to draw control: #{self} with x: #{@x.inspect} and y: #{@y.inspect}")
        end
        # Logger.log.info("Drawing control: #{self} at x:#{@x} y:#{@y} with rows: #{@rows.length}")
        print cursor.move_to(@x, @y)
        @rows.each do |row|
            row.each do |charhash|
                if charhash[:char] == :transparent
                    print cursor.move(1,0)
                else
                    print @pastel.decorate(charhash[:char], *charhash[:style])
                end
            end
            print cursor.move(-1 * row.length, -1)

        end
    end

    def inspect
        # return "x: #{@x}, y: #{@y}, width: #{@width}, height: #{@height}"
        return "class=#{self.class}, name=#{@name}"
    end

    # def set_screen(screen)
    #     raise StandardError.new("What is this method used for?")
    #     @screen = screen
    # end

    def on_selected()
    end

    def on_deselected()
    end

    def on_activate()
    end



    def <=>(other)

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

    def initialize(x, y, width, height, fill, text, name)
        super(name)
        set_position(x,y)
        @width = width
        @height = height
        @text = text
        @enabled = true
        @events = {}
        
        @fill = {char: BLOCK_FULL, style: [:white, :on_black]}
        @style = [:white, :on_black, :inverse]

    end

    def add_text_overlay(style)
        # Replace centre characters witih inverse text
        # middle_row = @height/2
        # middle_col = @width/2
        # starting_col = middle_col - (@text.length/2)
        # (0...@text.length).each do |char_count|
        #     @rows[middle_row][starting_col + char_count] = {char: @text[char_count], style: style}
        # end

        @rows = Text.centre_middle(@rows,@text,style)

    end

    def decorate_control()
        initial_fill(@fill)
        add_text_overlay(@style)
    end

    def register_event(event_name, event_block)
        @events[event_name] = event_block
    end

    def on_selected()
        fill = {char: BLOCK_FULL, style: [:green, :on_black]}
        initial_fill(fill)
        add_text_overlay([:green, :on_black, :inverse])
    end

    def on_deselected()
        initial_fill(@fill)
        add_text_overlay(@style)

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
        fill = {char: BLOCK_SHADED, style: [:white, :on_black]}
        fill = {char: :transparent, style: [:white, :on_black]}
        style = [:white, :on_black]
        initial_fill(fill)
        # add_text_overlay(style)
    end

    def enable()
        super()
        initial_fill(@fill)
        add_text_overlay(@style)
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
