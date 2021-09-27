require_relative("control")

class BorderControl < Control

    attr_reader :enclosed_control

    def enclose_control()
        @width = @enclosed_control.width + 2 * (1 + @enclosed_control.x_margin)
        @height = @enclosed_control.height + 2 * (1 + @enclosed_control.y_margin)
        @x = @enclosed_control.x-@enclosed_control.x_margin-1
        @y = @enclosed_control.y-@enclosed_control.y_margin-1
    end

    def decorate_control()

        initial_fill({char: :transparent, style: []})

    end


end

class LockedBorder < BorderControl
    
    def initialize(control, name)

        @enclosed_control = control
        enclose_control()
        super(@x, @y, name)
        decorate_control()
    end

    def decorate_control()
        # set the border characters

        super  # initial_fill({char: :transparent, style: [])

        style = [:red, :on_black]

        # [1,@width-2].each do |col|
        #     @rows[0][col] = { char: "\u{2501}", style: style}  #top row
        #     @rows[height - 1][col] = { char: "\u{2501}", style: style} #bottom row
        # end

        [2].each do |row|
            @rows[row][0] = { char: "\u{2503}", style: style}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", style: style}  #right side
        end
        [3].each do |row|
            @rows[row][0] = { char: "\u{2579}", style: style}  #left side
            @rows[row][width - 1] = { char: "\u{2579}", style: style}  #right side
        end


        # @rows[0][0] = { char: "\u{250F}", style: style} #top left corner
        # @rows[0][@width - 1] = { char: "\u{2513}", style: style} #top right corner
        # @rows[@height - 1][0] = { char: "\u{2517}", style: style} #bottom left corner
        # @rows[@height - 1][@width - 1] = { char: "\u{251B}", style: style} #bottom left corner
    end

    def enclose_control()
        @width = @enclosed_control.width + 2
        @height = @enclosed_control.height + 2
        @x = @enclosed_control.x-1
        @y = @enclosed_control.y-1

    end

end

class SelectionCursor < BorderControl


    def initialize(control, name)
        select_control(control)
        super(@x, @y, name)
        
    end

    def select_control(control)
        unless @enclosed_control.nil?
            @enclosed_control.is_selected = false
            @enclosed_control.on_deselected
        end
        @enclosed_control = control
        @enclosed_control.is_selected = true
        @enclosed_control.on_selected
        enclose_control()
        decorate_control()
    end

    def decorate_control()
        # set the border characters

        super # initial_fill({char: :transparent, style: [])

        style = [:green, :on_black]

        # draw a square

        (0...@width).each do |col|
            @rows[0][col] = { char: "\u{2501}", style: style}  #top row
            @rows[height - 1][col] = { char: "\u{2501}", style: style} #bottom row
        end

        (0...@height).each do |row|
            @rows[row][0] = { char: "\u{2503}", style: style}  #left side
            @rows[row][width - 1] = { char: "\u{2503}", style: style}  #right side
        end

        @rows[0][0] = { char: "\u{250F}", style: style} #top left corner
        @rows[0][@width - 1] = { char: "\u{2513}", style: style} #top right corner
        @rows[@height - 1][0] = { char: "\u{2517}", style: style} #bottom left corner
        @rows[@height - 1][@width - 1] = { char: "\u{251B}", style: style} #bottom left corner
    end

    def move(direction)
        if @enclosed_control.has_link(direction)
            # @enclosed_control = @enclosed_control.follow_link(direction)
            select_control(@enclosed_control.follow_link(direction))
        else
            puts "Cannot Move in direction: #{direction}"
        end
    end

    def keypress(event)  # implements subscription of TTY::Reader
        @screen.display_message("")
        case
        when event.key.name == :up || event.value == "w"
            move(NORTH)
        when event.key.name == :right || event.value == "d"
            move(EAST)
        when event.key.name == :down || event.value == "s"
            move(SOUTH)
        when event.key.name == :left || event.value == "a"
            move(WEST)
        when event.key.name == :return || event.key.name == :space
            @enclosed_control.activate
        end
        # @screen.display_message(get_status())
    end

    
    # return information about available links for cursor navigation and their directions
    def get_status()
        status = ""
        status << "#{@enclosed_control}: "
        status <<  "I can move"
        if @enclosed_control.links.length == 0
            status <<  " nowhere \u{1F622}"
        else
            counter = 0
            @enclosed_control.links.each do |link_direction, node|
                status <<  " #{link_direction} to #{node}"
                if counter == @enclosed_control.links.length - 2
                    status <<  " or"
                elsif counter != @enclosed_control.links.length - 1
                    status <<  ","
                end
                counter += 1
            end
        end
        status <<  "."
        return status
    end

end