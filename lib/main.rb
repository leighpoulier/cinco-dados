require "pastel"
require "tty-cursor"
require "tty-logger"
require "tty-reader"
require_relative "screen"
require_relative "cursormap"
require_relative "control"
include CompassDirections
include CincoDados

$logger = TTY::Logger.new do |config|
    config.output = File.open("error_" + Time.new.strftime("%Y%m%d-%H%M") + ".log", "a")
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
