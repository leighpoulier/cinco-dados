require_relative("screen.rb")
require "tty-reader"
include CincoDados

module CincoDados

    class ScoreCard



    end
    
end


screen = Screen.new(80,30)
reader = TTY::Reader.new(interrupt: Proc.new do
    screen.clean_up()
    puts "Exiting ... Goodbye!"
    exit
end)
