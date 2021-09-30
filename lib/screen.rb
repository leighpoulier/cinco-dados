require "pastel"
require "tty-cursor"
module CincoDados
    class Screen

        

        attr_reader :columns, :rows, :info_line, :selection_cursor
        def initialize(width, height)
            @controls = []
            @columns = width
            @rows = height

            @cursor = TTY::Cursor
            print @cursor.move_to
            print @cursor.hide

            @pastel = Pastel.new

            # system("clear")
        end

        def add_control(control)
            if !@controls.include?(control)
                @controls.push(control)
                @controls.sort!
                # Logger.log.info("new @controls order #{@controls.join(", ")}")
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
            
        # create selection cursor
        @selection_cursor = SelectionCursor.new(@roll_button, "cursor")
        add_control(@selection_cursor)
        # set_selection_cursor(selection_cursor)
        
        # create info_line
        @info_line = InfoLine.new(columns, rows-1)
        add_control(@info_line)
        # set_info_line(info_line)


        end


    end

    class MenuScreen < Screen


        MAIN_MENU_LEFT_MARGIN = 20
        MAIN_MENU_TOP_MARGIN = 18
        MAIN_MENU_BUTTON_WIDTH = 16
        MAIN_MENU_BUTTON_HEIGHT = 3

        
        def initialize(width, height)
            super

            @exit_flag = false


        end

        def start(reader)

            while !@exit_flag do
                draw()
                reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self} with name: #{@name}")
            end

        end


        def setup_menu(menu_config_type)

            @name = menu_config_type

            case menu_config_type # :main, :new_game
            when :main 


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


                @selection_cursor = SelectionCursor.new(@button_new_game, "cursor")
                add_control(@selection_cursor)

            when :new_game
                
                # create "Exit" button and link it to "How to Play" and "High Scores" buttons
                @button_exit = Button.new(MAIN_MENU_LEFT_MARGIN + 24, MAIN_MENU_TOP_MARGIN + 6, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "Exit")
                add_control(@button_exit)
                # @button_exit.add_link(NORTH, @button_how_to_play, true)
                # @button_exit.add_link(WEST, @button_high_scores, true)


                @button_exit.register_event(:activate, ->() {
                    @exit_flag = true
                })


                @selection_cursor = SelectionCursor.new(@button_exit, "cursor")
                add_control(@selection_cursor)


            end
        end

        def inspect

            return "class=#{self.class}, name=#{@name}"

        end

    end

end




