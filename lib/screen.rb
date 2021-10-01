require "pastel"
require "tty-cursor"

module CincoDados

    class Screen


        attr_reader :columns, :rows, :selection_cursor, :reader

        def initialize
            @controls = []
            @columns = Config::GAME_SCREEN_WIDTH
            @rows = Config::GAME_SCREEN_HEIGHT
            @current_page = 1
            @min_page = 1
            @max_page = 1


            @x = 0
            @y = 0

            @background_style = [:black]

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

            @escapecontrol = nil

        end


        def add_control(control)
            if !control.is_a?(Control)
                raise ArgumentError.new("What the hell are you doing? To add a control to the screen, it must actually be a control")
            end
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


        def set_selection_cursor(selection_cursor_control)
            if selection_cursor_control.instance_of? SelectionCursor
                @selection_cursor = selection_cursor_control
            else
                raise ArgumentError.new("Control must be an instance of SelectionCursor to assign as selection_cursor")
            end
        end


        def draw()
            # clear screen
            if self.is_a?(FullScreen)
                system("clear")
            end


            draw_background()
            

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
            @controls.filter do |control|
                control.on_pages().include?@current_page
            end.filter(&:visible).each do |control|
                control.draw(@cursor, @pastel, @x, @y)
            end
            print @cursor.move_to(@x, @y + @rows)
        end

        def draw_background()
            Logger.log.info("Printing the background from row #{@y} to #{@y + @rows -1} and column #{@x} to #{@x + @columns -1}")
            print @cursor.move_to(@x, @y)
            (@y..(@y + @rows-1)).each do |row|
                (@x..(@x + @columns-1)).each do |column|
                    print @pastel.decorate(Control::BLOCK_FULL, *@background_style)
                end
                print @cursor.move(-1 * @columns, -1)
            end
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

        def clean_up()
            print @cursor.show
        end



    end
    class FullScreen < Screen

        

        attr_reader :info_line
        def initialize()
   
            super

            # create info_line
            @info_line = InfoLine.new(columns, rows-1)
            add_control(@info_line)

        end


        def set_info_line(info_line_control)
            if info_line_control.instance_of? InfoLine
                @info_line = info_line_control
            else
                raise ArgumentError.new("Control must be an instance of InfoLine to assign as info_line")
            end
        end


        def display_message(message)
            @info_line.display_message(message)
 
        end


        def clear_message()
            @info_line.display_message("")

        end


    end

    class GameScreen < FullScreen

        attr_reader :roll_button

        def initialize()
            super
            @game = nil


            # create roll button
            @roll_button = RollButton.new(20, 14, 8, 3, "ROLL")
            add_control(@roll_button)
            
            @exit_button = BackButton.new(0,0,6,3,"Exit")
            add_control(@exit_button)
            @exit_button.hide()
            @escapecontrol = @exit_button
            @exit_button.register_event(:activate, -> {
                modal = Modal.new()
                if modal.yes_no("Are you sure you want to quit?")
                    @game.set_exit_flag()
                    
                    Logger.log.info("Set game exit flag")
                end
            })
                
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

    class MenuScreen < FullScreen

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


            @button_how_to_play.register_event(:activate, ->() {
                Controller.how_to_play()
            })
    
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

            @text_prompt = TextControl.new(19, 16, 42, 1, :top, :left, "Please enter a name. Maximum 5 characters!")
            add_control(@text_prompt)


            # Add OK button
            @button_exit = Button.new(32, MAIN_MENU_TOP_MARGIN + 8, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT, "OK")
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

            # @exit_flag = false
            # while !@exit_flag do
            while player_name.length < 1 || player_name.length > ScoreCard::PLAYER_SCORE_WIDTH || !Text.sanitize_string(player_name)
                draw()
                print @cursor.move_to(Text.start_column(ScoreCard::PLAYER_SCORE_WIDTH, @columns, :centre),@text_prompt.y + 2)
                print @cursor.show()
                player_name = gets.strip
                print @cursor.hide()
                # @reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self.inspect}")
                # end
            end

            return player_name

        end
    end

    class HowToPlayScreen < MenuScreen

        HOW_TO_PLAY_BUTTON_TOP_MARGIN = 25
        HOW_TO_PLAY_PARAGRAPH_TOP_MARGIN = 8
        HOW_TO_PLAY_BUTTON_WIDTH = 10
        HOW_TO_PLAY_BUTTON_HEIGHT = 3

        def initialize()
            super

            @current_page = 1
            @max_page = 3

            @all_pages = [1,2,3]  #for the controls below

            @selection_cursor.set_pages(@all_pages)

            @banner = BannerText.new(1, "How to Play", @columns)
            add_control(@banner)
            @banner.set_pages(@all_pages)

            @paragraph1 = ParagraphCentredTextControl.new(HOW_TO_PLAY_PARAGRAPH_TOP_MARGIN, Config::GAME_SCREEN_WIDTH - 4, :left, "Cinco Dados (Five Dice) is a game of chance played with five dice. Roll the dice up to 3 times in each turn to try and achieve certain combinations.", Config::GAME_SCREEN_WIDTH)
            add_control(@paragraph1)

            @paragraph2 = ParagraphCentredTextControl.new(@paragraph1.y + @paragraph1.height + 1, Config::GAME_SCREEN_WIDTH - 4, :left, "Each player has 13 turns, which correspond to the 13 spaces on the score card. After the first roll, you can set aside any number of dice to keep, and roll the remainder. By selectively keeping some dice and rerolling others you can hopefully build up the required combinations by your 3rd roll.", Config::GAME_SCREEN_WIDTH)
            add_control(@paragraph2)

            @paragraph3 = ParagraphCentredTextControl.new(@paragraph2.y + @paragraph2.height + 1, Config::GAME_SCREEN_WIDTH - 4, :left, "The combinations listed on the score card are split into upper and lower sections. The upper section contains one space for each of the six dice values, and the target is to roll 3 dice of each value.  The score for these spaces is the addition of the values of those dice.  For example if you roll 3 fives, you score 15. If you roll 4 sixes, you score 24, and if you roll 1 three, you score 3.", Config::GAME_SCREEN_WIDTH)
            add_control(@paragraph3)

            @paragraph4 = ParagraphCentredTextControl.new(HOW_TO_PLAY_PARAGRAPH_TOP_MARGIN, Config::GAME_SCREEN_WIDTH - 4, :left, "If you achieve 3 of each dice value, your upper section total will be 63, and you will receive a bonus of 35 points.  If you don’t achieve 3 of a certain dice value, you can compensate by achieving more in a different category, as long as the upper total is 63 or more, you will achieve the bonus.", Config::GAME_SCREEN_WIDTH)
            @paragraph4.set_page(2)
            add_control(@paragraph4)
            
            @paragraph5 = ParagraphCentredTextControl.new(@paragraph4.y + @paragraph4.height + 1, Config::GAME_SCREEN_WIDTH - 4, :left, "The lower section contains generic 3 of a kind and 4 of a kind categories, and if achieved, the score here is the total of all dice, not just those which match.", Config::GAME_SCREEN_WIDTH)
            @paragraph5.set_page(2)
            add_control(@paragraph5)

            @paragraph6 = ParagraphCentredTextControl.new(@paragraph5.y + @paragraph5.height + 1, Config::GAME_SCREEN_WIDTH - 4, :left, "Below that are fixed scores for full house (3 of one value, and 2 of another) worth 25 points, a small straight (any sequence of 4 numbers) worth 30 points, a large straight (any sequence of 5 numbers) worth 40 points, and Cinco Dados (5 of a kind) worth 50 points. The “chance” score is where you can place any roll which doesn’t achieve any combination, and scores the total of the dice.", Config::GAME_SCREEN_WIDTH)
            @paragraph6.set_page(2)
            add_control(@paragraph6)

            @paragraph7 = ParagraphCentredTextControl.new(HOW_TO_PLAY_PARAGRAPH_TOP_MARGIN, Config::GAME_SCREEN_WIDTH - 4, :left, "If you don’t achieve any combination, and your chance score is already allocated, you can apply your roll to any line for a zero score.  You must place every roll somewhere on your score card, so a bit of strategy is required when choosing where to place your score!", Config::GAME_SCREEN_WIDTH)
            @paragraph7.set_page(3)
            add_control(@paragraph7)

            # Add Exit button
            @button_exit = Button.new(35, HOW_TO_PLAY_BUTTON_TOP_MARGIN, HOW_TO_PLAY_BUTTON_WIDTH, HOW_TO_PLAY_BUTTON_HEIGHT, "Exit")
            add_control(@button_exit)
            @button_exit.set_pages(@all_pages)

            @button_exit.register_event(:activate, ->() {
                @exit_flag = true
            })
            # Register it to handle Esc keypress
            @escapecontrol = @button_exit

            # Add Next button
            @button_next = Button.new(66, HOW_TO_PLAY_BUTTON_TOP_MARGIN, HOW_TO_PLAY_BUTTON_WIDTH, HOW_TO_PLAY_BUTTON_HEIGHT, "Next")
            add_control(@button_next)
            @button_next.set_pages(@all_pages)
            @button_next.add_link(WEST, @button_exit, true)

            @button_next.register_event(:activate, -> {
                @current_page += 1
                if @current_page > @max_page
                    @current_page = @max_page
                end
            })

            # Add Previous button
            @button_previous = Button.new(4, HOW_TO_PLAY_BUTTON_TOP_MARGIN, HOW_TO_PLAY_BUTTON_WIDTH, HOW_TO_PLAY_BUTTON_HEIGHT, "Previous")
            add_control(@button_previous)
            @button_previous.set_pages(@all_pages)
            @button_previous.add_link(EAST, @button_exit, true)
            @button_previous.disable()
            @button_previous.hide()

            @button_previous.register_event(:activate, -> {
                @current_page -= 1
                if @current_page < @min_page
                    @current_page = @min_page
                end
            })

            
        end

        # override
        def start()

            
            @exit_flag = false
            while !@exit_flag do
                draw()
                @reader.read_keypress
                Logger.log.info("Read keypress in menu_screen #{self.inspect}")

                if @current_page == @max_page
                    @button_next.disable()
                    @button_next.hide()
                    if @selection_cursor.enclosed_control.equal?(@button_next)
                        @selection_cursor.select_control(@button_exit)
                    end
                else
                    if @button_next.disabled?
                        @button_next.enable()
                        @button_next.show()
                    end
                end

                if @current_page == @min_page
                    @button_previous.disable()
                    @button_previous.hide()
                    if @selection_cursor.enclosed_control.equal?(@button_previous)
                        @selection_cursor.select_control(@button_exit)
                    end
                else
                    if @button_previous.disabled?
                        @button_previous.enable()
                        @button_previous.show()
                    end
                end
            end
        end
    end

    class Modal < Screen

        MODAL_BUTTON_HEIGHT = 3
        MODAL_BUTTON_WIDTH = 10

        def initialize()

            super

            @columns = Config::MODAL_SCREEN_WIDTH
            @rows = Config::MODAL_SCREEN_HEIGHT

            @x = (Config::GAME_SCREEN_WIDTH - @columns) / 2
            @y = (Config::GAME_SCREEN_HEIGHT - @rows) / 2

            @background_style = [:black]

            @response = nil

            Logger.log.info ("Created new Modal")

        end

        def yes_no(prompt)

            border = ModalBorder.new("modal_border", self, 1)
            add_control(border)

            text_prompt = CentredTextControl.new(3, Config::MODAL_SCREEN_WIDTH - 2, 3, :middle, :centre, prompt, Config::MODAL_SCREEN_WIDTH)
            add_control(text_prompt)

            yes_button = Button.new(7, 9, MODAL_BUTTON_WIDTH, MODAL_BUTTON_HEIGHT, "Yes")
            yes_button.register_event(:activate, -> {
                @response = true
            })
            yes_button.set_fill_style_selected([:yellow, :on_black])
            yes_button.set_text_style_selected([:yellow, :on_black, :inverse])
            yes_button.set_border_style([:yellow, :on_black])
            add_control(yes_button)

            
            no_button = Button.new(22, 9, MODAL_BUTTON_WIDTH, MODAL_BUTTON_HEIGHT, "No")
            no_button.add_link(WEST, yes_button, true)
            no_button.register_event(:activate, -> {
                @response = false
            })
            add_control(no_button)
            @selection_cursor.select_control(no_button)

            @escapecontrol = no_button

            @response = nil
            while @response.nil?
                draw()
                reader.read_keypress
                # Logger.log.info("Modal response = #{@response}")
                # Logger.log.info("Read keypress in menu_screen #{self.inspect}")
            end


            Logger.log.info("Modal response = #{@response}")
            return @response

        end

    end

end




