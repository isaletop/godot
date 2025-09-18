extends Node2D

@export var obstacle_scene: PackedScene
var score: int = 0
var score_timer: float = 0.0
var score_interval: float = 1.0
var obstacles: Array = []
var is_game_over: bool = false

@onready var player: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var sprite1: Sprite2D = $Ground/Ground1
@onready var sprite2: Sprite2D = $Ground/Ground2

@export var speed: float = 500.0
const SPRITE_WIDTH: float = 2400.0

func _ready() -> void:
	$GameOver.hide()
	$Restart.hide()

func _process(delta: float):
	# Move ground sprites to the left
	sprite1.position.x -= speed * delta
	sprite2.position.x -= speed * delta

	# If sprite1 moves off the left edge, reposition it behind sprite2
	if sprite1.position.x <= -SPRITE_WIDTH:
		sprite1.position.x = sprite2.position.x + SPRITE_WIDTH
	# If sprite2 moves off the left edge, reposition it behind sprite1
	elif sprite2.position.x <= -SPRITE_WIDTH:
		sprite2.position.x = sprite1.position.x + SPRITE_WIDTH

func _physics_process(delta: float) -> void:
	if not is_game_over:
		update_score(delta)
		_check_obstacles_out_of_screen()
		if obstacles.size() == 0:
			_spawn_obstacle()

func update_score(delta: float) -> void:
	score_timer += delta
	if score_timer >= score_interval:
		score += 1
		$ScoreLabel.text = "Score: %d" % score
		score_timer = 0.0

func _spawn_obstacle() -> void:
	var obstacle = obstacle_scene.instantiate()
	obstacle.add_to_group("obstacle")
	obstacle.position = Vector2(1152, 388) 
	add_child(obstacle)
	obstacles.append(obstacle)

func _check_obstacles_out_of_screen() -> void:
	for obstacle in obstacles:
		if obstacle.position.x < 0:
			obstacles.erase(obstacle)
			obstacle.queue_free()

func _on_area_2d_body_entered(body):
	print("Collision detected with:", body.name)
	if body.is_in_group("obstacle") or body.get_parent().is_in_group("obstacle"):
		game_over()

func game_over() -> void:
	is_game_over = true
	$GameOver.show()
	$Restart.show()
	player.play("death")
	get_tree().paused = true

func _on_button_pressed() -> void:
	# Reset game state
	score = 0
	score_timer = 0.0
	$ScoreLabel.text = "Score: 0"
	$GameOver.hide()
	$Restart.hide()
	player.play("idle_and_jump")
	for obstacle in obstacles:
		obstacle.queue_free()
	obstacles.clear()
	is_game_over = false
	get_tree().paused = false
