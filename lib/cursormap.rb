require("tty-reader")

class Cursor

    def initialize(node)
        @selected_node = node
        print_status
    end

    def select_node(node)
        @selected_node = node
        print_status
    end

    def move(direction)
        if @selected_node.has_link(direction)
            @selected_node = @selected_node.follow_link(direction)
            print_status
        else
            puts "Cannot Move in direction: #{direction}"
        end
    end

    def print_status()
        system("clear")
        puts "selected node = #{@selected_node}"
        print "I can move"
        if @selected_node.links.length == 0
            puts " nowhere \u{1F622}"
        else
            counter = 0
            @selected_node.links.each do |link_direction, node|
                print " #{link_direction} to #{node}"
                if counter == @selected_node.links.length - 2
                    print " or"
                elsif counter != @selected_node.links.length - 1
                    print ","
                end
                counter += 1
            end
        end
        puts "."
    end

    def keypress(event)  # implements subscription of TTY::Reader
        # puts "name = #{event.key.name}"
        # puts "value = #{event.value}"
        case
        when event.key.name == :up || event.value == "w"
            move(NORTH)
        when event.key.name == :right|| event.value == "d"
            move(EAST)
        when event.key.name == :down|| event.value == "s"
            move(SOUTH)
        when event.key.name == :left|| event.value == "a"
            move(WEST)
        end
    end

end

class CursorMapNode

    attr_reader :links, :name


    def initialize(name)
        @links = {}
        @name = name
    end

    def add_link(direction, cursorMapNode)
        @links[direction] = cursorMapNode
        unless cursorMapNode.has_link(direction.opposite)
            cursorMapNode.add_link(direction.opposite, self)
        end
    end

    def has_link(direction)
        return !@links[direction].nil?
    end

    def follow_link(direction)
        if @links[direction].is_a?(CursorMapNode)
            return @links[direction]
        else
            raise "CursorMapNode - Link direction does not contain valid CursorMapNode"
        end
    end

    def to_s()
        return @name
    end

end

class Direction

    attr_reader :direction, :opposite

    def initialize(direction_symbol)
        @direction = direction_symbol
    end

    def set_opposite(opposite)
        @opposite = opposite
        if @opposite.opposite.nil?
            @opposite.set_opposite(self)
        end
    end

    def to_s()
        return @direction.to_s
    end

end

module CompassDirections
    # Group of standard directions to be used everywhere
    NORTH = Direction.new(:north)
    SOUTH = Direction.new(:south)
    SOUTH.set_opposite(NORTH)
    EAST = Direction.new(:east)
    WEST = Direction.new(:west)
    WEST.set_opposite(EAST)
end
