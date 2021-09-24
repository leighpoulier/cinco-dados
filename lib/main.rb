require_relative("cursormap")
include CompassDirections

map_node_1 = CursorMapNode.new("node_1")
map_node_2 = CursorMapNode.new("node_2")
map_node_2.add_link(NORTH, map_node_1)

map_node_3 = CursorMapNode.new("node_3")
map_node_3.add_link(WEST, map_node_1)

map_node_4 = CursorMapNode.new("node_4")
map_node_4.add_link(NORTH, map_node_3)
map_node_4.add_link(WEST, map_node_2)


cursor_1 = Cursor.new(map_node_1)
cursor_1.move(SOUTH)
cursor_1.move(EAST)
cursor_1.move(NORTH)
cursor_1.move(WEST)

map_node_5 = CursorMapNode.new("node_5")
cursor_2 = Cursor.new(map_node_5)


