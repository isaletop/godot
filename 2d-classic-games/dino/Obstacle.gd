extends Node2D

@export var speed: float = 500.0

func _ready():
	pass

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
