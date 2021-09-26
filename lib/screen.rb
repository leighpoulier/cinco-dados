require "tty-cursor"
require "pastel"
require "tty-logger"
require_relative "cursormap"
require_relative "control"
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

    def delete_control(control)
        if @controls.include?(control)
            @controls.delete(control)
        else
            raise "No such control in controls array"
        end
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
        

        @controls.sort!
        $logger.info("@controls order #{@controls.join(", ")}")
        # draw each control
        @controls.each do |control|
            control.draw(@cursor)
        end
        print @cursor.move_to(0, @rows)
    end

    def roll_unlocked_dados()
        # status = []
        dados.each do |dado|
        # for dado in dados
            if !dado.locked?
                dado.roll
            end
            # status << dado.value
        end

        cinco_dados = true
        dado_counter = 0
        while dado_counter < @dados.length
            unless dados[dado_counter].value == @dados[0].value
                cinco_dados = false
                break
            end
            dado_counter += 1
        end
        if cinco_dados
            display_message("Felicidades! Cinco Dades!")
        end
    end

    def clean_up()

        print @cursor.show

    end

end



$logger = TTY::Logger.new do |config|
    config.output = File.open("error_" + Time.new.strftime("%Y%m%d-%k%M") + ".log", "a")
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
    screen.clean_up()
    puts "Exiting ... Goodbye!"
    exit
end)

reader.subscribe(selection_cursor)

while true do 

    screen.draw
    reader.read_keypress

end



