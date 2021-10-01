require_relative "control"


class BorderControl < Control

    def initialize(name, height, width)

        super(name)
        @height = height
        @width = width


    end

    def decorate_control(type = :box, style)
        #style can be :box :sides :none

        # set the border characters

        initial_fill({char: :transparent, style: style})


        case type
        when :sides

            (1...@height-1).each do |row|
                @rows[row][0] = { char: "\u{2503}", style: style}  #left side
                @rows[row][width - 1] = { char: "\u{2503}", style: style}  #right side
            end
            
        when :box

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
        when :none

        end
    end


end
class EnclosingBorderControl < BorderControl

    attr_reader :enclosed_control

    def enclose_control()
        if @enclosed_control.nil?
            raise ConfigurationError.new("@enclosed_control is not set, no dimensions set, cannot decorate the selection cursor!")
        end
        @width = @enclosed_control.width + 2 * (1 + @enclosed_control.x_margin)
        @height = @enclosed_control.height + 2 * (1 + @enclosed_control.y_margin)
        @x = @enclosed_control.x-@enclosed_control.x_margin-1
        @y = @enclosed_control.y-@enclosed_control.y_margin-1
    end

    def decorate_control(selection_type, style)
        if @enclosed_control.nil?
            raise ConfigurationError.new("@enclosed_control is not set, no dimensions set, cannot decorate the enclosing border cursor!")
        end
        
        super

    end


end

class LockedBorder < EnclosingBorderControl


    
    def initialize(control, name)

        @enclosed_control = control
        enclose_control()
        set_position(@x, @y)
        super(name, @height, @width)
        decorate_control()
    end

    def decorate_control()
        # set the border characters

        

        style = [:red, :on_black]
        initial_fill({char: :transparent, style: style})

        # [1,@width-2].each do |col|
        #     @rows[0][col] = { char: "\u{2501}", style: style}  #top row
        #     @rows[@height - 1][col] = { char: "\u{2501}", style: style} #bottom row
        # end

        [2].each do |row|
            @rows[row][0] = { char: "\u{2503}", style: style}  #left side full bar
            @rows[row][width - 1] = { char: "\u{2503}", style: style}  #right side full bar
        end
        [3].each do |row|
            @rows[row][0] = { char: "\u{2579}", style: style}  #left side top half bar
            @rows[row][width - 1] = { char: "\u{2579}", style: style}  #right side top half bar
        end


        # @rows[0][0] = { char: "\u{250F}", style: style} #top left corner
        # @rows[0][@width - 1] = { char: "\u{2513}", style: style} #top right corner
        # @rows[@height - 1][0] = { char: "\u{2517}", style: style} #bottom left corner
        # @rows[@height - 1][@width - 1] = { char: "\u{251B}", style: style} #bottom left corner
    end

    # override to ignore margin
    def enclose_control()
        @width = @enclosed_control.width + 2
        @height = @enclosed_control.height + 2
        @x = @enclosed_control.x-1
        @y = @enclosed_control.y-1
    end

end

class SelectionCursor < EnclosingBorderControl


    def initialize(screen, name)
        @screen = screen
        @previously_enclosed_control = nil
        @enclosed_control = nil
        # select_control(control)
        super(name, 0, 0)
        set_position(@x,@y)
        @style = [:green, :on_black]
        
    end

    def select_control(control)
        unless @enclosed_control.nil?
            # @enclosed_control.is_selected = false
            @enclosed_control.on_deselected
            # @previously_enclosed_control = @enclosed_control  #save for linking backwards below
        end
        @enclosed_control = control
        # @enclosed_control.is_selected = true
        @enclosed_control.on_selected

        # use the opposite direction link on the target control to return to the last control.  
        # Logger.log.info("Inside select_control, direction: #{direction.inspect}")
        # unless direction.nil?
        #     Logger.log.info("Overwrite link on #{enclosed_control} with #{direction.opposite}")
        #     @enclosed_control.add_link(direction.opposite, @previously_enclosed_control, false)
        # end

        enclose_control()                                   # sets the position and dimensions

                
        if @enclosed_control.nil?
            style = @style
        else
            style = @enclosed_control.border_style()
        end

        decorate_control(@enclosed_control.selection_type, style)  # draws the box, for example


    end


    def move(direction)
        if @enclosed_control.nil?
            raise ConfigurationError.new("@enclosed_control is not set, no links, cannot move!")
        end
        if @enclosed_control.has_link(direction)
            # @enclosed_control = @enclosed_control.follow_link(direction)
            next_control = @enclosed_control.follow_link(direction)
            unless next_control.nil?
                select_control(next_control)
            else
                # raise StandardError.new("Cannot Move in direction: #{direction}")
                Logger.log.warn("Cannot Move in direction: #{direction}. #{@enclosed_control} has a link but it returns nil")
            end
        else
            # raise StandardError.new("Cannot Move in direction: #{direction}")
            Logger.log.warn("Cannot Move in direction: #{direction}. #{@enclosed_control} has no link.")
        end
    end


    def on_activate()
        if @enclosed_control.nil?
            raise ConfigurationError.new("@enclosed_control is not set, cannot activate!")
        end
        Logger.log.info("Selection Cursor activating control: #{@enclosed_control}")
        @enclosed_control.on_activate

    end

    
    # return information about available links for cursor navigation and their directions
    def get_status()
        if @enclosed_control.nil?
            raise ConfigurationError.new("@enclosed_control is not set, no status!")
        end
        status = ""
        status << "#{@enclosed_control} (#{@enclosed_control.enabled ? "enabled" : "disabled"}): "
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

class ModalBorder < BorderControl

    def initialize(name, modal, margin)
        super(name, modal.rows - 2 * margin, modal.columns - 4 * margin)
        set_position(margin, margin)
        @style = [:white, :on_black]
        decorate_control(:box, @style)
    end

end