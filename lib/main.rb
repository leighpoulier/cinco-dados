
require "optparse"
require_relative "logger"
require_relative "controller"
include CincoDados



parser = OptionParser.new
# OptionParser.new do |parser|
parser.banner = "Usage: #{File.basename($0)} [options]"

# parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
# options[:verbose] = v

parser.on("-d", "--debug", "enable debug mode with logging to a file") do
    Logger.set_logging_handler(:file)
end

parser.on("-s", "--static", "disable dice sequenced animation on roll") do
    Config.disable_dice_animation()
end

parser.on("-h", "--help", "display this usage information") do
    puts parser.help
    exit
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