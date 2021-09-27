# require_relative("exceptions")
include CincoDados

class Control < SelectionCursorMapNode

    attr_reader :height, :width, :x, :y, :screen, :x_margin, :y_margin
    attr_accessor :is_selected

    def initialize(x, y, name)
        super(name)
        @x = x
        @y = y
        @x_margin = 0
        @y_margin = 0
        @printed_rows = 0
        @pastel = Pastel.new
    end

        # fill is a hash of {char: fill_char, style: [array of styles] }
    def initial_fill(fill)
        # style = [:white, :on_black]
        # fill_row = Array.new(@width, {char: fill, style: style})
        fill_row = Array.new(@width, fill)
        @rows = []
        for i in (0...@height)
            @rows[i] = fill_row.clone
        end
    end

    def draw(cursor)
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
        # if self.is_a? BorderControl
        #     self.enclosed_control.draw(cursor)
        # end
    end

    def inspect
        return "x: #{@x}, y: #{@y}, width: #{@width}, height: #{@height}"
    end

    def set_screen(screen)
        @screen = screen
    end

    def on_selected()
    end

    def on_deselected()
    end

    def activate()
    end


    def <=>(other)

        case
        when self.instance_of?(Background)
            case
            when other.instance_of?(Background)
                return 0
            when other.is_a?(Control)
                return nil
            end
        when self.instance_of?(BorderControl)
            case
            when other.instance_of?(Background)
                return +1
            when other.instance_of?(BorderControl)
                return 0
            when other.instance_of?(SelectionCursor)
                return -1
            when other.is_a?(Control)
                return +1
            else
                return nil
            end
        when self.instance_of?(SelectionCursor)
            case
            when other.instance_of?(SelectionCursor)
                return 0
            when other.instance_of?(Background) || other.instance_of?(BorderControl)
                return +1
            when other.is_a?(Control)
                return +1
            else
                return nil
            end
        when self.is_a?(Control)
            case
            when other.instance_of?(Background)
                return +1
            when other.instance_of?(BorderControl) || other.instance_of?(SelectionCursor)
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

class Background < Control

end

class Button < Control

    def initialize(x, y, width, height, fill, text, name)
        super(x, y, name)
        @width = width
        @height = height
        @text = text
        @events = {}
        

        # fill = "\u{2588}"
        # style = [:white, :on_black]
        fill = {char: "\u{2588}", style: [:white, :on_black]}
        initial_fill(fill)

        add_text_overlay([:white, :on_black, :inverse])
    end

    def add_text_overlay(style)
        # Replace centre characters witih inverse text
        middle_row = @height/2
        middle_col = @width/2
        starting_col = middle_col - (@text.length/2)
        (0...@text.length).each do |char_count|
            @rows[middle_row][starting_col + char_count] = {char: @text[char_count], style: style}
        end
    end

    def register_event(event_name, event_block)
        @events[event_name] = event_block
    end

    def on_selected()
        fill = {char: "\u{2588}", style: [:green, :on_black]}
        initial_fill(fill)
        add_text_overlay([:green, :on_black, :inverse])
    end

    def on_deselected()
        fill = {char: "\u{2588}", style: [:white, :on_black]}
        initial_fill(fill)
        add_text_overlay([:white, :on_black, :inverse])

    end

    def activate()
        unless @events[:activate].nil?
            @events[:activate].call(@screen)
        end
    end


    

end

class Dado < Control

    WIDTH = 7
    HEIGHT = 4
    X_MARGIN = 1
    Y_MARGIN = 0

    attr_reader :value


    def initialize(x, y, name)


        super(x, y, name)
        @@full_block = "\u{2588}"
        @@pip = "\u{2584}"
        
        @width = WIDTH
        @height = HEIGHT
        @x_margin = X_MARGIN
        @y_margin = Y_MARGIN
        @locked = false


        style = [:white, :on_black]
        fill = {char: @@full_block, style: style}
        initial_fill(fill)
        # initial_fill(@@full_block)

        @prng = Random.new

        @rows[height-1] = Array.new(@width, {char: "\u{1FB0E}", style: style})  #bottom half row
        
        @rows[0][0] = {char: "\u{1FB44}", style: style} #top left corner
        @rows[0][@width-1] = {char: "\u{1FB4F}", style: style} #top right corner
        @rows[@height-1][0] = {char: "\u{1FB65}", style: style} #bottom left corner
        @rows[@height-1][@width-1] = {char: "\u{1FB5A}", style: style} #bottom right corner

        roll()
        
    end

    def roll()

        unless @locked

            reset_pips_to_blank()

            @value = @prng.rand(6) + 1

            if @value < 1 || @value > 6 || !@value.instance_of?(Integer)
                raise DadosError.new("Invalid dado @value: #{@value}")
            end

            style = [:white, :on_black, :inverse]
            
            if @value == 2 || @value == 3 || @value == 4 || @value == 5 || @value == 6
                @rows[0][1] = {char: @@pip, style: style}
                @rows[2][5] = {char: @@pip, style: style}
            end
            if @value == 4 || @value == 5 || @value == 6
                @rows[0][5] = {char: @@pip, style: style}
                @rows[2][1] = {char: @@pip, style: style}
            end
            if @value == 6
                @rows[1][1] = {char: @@pip, style: style}
                @rows[1][5] = {char: @@pip, style: style}
            end
            if @value == 1 || @value == 3 || @value == 5
                @rows[1][3] = {char: @@pip, style: style}
            end
        else
            raise DadosError.new("You can't roll a locked dado")
        end
    end

    def reset_pips_to_blank()
        style = [:white, :on_black]
        (0..2).each do |row|
            [1,5].each do |side|
                @rows[row][side] = {char: @@full_block, style: style}
            end
        end
        @rows[1][3]= {char: @@full_block, style: style}
    end

    def toggle_lock()
        if @locked
            remove_lock()
        else
            add_lock()
        end
        @locked = !@locked
    end

    def add_lock()
        @locked_border = LockedBorder.new(self, "locked_" + self.name)
        @screen.add_control(@locked_border)
        Logger.log.info("New Locked Border: " + @locked_border.name + ", " + @locked_border.inspect)
    end

    def remove_lock()
        @screen.delete_control(@locked_border)
        @locked_border = nil
    end

    def locked?
        return @locked
    end

    #override
    def activate()
        toggle_lock()
    end

end

class InfoLine < Control
    def initialize(width, vertical_position)
        super(0, vertical_position, "infoLine")

        @height = 1
        @width = width


        style = [:white, :on_black]
        initial_fill({char: " ", style: style})

        @left_indent = 1

    end

    @style = [:white, :on_black]
    def display_message(message)
        (0...@width-@left_indent).each do |char_count|
            @rows[0][@left_indent + char_count] = {char: message[char_count], style: @style}
        end
    end
end
