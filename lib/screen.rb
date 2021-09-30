require "pastel"
require "tty-cursor"

module CincoDados
    class Screen

        

        attr_reader :columns, :rows, :info_line, :selection_cursor, :reader
        def initialize()
            @controls = []
            @columns = Config::GAME_SCREEN_WIDTH
            @rows = Config::GAME_SCREEN_HEIGHT

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

        def initialize()
            super
            @game = nil


            # create roll button
            @roll_button = RollButton.new(20, 14, 8, 3, "ROLL")
            add_control(@roll_button)        
                
            @selection_cursor.select_control(@roll_button)
            # set_selection_cursor(selection_cursor)

        end

        def set_game(game)
            @game = game


            # link (screen) button to (game) middle dado
            @roll_button.add_link(WEST, @game.dados_cup.dados[2], false)

            # register activate event for roll button
            @roll_button.register_event(:activate, ->() {
                display_message("Rolling !")
                @game.roll()
            })

        end


    end

    class MenuScreen < Screen

        MAIN_MENU_LEFT_MARGIN = 20
        MAIN_MENU_TOP_MARGIN = 16
        MAIN_MENU_BUTTON_WIDTH = 16
        MAIN_MENU_BUTTON_HEIGHT = 3

        SETUP_MENU_BACK_BUTTON_TOP_OFFSET = 24
        SETUP_MENU_BACK_BUTTON_LEFT_OFFSET = 32
        
        def initialize()
            super
        end

        def start()

            
            @exit_flag = false
            while !@exit_flag do
                draw()
                @reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self.inspect}")
            end
        end

        def inspect

            return "class=#{self.class}, name=#{@name}"

        end

    end

    class MainMenuScreen < MenuScreen


        def initialize()

            super

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
        end


    end


    class PlayerCountMenuScreen < MenuScreen

        SETUP_MENU_PLAYER_COUNT_BUTTON_WIDTH = 7
        SETUP_MENU_PLAYER_COUNT_BUTTON_LEFT_MARGIN = 17


        def initialize()
            super

            @player_count = nil

            # Banner heading
            @banner = BannerText.new(2, "How Many", @columns)
            add_control(@banner)
            @banner2 = BannerText.new(8, "Players?", @columns)
            add_control(@banner2)

            # Add back button
            @button_exit = BackButton.new(SETUP_MENU_BACK_BUTTON_LEFT_OFFSET, SETUP_MENU_BACK_BUTTON_TOP_OFFSET, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "Back")
            add_control(@button_exit)


            @button_exit.register_event(:activate, ->() {
                @exit_flag = true
            })
            # Register it to handle Esc keypress
            @escapecontrol = @button_exit
            

            @player_count_buttons = []
            (0...4).each do |counter|
                @player_count_buttons.push(Button.new(SETUP_MENU_PLAYER_COUNT_BUTTON_LEFT_MARGIN + (counter * (SETUP_MENU_PLAYER_COUNT_BUTTON_WIDTH + 6)), MAIN_MENU_TOP_MARGIN + 2, SETUP_MENU_PLAYER_COUNT_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, (counter + 1).to_s))
                unless counter == 0
                    @player_count_buttons[counter].add_link(WEST, @player_count_buttons[counter-1], true)
                end
                @player_count_buttons[counter].add_link(SOUTH, @button_exit, false)
                @player_count_buttons[counter].register_event(:activate, ->() {
                    @player_count = counter + 1
                    @exit_flag = true
                })
                add_control(@player_count_buttons[counter])
            end

            @button_exit.add_link(NORTH, @player_count_buttons[0], false)


            @selection_cursor.select_control(@player_count_buttons[0])

        end


        def get_player_count()

            
            @exit_flag = false
            while !@exit_flag do
                draw()
                @reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self.inspect}")
            end

            return @player_count
        end
    end


    class PlayerNameMenuScreen < MenuScreen

        def initialize()
            super

            @player_name = ""

            @banner2 = BannerText.new(7, "Name", @columns)
            add_control(@banner2)

            @text_prompt = TextControl.new(19, 16, 42, 1, :left, "Please enter a name. Maximum 5 characters!")
            add_control(@text_prompt)


            # Add back button
            @button_exit = BackButton.new(32, MAIN_MENU_TOP_MARGIN + 8, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "Back")
            add_control(@button_exit)

            @button_exit.register_event(:activate, ->() {
                @exit_flag = true
            })
            # Register it to handle Esc keypress
            @escapecontrol = @button_exit

            
        
        end

        def keypress(event)  # implements subscription of TTY::Reader
            Logger.log.info("keypress event: key.name = #{event.key.name}, event.value = #{event.value}")
            case
            when event.key.name == :up
                @selection_cursor.move(NORTH)
            when event.key.name == :left
                @selection_cursor.move(WEST)
            when event.key.name == :down
                @selection_cursor.move(SOUTH)
            when event.key.name == :right
                @selection_cursor.move(EAST)
            when event.key.name == :return
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

        def get_player_name(player_number)

            # Banner heading
            @banner = BannerText.new(2, "Player #{player_number + 1}", @columns)
            add_control(@banner)

            player_name = ""
            regex = "^" + Regexp.escape("`~!@#$%^&*()-_=+[]{}\|;:'\",.<>\/?") + "0-9a-zA-z"
            
            @exit_flag = false
            # while !@exit_flag do
            while player_name.length < 1 || player_name.length > ScoreCard::PLAYER_SCORE_WIDTH || !(/[#{regex}]/ =~ player_name).nil?
                draw()
                @cursor.move_to(0,0)
                @cursor.show()
                player_name = gets.strip
                @cursor.hide()
                # @reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self.inspect}")
                # end
            end

            return player_name

        end
    end

end




