require_relative("cursormap")
require("pastel")
include CompassDirections

nodes=[]

nodes.push(CursorMapNode.new("node_0"))
nodes.push(CursorMapNode.new("node_1"))
nodes[1].add_link(NORTH, nodes[0])

nodes.push(CursorMapNode.new("node_2"))
nodes[2].add_link(WEST, nodes[0])

nodes.push(CursorMapNode.new("node_3"))
nodes[3].add_link(NORTH, nodes[2])
nodes[3].add_link(WEST, nodes[1])


cursor_1 = Cursor.new(nodes[0])
# cursor_1.move(SOUTH)
# cursor_1.move(EAST)
# cursor_1.move(NORTH)
# cursor_1.move(WEST)

# map_node_5 = CursorMapNode.new("node_5")
# cursor_2 = Cursor.new(map_node_5)


reader = TTY::Reader.new(interrupt: Proc.new do
    puts "Exiting ... Goodbye!"
    exit
end)

reader.subscribe(cursor_1)


pastel=Pastel.new
pastel.red.on_green.bold("Unicorns!")

while true do
    pastel.red.on_green.bold("Unicorns!")
    reader.read_keypress
end