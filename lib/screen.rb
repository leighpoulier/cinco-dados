require "pastel"
require "tty-cursor"
module CincoDados
    class Screen

        attr_reader :columns, :rows, :info_line, :selection_cursor
        def initialize(width, height)
            @controls = []
            # @dados=[]
            @columns = width
            @rows = height

            @cursor = TTY::Cursor
            print @cursor.move_to
            print @cursor.hide

            @pastel = Pastel.new

            system("clear")
        end

        def add_control(control)
            @controls.push(control)
            @controls.sort!
            # Logger.log.info("@controls order #{@controls.join(", ")}")
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
                    print @pastel.black("\u{2588}")
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
            @controls.each do |control|
                control.draw(@cursor)
            end
            print @cursor.move_to(0, @rows)
        end


        def clean_up()

            print @cursor.show
        end

    end

    class GameScreen < Screen

        attr_reader :button

        def initialize(width, height)
            super(width, height)


        # create roll button
        @button = Button.new(20, 14, 8, 3, "\u{1FB99}", "ROLL", "roll")
        add_control(@button)        
            
        # create selection cursor
        @selection_cursor = SelectionCursor.new(button, "cursor")
        add_control(@selection_cursor)
        # set_selection_cursor(selection_cursor)
        
        # create info_line
        @info_line = InfoLine.new(columns, rows-1)
        add_control(@info_line)
        # set_info_line(info_line)


        end


    end

end




