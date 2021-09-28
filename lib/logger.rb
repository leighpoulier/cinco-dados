
module CincoDados

    require "tty-logger"

    class Logger

        @@logger = nil
        @@handler = :null

        # https://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes/918087#918087

        def self.log

            if @@logger.nil?
                if @@handler == :file
                    @@logger ||= TTY::Logger.new do |config|
                        config.metadata = [:date, :time]
                        config.handlers = [:stream]
                        config.output = File.open("log_" + Time.new.strftime("%Y%m%d-%H%M%S") + ".log", "a")
                    end
                elsif @@handler == :console
                    @@logger ||= TTY::Logger.new do |config|
                        config.handlers = [:console]
                    end
                elsif @@handler == :null
                    @@logger ||= TTY::Logger.new do |config|
                        config.handlers = [:null]
                    end
                else
                    raise ConfigurationError.new("Invalid handler configuration. Handler: #{@@handler}")
                end
            end

            return @@logger
        end

        def self.set_logging_handler(handler)
            if [:console, :file, :null].include?(handler)
                @@handler = handler
            else
                raise ArgumentError.new("Invalid handler: #{handler}, must be one of [ :console , :file , :null ]")
            end
        end



    end
end