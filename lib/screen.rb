require "tty-cursor"
require "pastel"
require_relative "cursormap"
include CompassDirections

class Screen

    attr_reader :columns, :rows, :dados
    def initialize(width, height)
        @controls = []
        @dados=[]
        @columns = width
        @rows = height

        @cursor = TTY::Cursor
        print @cursor.move_to
        print @cursor.hide

        @pastel = Pastel.new

        system("clear")
    end

    def add_control(control)
        @controls.push(control)
        control.set_screen(self)
    end

    def add_dado(dado)
        if dado.instance_of? Dado
            @dados.push(dado)
        else
            raise "Control must be an instance of Dado to add to dados array"
        end
    end

    def set_info_line(info_line_control)
        if info_line_control.instance_of? InfoLine
            @info_line = info_line_control
        else
            raise "Control must be an instance of InfoLine to assign as info_line"
        end
    end

    def set_selection_cursor(selection_cursor_control)
        if selection_cursor_control.instance_of? SelectionCursor
            @selection_cursor = selection_cursor_control
        else
            raise "Control must be an instance of SelectionCursor to assign as selection_cursor"
        end
    end

    def display_message(message)
        @info_line.display_message(message)
    end


    def draw()
        # clear screen
        system("clear")

        # draw background
        (0..(@rows-1)).each do |row|
            (0..(@columns-1)).each do |column|
                print @pastel.black("\u{2588}")
            end
            print "\n"
        end
        
        # draw each control
        @controls.each do |control|
            control.draw(@cursor)
        end
        print @cursor.move_to(0, @rows)
    end

    def roll_unlocked_dados()
        status = []
        dados.each do |dado|
        # for dado in dados
            if !dado.locked?
                dado.roll
            end
            status << dado.value
        end
        
        display_message(status.sort)
    end

end

class Control < SelectionCursorMapNode

    attr_reader :height, :width, :x, :y, :screen
    attr_accessor :is_selected

    def initialize(x, y, name)
        super(name)
        @x = x
        @y = y
        @printed_rows = 0
        @pastel = Pastel.new
    end

    def initial_fill(fill)
        fill_row = Array.new(@width, {char: fill, inverse: false})
        @rows = []
        for i in (0...@height)
            @rows[i] = fill_row.clone
        end
    end

    def draw(cursor)
        print cursor.move_to(@x, @y)
        @rows.each do |row|
            row.each do |charhash|
                if charhash[:inverse]
                    print @pastel.decorate(charhash[:char], :black, :on_white)
                else
                    print @pastel.decorate(charhash[:char], :white, :on_black)
                end
            end
            print cursor.move(-1 * row.length, -1)

        end
        if self.is_a? BorderControl
            self.enclosed_control.draw(cursor)
        end
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
        (0...@text.length).each do |char_count|
            @rows[middle_row][starting_col + char_count] = {char: @text[char_count], inverse: true}
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

    attr_reader :value


    def initialize(x, y, name)


        super(x, y, name)
        @@full_block = "\u{2588}"
        @@pip = "\u{2584}"
        
        @height = HEIGHT
        @width = WIDTH
        @locked = false

        # row_default = Array.new(@width, {char: @@full_block, inverse: false})
        
        # @rows = []
        # for i in (0...@height)
        #     @rows[i] = row_default.clone
        # end

        initial_fill(@@full_block)

        @prng = Random.new

        # if shift 
        #     @rows[0] = Array.new(@width, {char: "\u{1FB39}", inverse: false})
            
        #     @rows[0][0] = {char: "\u{1FB4A}", inverse: false} #top left corner
        #     @rows[0][@width-1] = {char: "\u{1FB3F}", inverse: false} #top right corner
        #     @rows[@height-1][0] = {char: "\u{1FB55}", inverse: false} #bottom left corner
        #     @rows[@height-1][@width-1] = {char: "\u{1FB60}", inverse: false} #bottom right corner
        
        # else
            @rows[height-1] = Array.new(@width, {char: "\u{1FB0E}", inverse: false})
            
            @rows[0][0] = {char: "\u{1FB44}", inverse: false} #top left corner
            @rows[0][@width-1] = {char: "\u{1FB4F}", inverse: false} #top right corner
            @rows[@height-1][0] = {char: "\u{1FB65}", inverse: false} #bottom left corner
            @rows[@height-1][@width-1] = {char: "\u{1FB5A}", inverse: false} #bottom right corner
        # end

        roll
        
    end

    def roll()

        reset_pips()

        @value = @prng.rand(6) + 1

        if @value < 1 || @value > 6 || !@value.is_a?(Integer)
            raise "Invalid dado @value: #{@value}"
        end
        
        if @value == 2 || @value == 3 || @value == 4 || @value == 5 || @value == 6
            @rows[0][1] = {char: @@pip, inverse: true}
            @rows[2][5] = {char: @@pip, inverse: true}
        end
        if @value == 4 || @value == 5 || @value == 6
            @rows[0][5] = {char: @@pip, inverse: true}
            @rows[2][1] = {char: @@pip, inverse: true}
        end
        if @value == 6
            @rows[1][1] = {char: @@pip, inverse: true}
            @rows[1][5] = {char: @@pip, inverse: true}
        end
        if @value == 1 || @value == 3 || @value == 5
            @rows[1][3] = {char: @@pip, inverse: true}
        end
    end

    def reset_pips()
        (0..2).each do |row|
            [1,5].each do |side|
                @rows[row][side] = {char: @@full_block, inverse: false}
            end
        end
        @rows[1][3]= {char: @@full_block, inverse: false}
    end

    def toggle_lock()
        @locked = !@locked
        @locked_border = LockedBorder.new(self, "locked_" + self.name)
        screen.add_control(@locked_border)
    end

    def locked?
        return @locked
    end

    def activate()
        toggle_lock()
    end

end

class BorderControl < Control

    attr_reader :enclosed_control

    def enclose_control()
        @height = @enclosed_control.height + 2
        @width = @enclosed_control.width + 2
        @x = @enclosed_control.x-1
        @y = @enclosed_control.y-1

        initial_fill(" ")

    end
end

class LockedBorder < BorderControl
    
    def initialize(control, name)

        @enclosed_control = control
        enclose_control()
        super(@x, @y, name)
    end

    def decorate_control()
        # set the border characters

        [1,@width-2].each do |col|
            @rows[0][col] = { char: "\u{2501}", invert: false}  #top row
            @rows[height - 1][col] = { char: "\u{2501}", invert: false} #bottom row
        end

        [1,@height-2].each do |row|
            @rows[row][0] = { char: "\u{2503}", invert: false}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", invert: false}  #right side
        end

        @rows[0][0] = { char: "\u{250F}", invert: false} #top left corner
        @rows[0][@width - 1] = { char: "\u{2513}", invert: false} #top right corner
        @rows[@height - 1][0] = { char: "\u{2517}", invert: false} #bottom left corner
        @rows[@height - 1][@width - 1] = { char: "\u{251B}", invert: false} #bottom left corner
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

    def display_message(message)
        (0...@width-@left_indent).each do |char_count|
            @rows[0][@left_indent + char_count] = {char: message[char_count], inverse: false}
        end
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

        (0...@width).each do |col|
            @rows[0][col] = { char: "\u{2501}", invert: false}  #top row
            @rows[height - 1][col] = { char: "\u{2501}", invert: false} #bottom row
        end

        (0...@height).each do |row|
            @rows[row][0] = { char: "\u{2503}", invert: false}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", invert: false}  #right side
        end

        @rows[0][0] = { char: "\u{250F}", invert: false} #top left corner
        @rows[0][@width - 1] = { char: "\u{2513}", invert: false} #top right corner
        @rows[@height - 1][0] = { char: "\u{2517}", invert: false} #bottom left corner
        @rows[@height - 1][@width - 1] = { char: "\u{251B}", invert: false} #bottom left corner
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

screen = Screen.new(80,30)

left_margin = 6
top_margin = 2
vert_spacing = 1

(0..4).each do |counter|
    dado = Dado.new(left_margin, top_margin + counter * (Dado::HEIGHT + vert_spacing ), "dado" + counter.to_s)
    screen.add_dado(dado)
    screen.add_control(dado)
    if counter > 0 
        dado.add_link(NORTH, screen.dados[counter-1], true)
    end
end

button = Button.new(18, 12, 8, 3, "\u{1FB99}", "ROLL", "roll")
screen.dados.each do |dado|
    dado.add_link(EAST, button, false)
end
button.add_link(WEST, screen.dados[2], false)
button.register_event(:activate, ->(screen) {
    # screen.display_message("ROLL!")
    screen.roll_unlocked_dados()
})
screen.add_control(button)

selection_cursor = SelectionCursor.new(button, "cursor")
screen.add_control(selection_cursor)
screen.set_selection_cursor(selection_cursor)

info_line = InfoLine.new(screen.columns, screen.rows-1)
screen.add_control(info_line)
screen.set_info_line(info_line)

reader = TTY::Reader.new(interrupt: Proc.new do
    puts "Exiting ... Goodbye!"
    exit
end)

reader.subscribe(selection_cursor)

while true do 

    screen.draw
    reader.read_keypress

end



