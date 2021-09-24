require "tty-cursor"
require "pastel"

class Screen
    def initialize(width, height)
        @controls = []
        @columns = width
        @rows = height

        @cursor = TTY::Cursor
        print @cursor.move_to
        print @cursor.show

        @pastel = Pastel.new

        system("clear")
    end

    def add_control(control)
        @controls.push(control)
    end

    def background_draw()
        (0..(@rows-1)).each do |row|
            (0..(@columns-1)).each do |column|
                print @pastel.black("\u{2588}")
            end
            print "\n"
        end
    end

    def draw()
        system("clear")
        background_draw()
        @controls.each do |control|
            control.draw(@cursor)
        end
        print @cursor.move_to(0, @rows)
    end

end

class Control

    attr_reader :height, :width, :x, :y

    def initialize(x, y)
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
        if self.instance_of? Cursor
            self.control.draw(cursor)
        end
    end

end

class Button < Control

    def initialize(x, y, width, height, fill, text)
        super(x, y)
        @width = width
        @height = height
        @fill = "\u{2588}"
        @text = text

        initial_fill(@fill)


        # Replace centre characters witih inverse text
        middle_row = @height/2
        middle_col = @width/2
        starting_col = middle_col - (text.length/2)
        (0...text.length).each do |char_count|
            @rows[middle_row][starting_col + char_count] = {char: @text[char_count], inverse: true}
        end

    
    end

end

class Dado < Control

    WIDTH = 7
    HEIGHT = 4


    def initialize(x, y)


        super(x, y)
        @@full_block = "\u{2588}"
        @@pip = "\u{2584}"
        
        @height = HEIGHT
        @width = WIDTH

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

end

class Cursor < Control

    attr_reader :control

    def initialize(control)
        set_control(control)
        super(@x, @y)
        
    end

    def set_control(control)

        @control = control
        @height = control.height + 2
        @width = control.width + 2
        @x = control.x-1
        @y = control.y-1

        initial_fill(" ")


        # set the border characters

        (0...width).each do |col|
            @rows[0][col] = { char: "\u{2501}", invert: false}  #top row
            @rows[height - 1][col] = { char: "\u{2501}", invert: false} #bottom row
        end

        (0...height).each do |row|
            @rows[row][0] = { char: "\u{2503}", invert: false}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", invert: false}  #right side
        end

        @rows[0][0] = { char: "\u{250F}", invert: false} #top left corner
        @rows[0][width - 1] = { char: "\u{2513}", invert: false} #top right corner
        @rows[height - 1][0] = { char: "\u{2517}", invert: false} #bottom left corner
        @rows[height - 1][width - 1] = { char: "\u{251B}", invert: false} #bottom left corner

    end




end

screen = Screen.new(80,30)

dados = []

left_margin = 6
top_margin = 2
vert_spacing = 1

(0..4).each do |counter|
    dado = Dado.new(left_margin, top_margin + counter * (Dado::HEIGHT + vert_spacing ))
    dados.push(dado)
    screen.add_control(dado)
end

button = Button.new(18, 12, 8, 3, "\u{1FB99}", "ROLL")
screen.add_control(button)

cursor = Cursor.new(button)
screen.add_control(cursor)


screen.draw





