extends Node2D

# Grid size and field
var grid_size = 50
var segment_size = 42
var grid_width = 10
var grid_height = 10

# Colors
var grid_color = Color(0.5, 0.5, 0.5)
var snake_color = Color(0, 1, 0)  # Green snake
var food_color = Color(1, 0, 0)   # Red food

# Directions
enum Direction { UP, DOWN, LEFT, RIGHT }
var current_direction = Direction.RIGHT
var next_direction = Direction.RIGHT

# Snake
var snake = [Vector2(5, 5)]  # Initial snake position
var snake_length = 1

# Food
var food_position = Vector2.ZERO
var food_spawned = false

# Timers
var move_timer = 0.2
var current_time = 0.0

# Victory condition
var victory_length = 100  # Length of the snake at which the game is won

# Game state
var game_over_flag = false
var win_flag = false

# Nodes for displaying text
@onready var label = $Label

@onready var sprite = $Sprite2D

func _ready():
	# Initialize food
	spawn_food()
	set_position(Vector2.ZERO)  # Start drawing from the top-left corner
	sprite.z_index = -1

# Drawing
func _draw():
	if game_over_flag or win_flag:
		return  # If the game is over, don't draw the grid and snake	
	
	# Draw the snake
	for segment in snake:
		var offset = (grid_size - segment_size) / 2
		draw_rect(Rect2(segment * grid_size + Vector2(offset, offset), Vector2(segment_size, segment_size)), snake_color)
	
	# Draw the food
	draw_rect(Rect2(food_position * grid_size, Vector2(grid_size, grid_size)), food_color)

# Movement processing
func _process(delta):
	if game_over_flag or win_flag:
		return  # If the game is over, stop updating

	current_time += delta
	if current_time >= move_timer:
		current_time = 0.0
		move_snake()

	# Handle movement
	if Input.is_action_just_pressed("ui_up") and current_direction != Direction.DOWN:
		next_direction = Direction.UP
	elif Input.is_action_just_pressed("ui_down") and current_direction != Direction.UP:
		next_direction = Direction.DOWN
	elif Input.is_action_just_pressed("ui_left") and current_direction != Direction.RIGHT:
		next_direction = Direction.LEFT
	elif Input.is_action_just_pressed("ui_right") and current_direction != Direction.LEFT:
		next_direction = Direction.RIGHT

# Snake movement
func move_snake():
	current_direction = next_direction
	var head = snake[0]

	match current_direction:
		Direction.UP:
			head.y -= 1
		Direction.DOWN:
			head.y += 1
		Direction.LEFT:
			head.x -= 1
		Direction.RIGHT:
			head.x += 1

	# Add new segment to the snake's head
	snake.insert(0, head)

	# Check for food
	if head == food_position:
		snake_length += 1
		food_spawned = false  # Food eaten, need to spawn new food
	else:
		snake.pop_back()  # Remove last segment if no food was eaten

	# Check for collision with boundary or snake's body
	if head.x < 0 or head.x >= grid_width or head.y < 0 or head.y >= grid_height or head in snake.slice(1, snake.size()):
		game_over()

	# Spawn new food if the old one was eaten
	if not food_spawned:
		spawn_food()

	# Check for victory
	if snake_length >= victory_length:
		win_game()

	queue_redraw()  # Redraw the screen

# Spawn food
func spawn_food():
	food_position = Vector2(randi_range(0, grid_width - 1), randi_range(0, grid_height - 1))
	# Ensure food doesn't spawn on the snake
	while food_position in snake:
		food_position = Vector2(randi_range(0, grid_width - 1), randi_range(0, grid_height - 1))
	
	food_spawned = true

# Game over
func game_over():
	game_over_flag = true
	label.text = "Game Over!\nPress any key or click to restart."
	print("Game Over!")
	sprite.hide()

# Win game
func win_game():
	win_flag = true
	label.text = "You Win!\nPress any key or click to restart."
	print("You Win!")
	sprite.hide()

# Restart the game on key press or mouse click
func _input(event):
	if game_over_flag or win_flag:
		if event is InputEventMouseButton or event is InputEventKey:
			restart_game()

# Restart the game
func restart_game():
	# Reset game state
	game_over_flag = false
	win_flag = false
	snake = [Vector2(5, 5)]  # Initial snake position
	snake_length = 1
	current_direction = Direction.RIGHT
	next_direction = Direction.RIGHT
	spawn_food()
	label.text = ""  # Remove the text from the screen
	queue_redraw()  # Redraw the screen
	sprite.show()
