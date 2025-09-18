extends Node2D

@export var asteroid_scene: PackedScene
@export var asteroid_spawn_interval: float = 1.0 

var time_since_last_spawn: float = 0.0

func _process(delta: float) -> void:
	time_since_last_spawn += delta

	if time_since_last_spawn >= asteroid_spawn_interval:
		spawn_asteroid()
		time_since_last_spawn = 0.0

func spawn_asteroid() -> void:
	var asteroid = asteroid_scene.instantiate() as Node2D
	asteroid.position = Vector2(1152, randf_range(0, 648))
	add_child(asteroid)

func _on_spaceship_game_over():
	print("Game Over!")
	get_tree().reload_current_scene() 
