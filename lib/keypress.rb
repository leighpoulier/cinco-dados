require("tty-reader")

reader = TTY::Reader.new(interrupt: Proc.new do
    puts "Exiting ... Goodbye!"
    exit
end)

reader.on(:keyup, :keydown, :keyleft, :keyright) do |event|
    # puts "You pressed #{event.value}"
    puts "You pressed #{event.key.name}"
end


puts "Press an arrow key.  Press Ctrl-C to exit"
while true do
    reader.read_keypress
end