require "pastel"
require "tty-cursor"
module CincoDados
    class Screen

        attr_reader :columns, :rows, :dados
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
            control.set_screen(self)
        end

        def delete_control(control)
            if @controls.include?(control)
                @controls.delete(control)
            else
                raise ArgumentError.new("No such control in controls array")
            end
        end

        # def add_dado(dado)
        #     if dado.instance_of? Dado
        #         @dados.push(dado)
        #     else
        #         raise ArgumentError.new("Control must be an instance of Dado to add to dados array")
        #     end
        # end

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

        def display_message(message)
            @info_line.display_message(message)
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
            

            @controls.sort!
            Logger.log.info("@controls order #{@controls.join(", ")}")
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

end




