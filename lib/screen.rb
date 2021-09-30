require "pastel"
require "tty-cursor"

module CincoDados
    class Screen

        

        attr_reader :columns, :rows, :info_line, :selection_cursor, :reader
        def initialize(width, height)
            @controls = []
            @columns = width
            @rows = height

            @cursor = TTY::Cursor
            print @cursor.move_to
            print @cursor.hide

            @pastel = Pastel.new

            @reader = TTY::Reader.new(interrupt: Proc.new do
                puts "Ctrl-C pressed: Exiting ... Goodbye!"
                exit
            end)

            @reader.subscribe(self)
            Logger.log.info("Logger subscribed to #{self.inspect}")

            # create selection cursor
            @selection_cursor = SelectionCursor.new(self, "cursor")
            add_control(@selection_cursor)

            # create info_line
            @info_line = InfoLine.new(columns, rows-1)
            add_control(@info_line)

            @escapecontrol = nil


        end

        def add_control(control)
            if !@controls.include?(control)
                @controls.push(control)
                @controls.sort!
                # Logger.log.info("new @controls order #{@controls.join(", ")}")

                if @selection_cursor.enclosed_control.nil? && !control.equal?(@selection_cursor) && control.is_a?(Button)
                    @selection_cursor.select_control(control)
                    Logger.log.info("Automatically selected control #{control} because it's a #{control.class.name} and selection cursor was empty")
                end
            else
                raise ArgumentError.new("control #{control} already exists in controls array #{@controls}")
            end
                
        end

        def has_control?(control)
            return @controls.include?(control)
        end

        def delete_control(control)
            if @controls.include?(control)
                @controls.delete(control)
            else
                raise ArgumentError.new("No such control in controls array")
            end
        end

        def set_info_line(info_line_control)
            if info_line_control.instance_of? InfoLine
                @info_line = info_line_control
            else
                raise ArgumentError.new("Control must be an instance of InfoLine to assign as info_line")
            end
        end

        def set_selection_cursor(selection_cursor_control)
            if selection_cursor_control.instance_of? SelectionCursor
                @selection_cursor = selection_cursor_control
            else
                raise ArgumentError.new("Control must be an instance of SelectionCursor to assign as selection_cursor")
            end
        end


        def draw()
            # clear screen
            system("clear")

            # draw background
            (0..(@rows-1)).each do |row|
                (0..(@columns-1)).each do |column|
                    print @pastel.black(Control::BLOCK_FULL)
                end
                print "\n"
            end

            

            # #print row numbers
            # print @cursor.move_to(0,0)
            # (0..(@rows-1)).each do |row|
            #     print @pastel.white.on_black(row)
            #     print @cursor.move_to(@columns-2, row)
            #     print @pastel.white.on_black(row)
            #     print "\n"
            # end
            
            # #print column numbers
            # (0..(@columns-1)).each do |column|
            #     print @cursor.move_to(column,0)
            #     print @pastel.white.on_black(column % 10)
            #     print @cursor.move_to(column, @rows-2)
            #     print @pastel.white.on_black(column % 10)
            # end
            

            # draw each control
            @controls.filter(&:visible).each do |control|
                control.draw(@cursor, @pastel)
            end
            print @cursor.move_to(0, @rows)
        end


        def keypress(event)  # implements subscription of TTY::Reader
            Logger.log.info("keypress event: key.name = #{event.key.name}, event.value = #{event.value}")
            case
            when event.key.name == :up || event.value == "w"
                @selection_cursor.move(NORTH)
            when event.key.name == :left || event.value == "a"
                @selection_cursor.move(WEST)
            when event.key.name == :down || event.value == "s"
                @selection_cursor.move(SOUTH)
            when event.key.name == :right || event.value == "d"
                @selection_cursor.move(EAST)
            when event.key.name == :return || event.key.name == :space
                @selection_cursor.on_activate()
            when event.key.name == :escape
                if @escapecontrol.nil?
                    Logger.log.info("Escape key pressed but no control registered")
                    @info_line.display_message("Escape pressed but no control registered")
                else
                    @escapecontrol.on_activate()
                end
            end
        end


        def display_message(message)
            @info_line.display_message(message)
 
        end


        def clear_message()
            @info_line.display_message("")

        end


        def clean_up()
            print @cursor.show
        end

    end

    class GameScreen < Screen

        attr_reader :roll_button

        def initialize(width, height)
            super


        # create roll button
        @roll_button = RollButton.new(20, 14, 8, 3, "ROLL")
        add_control(@roll_button)        
            
        @selection_cursor.select_control(@roll_button)
        # set_selection_cursor(selection_cursor)
        

        end


    end

    class MenuScreen < Screen


        MAIN_MENU_LEFT_MARGIN = 20
        MAIN_MENU_TOP_MARGIN = 16
        MAIN_MENU_BUTTON_WIDTH = 16
        MAIN_MENU_BUTTON_HEIGHT = 3

        SETUP_MENU_PLAYER_COUNT_BUTTON_WIDTH = 7
        SETUP_MENU_PLAYER_COUNT_BUTTON_LEFT_MARGIN = 17

        
        def initialize(width, height)
            super

            @exit_flag = false
            @return_data = {}

            font = TTY::Font.new(:standard)


        end

        def start()


            while !@exit_flag do
                draw()
                @reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self.inspect}")
            end
            return @return_data

        end


        def setup_menu(menu_config_type)

            @name = menu_config_type

            case menu_config_type # :main, :new_game
            when :main


                @banner = BannerText.new(4, "Cinco Dados", @columns)
                add_control(@banner)


                # create "New Game" button
                @button_new_game = Button.new(MAIN_MENU_LEFT_MARGIN, MAIN_MENU_TOP_MARGIN, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "New Game")
                add_control(@button_new_game)


                @button_new_game.register_event(:activate, ->() {
                    Controller.menu_new_game()
                })

                # create "How to Play" button and link it to "New Game" button
                @button_how_to_play = Button.new(MAIN_MENU_LEFT_MARGIN + 24, MAIN_MENU_TOP_MARGIN, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "How to Play")
                add_control(@button_how_to_play)
                @button_how_to_play.add_link(WEST, @button_new_game, true)
        
                # create "High Scores" button and link it to "New Game" button
                @button_high_scores = Button.new(MAIN_MENU_LEFT_MARGIN, MAIN_MENU_TOP_MARGIN + 6, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "High Scores")
                add_control(@button_high_scores)
                @button_high_scores.add_link(NORTH, @button_new_game, true)

                # create "Exit" button and link it to "How to Play" and "High Scores" buttons
                @button_exit = Button.new(MAIN_MENU_LEFT_MARGIN + 24, MAIN_MENU_TOP_MARGIN + 6, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "Exit")
                add_control(@button_exit)
                @button_exit.add_link(NORTH, @button_how_to_play, true)
                @button_exit.add_link(WEST, @button_high_scores, true)


                @button_exit.register_event(:activate, ->() {
                    @exit_flag = true
                })
                @escapecontrol = @button_exit

                @selection_cursor.select_control(@button_new_game)

            when :player_count



                @banner = BannerText.new(2, "How Many", @columns)
                add_control(@banner)
                @banner2 = BannerText.new(8, "Players?", @columns)
                add_control(@banner2)

                # create "Exit" button and link it to "How to Play" and "High Scores" buttons
                @button_exit = BackButton.new(32, MAIN_MENU_TOP_MARGIN + 8, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "Back")
                add_control(@button_exit)
                # @button_exit.add_link(NORTH, @button_how_to_play, true)
                # @button_exit.add_link(WEST, @button_high_scores, true)
                

                @player_count_buttons = []
                (0...4).each do |counter|
                    @player_count_buttons.push(Button.new(SETUP_MENU_PLAYER_COUNT_BUTTON_LEFT_MARGIN + (counter * (SETUP_MENU_PLAYER_COUNT_BUTTON_WIDTH + 6)), MAIN_MENU_TOP_MARGIN + 2, SETUP_MENU_PLAYER_COUNT_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, (counter + 1).to_s))
                    unless counter == 0
                        @player_count_buttons[counter].add_link(WEST, @player_count_buttons[counter-1], true)
                    end
                    @player_count_buttons[counter].add_link(SOUTH, @button_exit, false)
                    @player_count_buttons[counter].register_event(:activate, ->() {
                        @return_data[:player_count] = counter + 1
                        @exit_flag = true
                    })
                    add_control(@player_count_buttons[counter])
                end

                @button_exit.add_link(NORTH, @player_count_buttons[0], false)



                @button_exit.register_event(:activate, ->() {
                    @exit_flag = true
                })
                @escapecontrol = @button_exit

                @selection_cursor.select_control(@player_count_buttons[0])

            when :player_name

            

            end
        end

        def inspect

            return "class=#{self.class}, name=#{@name}"

        end

    end

end




