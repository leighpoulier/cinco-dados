require_relative "game"
module CincoDados
    class Controller

    def self.start()

        #Game should be instantiated with players, after player names are input from terminal
        @@game = GameModel.new()
        @@screen = @@game.screen
        @@cursor = @@game.screen.selection_cursor
        @@console = @@game.screen.info_line

        reader = TTY::Reader.new(interrupt: Proc.new do
            @@screen.clean_up()
            puts "Ctrl-C pressed: Exiting ... Goodbye!"
            exit
        end)
        
        reader.subscribe(self)
        
        while true do 
        
            @@screen.draw
            reader.read_keypress
        
        end


    end

    def self.keypress(event)  # implements subscription of TTY::Reader
        Logger.log.info("keypress event: key.name = #{event.key.name}, event.value = #{event.value}")
        case
        when event.key.name == :up || event.value == "w"
            @@cursor.move(NORTH)
        when event.key.name == :right || event.value == "d"
            @@cursor.move(EAST)
        when event.key.name == :down || event.value == "s"
            @@cursor.move(SOUTH)
        when event.key.name == :left || event.value == "a"
            @@cursor.move(WEST)
        when event.key.name == :return || event.key.name == :space
            @@cursor.activate()
        end
        Controller.display_message(@@cursor.get_status())
    end

    def self.display_message(message)
        @@console.display_message(message)
    end


    def self.clear_message()
        @@console.display_message("")
    end


    end
end