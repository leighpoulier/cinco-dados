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

    def initial_fill(fill)
        style = [:white, :on_black]
        fill_row = Array.new(@width, {char: fill, style: style})
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
        if self.is_a? BorderControl
            self.enclosed_control.draw(cursor)
        end
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
        @fill = "\u{2588}"
        @text = text
        @events = {}

        initial_fill(@fill)
        add_text_overlay()
    end

    def add_text_overlay()
        # Replace centre characters witih inverse text
        middle_row = @height/2
        middle_col = @width/2
        starting_col = middle_col - (@text.length/2)
        style = [:white, :on_black]
        (0...@text.length).each do |char_count|
            @rows[middle_row][starting_col + char_count] = {char: @text[char_count], style: style}
        end
    end

    def register_event(event_name, event_block)
        @events[event_name] = event_block
    end

    def on_selected()
        @fill = "\u{1FB99}"
        initial_fill(@fill)
        add_text_overlay()
    end

    def on_deselected()
        @fill = "\u{2588}"
        initial_fill(@fill)
        add_text_overlay()

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


        initial_fill(@@full_block)

        @prng = Random.new

        style = [:white, :on_black]
        @rows[height-1] = Array.new(@width, {char: "\u{1FB0E}", style: style})
        
        @rows[0][0] = {char: "\u{1FB44}", style: style} #top left corner
        @rows[0][@width-1] = {char: "\u{1FB4F}", style: style} #top right corner
        @rows[@height-1][0] = {char: "\u{1FB65}", style: style} #bottom left corner
        @rows[@height-1][@width-1] = {char: "\u{1FB5A}", style: style} #bottom right corner

        roll
        
    end

    def roll()

        reset_pips_to_blank()

        @value = @prng.rand(6) + 1

        if @value < 1 || @value > 6 || !@value.instance_of?(Integer)
            raise "Invalid dado @value: #{@value}"
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
        $logger.info("New Locked Border: " + @locked_border.name + ", " + @locked_border.inspect)
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

        initial_fill(" ")

        @left_indent = 1

    end

    @style = [:white, :on_black]
    def display_message(message)
        (0...@width-@left_indent).each do |char_count|
            @rows[0][@left_indent + char_count] = {char: message[char_count], style: @style}
        end
    end
end

class BorderControl < Control

    attr_reader :enclosed_control

    def enclose_control()
        @width = @enclosed_control.width + 2 * (1 + @enclosed_control.x_margin)
        @height = @enclosed_control.height + 2 * (1 + @enclosed_control.y_margin)
        @x = @enclosed_control.x-@enclosed_control.x_margin-1
        @y = @enclosed_control.y-@enclosed_control.y_margin-1
    end

    def decorate_control()

        initial_fill(:transparent)

    end


end

class LockedBorder < BorderControl
    
    def initialize(control, name)

        @enclosed_control = control
        enclose_control()
        super(@x, @y, name)
        decorate_control()
    end

    def decorate_control()
        # set the border characters

        super  # initial_fil(:transparent)

        style = [:red, :on_black]

        # [1,@width-2].each do |col|
        #     @rows[0][col] = { char: "\u{2501}", style: style}  #top row
        #     @rows[height - 1][col] = { char: "\u{2501}", style: style} #bottom row
        # end

        [2].each do |row|
            @rows[row][0] = { char: "\u{2503}", style: style}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", style: style}  #right side
        end
        [3].each do |row|
            @rows[row][0] = { char: "\u{2579}", style: style}  #left side
            @rows[row][width - 1] = { char: "\u{2579}", style: style}  #right side
        end


        # @rows[0][0] = { char: "\u{250F}", style: style} #top left corner
        # @rows[0][@width - 1] = { char: "\u{2513}", style: style} #top right corner
        # @rows[@height - 1][0] = { char: "\u{2517}", style: style} #bottom left corner
        # @rows[@height - 1][@width - 1] = { char: "\u{251B}", style: style} #bottom left corner
    end

    def enclose_control()
        @width = @enclosed_control.width + 2
        @height = @enclosed_control.height + 2
        @x = @enclosed_control.x-1
        @y = @enclosed_control.y-1

    end

end

class SelectionCursor < BorderControl


    def initialize(control, name)
        select_control(control)
        super(@x, @y, name)
        
    end

    def select_control(control)
        unless @enclosed_control.nil?
            @enclosed_control.is_selected = false
            @enclosed_control.on_deselected
        end
        @enclosed_control = control
        @enclosed_control.is_selected = true
        @enclosed_control.on_selected
        enclose_control()
        decorate_control()
    end

    def decorate_control()
        # set the border characters

        super # initial_fill(:transparent)

        style = [:white, :on_black]

        (0...@width).each do |col|
            @rows[0][col] = { char: "\u{2501}", style: style}  #top row
            @rows[height - 1][col] = { char: "\u{2501}", style: style} #bottom row
        end

        (0...@height).each do |row|
            @rows[row][0] = { char: "\u{2503}", style: style}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", style: style}  #right side
        end

        @rows[0][0] = { char: "\u{250F}", style: style} #top left corner
        @rows[0][@width - 1] = { char: "\u{2513}", style: style} #top right corner
        @rows[@height - 1][0] = { char: "\u{2517}", style: style} #bottom left corner
        @rows[@height - 1][@width - 1] = { char: "\u{251B}", style: style} #bottom left corner
    end

    def move(direction)
        if @enclosed_control.has_link(direction)
            # @enclosed_control = @enclosed_control.follow_link(direction)
            select_control(@enclosed_control.follow_link(direction))
        else
            puts "Cannot Move in direction: #{direction}"
        end
    end

    def keypress(event)  # implements subscription of TTY::Reader
        # puts "name = #{event.key.name}"
        # puts "value = #{event.value}"
        @screen.display_message("")
        case
        when event.key.name == :up || event.value == "w"
            move(NORTH)
        when event.key.name == :right || event.value == "d"
            move(EAST)
        when event.key.name == :down || event.value == "s"
            move(SOUTH)
        when event.key.name == :left || event.value == "a"
            move(WEST)
        when event.key.name == :return || event.key.name == :space
            @enclosed_control.activate
        end
        # @screen.display_message(get_status())
    end

    def get_status()
        status = ""
        status << "#{@enclosed_control}: "
        status <<  "I can move"
        if @enclosed_control.links.length == 0
            status <<  " nowhere \u{1F622}"
        else
            counter = 0
            @enclosed_control.links.each do |link_direction, node|
                status <<  " #{link_direction} to #{node}"
                if counter == @enclosed_control.links.length - 2
                    status <<  " or"
                elsif counter != @enclosed_control.links.length - 1
                    status <<  ","
                end
                counter += 1
            end
        end
        status <<  "."
        return status
    end

end