# require "pastel"
# require "tty-cursor"
require "optparse"
# require "tty-logger"
require "tty-reader"
require_relative "logging"
require_relative "screen"
# require_relative "cursormap"
require_relative "control"
require_relative "border_control"
require_relative "exceptions"
include CompassDirections
include CincoDados


# Logger.set_logging_handler(:null)

OptionParser.new do |parser|
    parser.banner = "Usage: options_parser.rb [options]"

    # parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    # options[:verbose] = v

    parser.on("-d", "--debug OUTPUT", "enable debug mode, without output to OUTPUT [ console | file ]") do |output|
        if ["console","file"].include?(output)
            # puts "debug output to #{output}!"
            Logger.set_logging_handler(output.to_sym)
        else
            # raise ArgumentError.new("Invalid output for debug mode: #{output}, must be one of [ console | file ]")
            puts "Invalid output for debug mode: #{output}, must be one of [ console | file ]"
            puts "\n"
            puts parser.help
            exit
        end
    end
    
end.parse!



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
