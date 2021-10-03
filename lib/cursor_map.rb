module CincoDados

    class SelectionCursorMapNode

        attr_reader :links, :name, :enabled

        def initialize(name)
            @links = {}  # { direction, node}
            # @alternate_links_if_disabled {} # {attempted direction, node}
            @name = name
            @enabled = true
        end

        def add_link(direction, cursorMapNode, mirror)
            if !direction.is_a?(Direction)
                raise ArgumentError.new("Direction must be an instance of Direction class")
            end
            if !cursorMapNode.is_a?(SelectionCursorMapNode)
                raise ArgumentError.new("cursorMapNode must be an instance of SelectionCursorMapNode class")
            end
            # Logger.log.info("inside add_link: Set link on #{self} in direction: #{direction} to node #{cursorMapNode}")
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

        def can_follow_link(direction)
            # check if the linked control can be followed
            next_control = follow_link(direction)
            Logger.log.info("#{__method__}: the linked control is #{next_control.inspect}")

            if next_control.nil?
                # raise StandardError.new("Cannot Move in direction: #{direction}")
                Logger.log.warn("#{__method__}: Cannot Move in direction: #{direction}. #{self} has a link but it returns nil")
                return false
            else
                Logger.log.warn("#{__method__}: can follow link , off we go")
                return true
            end

        end

        def follow_link(direction)
            # if @links[direction].is_a?(SelectionCursorMapNode)
            #     return @links[direction]
            # else
            #     raise ArgumentError.new("Trying to move in an unlinked direction. direction: #{direction} does not contain valid CursorMapNode")
            # end
            if @links[direction].is_a?(SelectionCursorMapNode)
                Logger.log.info("#{self} has a link in direction #{direction} to node: #{@links[direction]}")
                if @links[direction].enabled
                    Logger.log.info("link points to node: #{@links[direction]} which is enabled")
                    return @links[direction]
                else
                    Logger.log.info("link points to node: #{@links[direction]} which is disabled, recursing")
                    next_node = @links[direction].follow_link(direction)
                    unless next_node.nil?
                        Logger.log.info("Continuing in same direction #{direction}")
                        return next_node
                    else
                        Logger.log.info("Cannot continue in same direction #{direction}")
                        return nil
                        # links_excluding_self = @links[direction].links.reject do |dir,node|
                        #     node.equal?(self)
                        # end
                        # if links_excluding_self.length > 0
                        #     Logger.log.info("Node #{@links[direction]} contains other links besides self")
                        #     alternate_link =  links_excluding_self.first
                        #     Logger.log.info("Node #{@links[direction]} contains other links besides self, following alternate direction: #{alternate_link[0]} to node: #{alternate_link[1]}")
                        #     return alternate_link[1]
                        # else
                        #     Logger.log.info("Node #{@links[direction]} does not contain other links besides self")
                        #     return nil
                        # end

                    end
                end
            else
                return nil
            end
        end

        def delete_link(direction)
            unless links[direction].nil?
                links[direction].delete(direction)
            else
                raise ArgumentError.new("Cannot delete non-existant link from #{self} in direction #{direction}.")
            end
        end

        def disable()
            @enabled = false
        end

        def enable()
            @enabled = true
        end

        def enabled?()
            @enabled
        end

        def disabled?()
            !@enabled
        end

        def on_selected()
        end

        def on_deselected()
        end

        def on_activate()
        end

        def to_s()
            return @name
        end

        def inspect()
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