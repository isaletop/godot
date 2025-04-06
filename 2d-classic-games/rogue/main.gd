extends Node2D

class_name RogueDungeon

# Tile definitions
const WALL = "#"
const FLOOR = "."
const EMPTY = " "
const PLAYER = "@"
const UNKNOWN = " " # Fog of war representation (space)

# Dungeon parameters
var width: int = 80  # 10x original size
var height: int = 24 # 10x original size
var min_room_size: int = 4
var max_room_size: int = 8 # Reduced for smaller rooms
var max_rooms: int = 200 # More rooms for larger space
var max_tunnel_length: int = 5 # Shorten tunnel length
var dungeon: Array = []

# Player variables
var player_pos: Vector2i = Vector2i(0, 0)
@onready var label: Label = $DungeonLabel

# Fog of war variables
var visibility_radius: int = 7
var discovered: Array = [] # Tracks discovered tiles

# Camera/viewport variables
var viewport_width: int = 80    # Visible area width
var viewport_height: int = 24  # Visible area height
var camera_offset: Vector2i = Vector2i(0, 0) # Camera position

# Room class to store room data
class Room:
	var x: int
	var y: int
	var w: int
	var h: int

	func _init(x_pos: int, y_pos: int, width: int, height: int):
		x = x_pos
		y = y_pos
		w = width
		h = height

	func center() -> Vector2:
		return Vector2(x + w / 2, y + h / 2)

	func intersects(other: Room) -> bool:
		# Add a buffer of 1 to avoid rooms being adjacent
		return (x - 1 <= other.x + other.w and
				x + w + 1 >= other.x and
				y - 1 <= other.y + other.h and
				y + h + 1 >= other.y)

# Called when the node enters the scene tree
func _ready() -> void:
	# Set random seed for reproducible dungeons if needed
	randomize()

	# Generate the dungeon
	var rooms = generate()

	# Ensure we have rooms
	while rooms.size() == 0:
		rooms = generate()

	# Initialize fog of war
	init_fog_of_war()

	# Place player in the center of the first room
	var center = rooms[0].center()
	player_pos = Vector2i(center.x, center.y)

	# Make the starting room visible
	force_discover_starting_room(rooms[0])

	# Update player's visibility
	update_visibility()

	# Update camera position
	update_camera_offset()

	# Update the display
	update_display()

	# Set up input processing
	set_process_input(true)

# Update camera position to follow player
func update_camera_offset() -> void:
	camera_offset.x = player_pos.x - viewport_width / 2
	camera_offset.y = player_pos.y - viewport_height / 2
	# Clamp to dungeon bounds
	camera_offset.x = clamp(camera_offset.x, 0, width - viewport_width)
	camera_offset.y = clamp(camera_offset.y, 0, height - viewport_height)

# Force discovery of the starting room to ensure visibility
func force_discover_starting_room(room: Room) -> void:
	for y in range(max(0, room.y - 1), min(height, room.y + room.h + 1)):
		for x in range(max(0, room.x - 1), min(width, room.x + room.w + 1)):
			discovered[y][x] = true

# Initialize fog of war grid
func init_fog_of_war() -> void:
	discovered = []
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(false) # All tiles start undiscovered
		discovered.append(row)

# Process input for player movement
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var moved = false
		var new_pos = player_pos

		match event.keycode:
			KEY_UP:    # Up (using both arrow keys and vi keys)
				new_pos.y -= 1
				moved = true
			KEY_DOWN:  # Down
				new_pos.y += 1
				moved = true
			KEY_LEFT:  # Left
				new_pos.x -= 1
				moved = true
			KEY_RIGHT: # Right
				new_pos.x += 1
				moved = true
			KEY_R:      # Generate new dungeon
				var rooms = generate()
				# Ensure we have rooms
				while rooms.size() == 0:
					rooms = generate()

				init_fog_of_war()

				var center = rooms[0].center()
				player_pos = Vector2i(center.x, center.y)

				# Make the starting room visible
				force_discover_starting_room(rooms[0])

				update_visibility()
				update_camera_offset()
				update_display()
				return

		if moved:
			# Check if can move to the new position
			if can_move_to(new_pos.x, new_pos.y):
				# Update player position
				player_pos = new_pos
				# Update camera position
				update_camera_offset()
				# Update visibility around player
				update_visibility()
				# Update display
				update_display()

# Check if player can move to a position
func can_move_to(x: int, y: int) -> bool:
	if x < 0 or x >= width or y < 0 or y >= height:
		return false

	var tile = dungeon[y][x]
	return tile == FLOOR

# Update visibility around player
func update_visibility() -> void:
	# Mark tiles within visibility radius as discovered
	for y in range(max(0, player_pos.y - visibility_radius),
				min(height, player_pos.y + visibility_radius + 1)):
		for x in range(max(0, player_pos.x - visibility_radius),
					min(width, player_pos.x + visibility_radius + 1)):
			# Calculate squared distance to player
			var dx = x - player_pos.x
			var dy = y - player_pos.y
			var distance_squared = dx * dx + dy * dy

			# Check if within visibility circle
			if distance_squared <= visibility_radius * visibility_radius:
				# Simple ray casting to check for line of sight
				if has_line_of_sight(player_pos, Vector2i(x, y)):
					discovered[y][x] = true

# Simple line-of-sight algorithm using Bresenham's line algorithm
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	# If the target is a wall, we can still see it
	var target_is_wall = dungeon[to.y][to.x] == WALL

	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	var x = x0
	var y = y0

	while x != x1 or y != y1:
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

		# Skip the starting point
		if x == x0 and y == y0:
			continue

		# Skip the target if it's a wall (we can see walls)
		if x == x1 and y == y1 and target_is_wall:
			return true

		# If we hit a wall before reaching the target, no line of sight
		if dungeon[y][x] == WALL:
			return false

	return true

# Generate a new dungeon layout
func generate() -> Array:
	# Initialize with empty spaces
	dungeon = []
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(EMPTY)
		dungeon.append(row)

	var rooms = []

	# Generate rooms with retry logic
	var attempts = 0
	var max_attempts = 1000 # Increased for larger dungeon

	while rooms.size() < max_rooms and attempts < max_attempts:
		attempts += 1

		# Random room size
		var w = randi() % (max_room_size - min_room_size + 1) + min_room_size
		var h = randi() % (max_room_size - min_room_size + 1) + min_room_size

		# Random position (leaving room for walls)
		var x = randi() % (width - w - 2) + 1
		var y = randi() % (height - h - 2) + 1

		var new_room = Room.new(x, y, w, h)

		# Check if this room intersects with any other room
		var failed = false
		for other_room in rooms:
			if new_room.intersects(other_room):
				failed = true
				break

		if not failed:
			create_room(new_room)

			# Connect to previous room
			if rooms.size() > 0:
				var prev_center = rooms[rooms.size() - 1].center()
				var new_center = new_room.center()

				# Randomly decide whether to do horizontal or vertical tunnel first
				if randi() % 2 == 1:
					create_h_tunnel(int(prev_center.x), int(new_center.x), int(prev_center.y))
					create_v_tunnel(int(prev_center.y), int(new_center.y), int(new_center.x))
				else:
					create_v_tunnel(int(prev_center.y), int(new_center.y), int(prev_center.x))
					create_h_tunnel(int(prev_center.x), int(new_center.x), int(new_center.y))

			rooms.append(new_room)

	# Add walls around the floor spaces
	add_walls()

	return rooms

# Create a room (filled with floor tiles)
func create_room(room: Room) -> void:
	for y in range(room.y, room.y + room.h):
		for x in range(room.x, room.x + room.w):
			dungeon[y][x] = FLOOR

# Create a horizontal tunnel
func create_h_tunnel(x1: int, x2: int, y: int) -> void:
	var start_x = min(x1, x2)
	var end_x = max(x1, x2)
	for x in range(start_x, end_x + 1):
		if 0 <= y and y < height and 0 <= x and x < width:
			if dungeon[y][x] == EMPTY:
				dungeon[y][x] = FLOOR

# Create a vertical tunnel
func create_v_tunnel(y1: int, y2: int, x: int) -> void:
	var start_y = min(y1, y2)
	var end_y = max(y1, y2)
	for y in range(start_y, end_y + 1):
		if 0 <= y and y < height and 0 <= x and x < width:
			if dungeon[y][x] == EMPTY:
				dungeon[y][x] = FLOOR

# Add walls around floor spaces
func add_walls() -> void:
	var temp_dungeon = []

	# Create a copy of the dungeon
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(dungeon[y][x])
		temp_dungeon.append(row)

	# Add walls where needed
	for y in range(height):
		for x in range(width):
			if dungeon[y][x] == EMPTY:
				# Check if any adjacent tile is a floor
				var adjacent_floor = false
				for nx in [x-1, x, x+1]:
					for ny in [y-1, y, y+1]:
						if 0 <= ny and ny < height and 0 <= nx and nx < width:
							if dungeon[ny][nx] == FLOOR:
								adjacent_floor = true
								break

				if adjacent_floor:
					temp_dungeon[y][x] = WALL

	dungeon = temp_dungeon

# Update the display with current dungeon state and player position
func update_display() -> void:
	if not label:
		return

	var display_text = ""

	for dy in range(viewport_height):
		var y = camera_offset.y + dy
		if y < 0 or y >= height:
			display_text += "\n"
			continue

		var row_text = ""
		for dx in range(viewport_width):
			var x = camera_offset.x + dx
			if x < 0 or x >= width:
				row_text += UNKNOWN
				continue

			if discovered[y][x]:
				var distance_squared = (x - player_pos.x)**2 + (y - player_pos.y)**2
				if distance_squared <= visibility_radius * visibility_radius and has_line_of_sight(player_pos, Vector2i(x, y)):
					row_text += dungeon[y][x]
				else:
					row_text += dungeon[y][x]
			else:
				row_text += UNKNOWN

		if y == player_pos.y:
			var px = player_pos.x - camera_offset.x
			if px >= 0 and px < viewport_width:
				row_text = row_text.left(px) + PLAYER + row_text.substr(px + 1)

		display_text += row_text + "\n"

	var total_walls = 0
	var discovered_walls = 0

	for y in range(height):
		for x in range(width):
			if dungeon[y][x] == WALL:
				total_walls += 1
				if discovered[y][x]:
					discovered_walls += 1

	var percentage_discovered = int(float(discovered_walls) / total_walls * 100) if total_walls > 0 else 0

	display_text += "Discovered: " + str(percentage_discovered) + "%\n"

	label.text = display_text

# Print the dungeon to the console (for debugging)
func print_dungeon() -> void:
	var result = ""
	for row in dungeon:
		result += "".join(row) + "\n"
	print(result)
