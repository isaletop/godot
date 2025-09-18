extends CharacterBody2D

@export var jump_force: float = -600.0
@export var gravity: float = 1500.0
var animated_sprite: AnimatedSprite2D

func _ready() -> void:
	animated_sprite = $AnimatedSprite2D  # Get reference to AnimatedSprite2D
	animated_sprite.play("idle_and_jump")  # Start with idle/jump animation

func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y += gravity * delta

	# If the dinosaur is on the ground and the jump action is pressed
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force  # Jump upward
		animated_sprite.play("idle_and_jump")  # Play jump animation

	# If the down action is pressed and the dinosaur is on the ground
	if Input.is_action_pressed("ui_down") and is_on_floor():
		animated_sprite.play("sit")  # Play sit animation

	# If the dinosaur is in the air and not playing the jump animation
	elif not is_on_floor() and animated_sprite.animation != "idle_and_jump":
		animated_sprite.play("idle_and_jump")  # Ensure jump animation plays while in air

	# If the dinosaur is on the ground and not playing the run animation
	elif is_on_floor() and animated_sprite.animation != "run":
		animated_sprite.play("run")  # Play run animation when on the ground

	# Update position with velocity
	move_and_slide()
