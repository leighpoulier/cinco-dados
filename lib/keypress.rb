require("tty-reader")

reader = TTY::Reader.new(interrupt: Proc.new do
    puts "Exiting ... Goodbye!"
    exit
end)

# reader.on(:keyup, :keydown, :keyleft, :keyright) do |event|
reader.on(:keypress) do |event|
    puts "Key pressed Value: #{event.value}"
    puts "Key pressed Name: #{event.key.name}"
end


puts "Press an arrow key.  Press Ctrl-C to exit"
while true do
    reader.read_keypress
end