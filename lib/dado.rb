require_relative "control"

module CincoDados
    class Dado < Control

        WIDTH = 7
        HEIGHT = 4
        X_MARGIN = 1
        Y_MARGIN = 0

        ON_ACTIVATE_DESCRIPTION_UNLOCKED = "lock dado"
        ON_ACTIVATE_DESCRIPTION_LOCKED = "unlock dado"

        attr_reader :value


        def initialize(game_screen, dados_cup, x, y, name)


            super(name)
            set_position(x,y)
            @@full_block = "\u{2588}"
            @@pip = "\u{2584}"
            @game_screen = game_screen
            @dados_cup = dados_cup
            @width = WIDTH
            @height = HEIGHT
            @x_margin = X_MARGIN
            @y_margin = Y_MARGIN
            @locked = false
            @enabled = false


            style = [:white, :on_black]
            fill = {char: @@full_block, style: style}
            initial_fill(fill)
            # initial_fill(@@full_block)

            @prng = Random.new
            @value = @prng.rand(6) + 1

            @rows[height-1] = Array.new(@width, {char: "\u{1FB0E}", style: style})  #bottom half row
            
            @rows[0][0] = {char: "\u{1FB44}", style: style} #top left corner
            @rows[0][@width-1] = {char: "\u{1FB4F}", style: style} #top right corner
            @rows[@height-1][0] = {char: "\u{1FB65}", style: style} #bottom left corner
            @rows[@height-1][@width-1] = {char: "\u{1FB5A}", style: style} #bottom right corner


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
                    @rows[0][1] = {char: @@pip, style: style}
                    @rows[2][5] = {char: @@pip, style: style}
                end
                if @value == 4 || @value == 5 || @value == 6
                    @rows[0][5] = {char: @@pip, style: style}
                    @rows[2][1] = {char: @@pip, style: style}
                end
                if @value == 6
                    @rows[1][1] = {char: @@pip, style: style}
                    @rows[1][5] = {char: @@pip, style: style}
                end
                if @value == 1 || @value == 3 || @value == 5
                    @rows[1][3] = {char: @@pip, style: style}
                end
            else
                raise DadosError.new("You can't roll a locked dado")
            end
        end

        def reset_pips_to_blank()
            style = [:white, :on_black]
            (0..2).each do |row|
                [1,5].each do |side|
                    @rows[row][side] = {char: @@full_block, style: style}
                end
            end
            @rows[1][3]= {char: @@full_block, style: style}
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
        def get_on_activate_description()
            if @locked
                ON_ACTIVATE_DESCRIPTION_LOCKED
            else
                ON_ACTIVATE_DESCRIPTION_UNLOCKED
            end
        end

    end
end