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
require_relative "score_card"
require_relative "player"
require_relative "controller"
include CompassDirections
include CincoDados



parser = OptionParser.new
# OptionParser.new do |parser|
parser.banner = "Usage: #{File.basename($0)} [options]"

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

begin
    parser.parse!
rescue => e
    puts "Command line options error: #{e.message}"
    puts ""
    puts parser.help
    exit
end



# screen = Screen.new(80,30)

# left_margin = 6
# top_margin = 4
# vert_spacing = 1

# (0..4).each do |counter|
#     dado = Dado.new(left_margin, top_margin + counter * (Dado::HEIGHT + vert_spacing ), "dado" + counter.to_s)
#     screen.add_dado(dado)
#     screen.add_control(dado)
#     if counter > 0 
#         dado.add_link(NORTH, screen.dados[counter-1], true)
#     end
# end

Controller.start()