require_relative "control"

module CincoDados
    class Dado < Control

        WIDTH = 7
        HEIGHT = 4
        X_MARGIN = 1
        Y_MARGIN = 0

        CONTEXT_HELP_ADDON_UNLOCKED = "lock dado"
        CONTEXT_HELP_ADDON_LOCKED = "unlock dado"
        CONTEXT_HELP = "Navigate with #{Screen::UNICODE_UP_ARROW}#{Screen::UNICODE_DOWN_ARROW}#{Screen::UNICODE_RIGHT_ARROW} and Enter/Space to "


        attr_reader :value


        def initialize(game_screen, dados_cup, x, y, name)


            super(name)
            set_position(x,y)
            @game_screen = game_screen
            @dados_cup = dados_cup
            @width = WIDTH
            @height = HEIGHT
            @x_margin = X_MARGIN
            @y_margin = Y_MARGIN
            @locked = false
            @enabled = false


            style = [:white, :on_black]
            fill = {char: BLOCK_FULL, style: style}
            initial_fill(fill)

            @prng = Random.new
            @value = @prng.rand(6) + 1

            @rows[height-1] = Array.new(@width, {char: DICE_BOTTOM_ROW_HALF, style: style})  #bottom half row
            
            @rows[0][0] = {char: DICE_TOP_LEFT_CORNER, style: style} #top left corner
            @rows[0][@width-1] = {char: DICE_TOP_RIGHT_CORNER, style: style} #top right corner
            @rows[@height-1][0] = {char: DICE_BOTTOM_LEFT_CORNER, style: style} #bottom left corner
            @rows[@height-1][@width-1] = {char: DICE_BOTTOM_RIGHT_CORNER, style: style} #bottom right corner


            @locked_border = LockedBorder.new(self, "locked_" + self.name)
            game_screen.add_control(@locked_border)
            @locked_border.hide()

            # roll()
            
        end

        def roll()

            unless @locked

                reset_pips_to_blank()

                @value = @prng.rand(6) + 1
                @dados_cup.increment_dados_stats("roll#{@value}".to_sym)

                if @value < 1 || @value > 6 || !@value.instance_of?(Integer)
                    raise DadosError.new("Invalid dado @value: #{@value}")
                end

                style = [:white, :on_black, :inverse]
                
                if @value == 2 || @value == 3 || @value == 4 || @value == 5 || @value == 6
                    @rows[0][1] = {char: BLOCK_LOWER_HALF, style: style}
                    @rows[2][5] = {char: BLOCK_LOWER_HALF, style: style}
                end
                if @value == 4 || @value == 5 || @value == 6
                    @rows[0][5] = {char: BLOCK_LOWER_HALF, style: style}
                    @rows[2][1] = {char: BLOCK_LOWER_HALF, style: style}
                end
                if @value == 6
                    @rows[1][1] = {char: BLOCK_LOWER_HALF, style: style}
                    @rows[1][5] = {char: BLOCK_LOWER_HALF, style: style}
                end
                if @value == 1 || @value == 3 || @value == 5
                    @rows[1][3] = {char: BLOCK_LOWER_HALF, style: style}
                end
            else
                raise DadosError.new("You can't roll a locked dado")
            end
        end

        def reset_pips_to_blank()
            style = [:white, :on_black]
            (0..2).each do |row|
                [1,5].each do |side|
                    @rows[row][side] = {char: BLOCK_FULL, style: style}
                end
            end
            @rows[1][3]= {char: BLOCK_FULL, style: style}
        end

        def toggle_lock()
            if @locked
                remove_lock()
            else
                add_lock()
            end
        end

        def add_lock()
            # @game_screen.add_control(@locked_border)
            @locked_border.show
            @locked = true
            # Logger.log.info("New Locked Border: " + @locked_border.name + ", " + @locked_border.inspect)

            enable_disable_roll_button()

        end

        def remove_lock()
            # @game_screen.delete_control(@locked_border)
            @locked_border.hide
            @locked = false

            enable_disable_roll_button()

        end

        def enable_disable_roll_button()
            if @dados_cup.all_locked?
                @game_screen.roll_button.disable
            else
                @game_screen.roll_button.enable
            end
        end

        def locked?
            return @locked
        end

        def hide_lock()
            @locked_border.hide
        end

        def show_lock()
            @locked_border.show
        end

        #override
        def on_activate()
            toggle_lock()
        end

        #override
        def get_context_help()
            Logger.log.info("Returning custom context help, for object #{self} of class #{self.class.name}")
            if @locked
                CONTEXT_HELP + CONTEXT_HELP_ADDON_LOCKED
            else
                CONTEXT_HELP + CONTEXT_HELP_ADDON_UNLOCKED
            end
        end

    end
end