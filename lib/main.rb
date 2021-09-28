# # require "pastel"
# # require "tty-cursor"
require "optparse"
# # require "tty-logger"
# require "tty-reader"
require_relative "logger"
# require_relative "screen"
# # require_relative "cursormap"
# require_relative "control"
# require_relative "border_control"
# require_relative "exceptions"
# require_relative "score_card"
# require_relative "player"
# require_relative "controller"
# include CompassDirections
# include CincoDados



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



Controller.start()