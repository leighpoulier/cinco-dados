# require("tty-reader")

module CincoDados

    class SelectionCursorMapNode

        attr_reader :links, :name

        def initialize(name)
            @links = {}
            @name = name
        end

        def add_link(direction, cursorMapNode, mirror)
            @links[direction] = cursorMapNode
            if mirror
                unless cursorMapNode.has_link(direction.opposite)
                    cursorMapNode.add_link(direction.opposite, self, false)
                end
            end
        end

        def has_link(direction)
            # if @links.empty?
            #     return false
            # else
                return !@links[direction].nil?
            # end
        end

        def follow_link(direction)
            if @links[direction].is_a?(SelectionCursorMapNode)
                return @links[direction]
            else
                raise ArgumentError.new("Trying to move in an unlinked direction. direction: #{direction} does not contain valid CursorMapNode")
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
end