extends CharacterBody3D

@export var idle_animation: String = "fighting_idle"
@export var punch_animation: String = "punch"
@export var hit_animation: String = "hit_to_head"
@export var punch_speed: float = 2.0

var debug_draw: bool = true
var player2: CharacterBody3D
var debug_mesh: MeshInstance3D

var animation_player: AnimationPlayer

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready():
	animation_player = $"Y Bot/AnimationPlayer"
	play_idle()
	animation_player.animation_finished.connect(_on_animation_finished)

	player2 = $"../Player2"

	debug_mesh = MeshInstance3D.new()
	debug_mesh.mesh = ImmediateMesh.new()
	add_child(debug_mesh)
	
func play_idle():
	if animation_player.has_animation(idle_animation):
		animation_player.set_speed_scale(1.0)
		animation_player.play(idle_animation)

func _on_animation_finished(anim_name: String):
	if anim_name == punch_animation:
		play_idle()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_button_pressed() -> void:
	if animation_player.has_animation(punch_animation):
		animation_player.set_speed_scale(punch_speed)
		animation_player.play(punch_animation)
		check_collision()

func check_collision():
	var space_state = get_world_3d().direct_space_state

	var hand_position = $PunchOrigin.global_transform.origin
	var target_position = hand_position + transform.basis.z * 1.0

	var query = PhysicsRayQueryParameters3D.new()
	query.from = hand_position
	query.to = target_position

	if debug_draw:
		draw_ray(query.from, query.to)

	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		print("Ray hit something:", collider)

		if collider is CharacterBody3D and collider != self:
			print("Hit a CharacterBody3D:", collider)

			var anim_player = collider.get_node_or_null("Y Bot/AnimationPlayer")
			if anim_player:
				print("Found animation player on the hit character.")
				if anim_player.has_animation(hit_animation):
					await get_tree().create_timer(0.45).timeout
					print("Playing hit animation.")
					anim_player.play(hit_animation)

func draw_ray(from_position: Vector3, to_position: Vector3):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)

	st.set_color(Color(1, 0, 0))
	st.add_vertex(from_position)
	st.add_vertex(to_position)

	var mesh = st.commit()
	debug_mesh.mesh = mesh
		
func get_target_position() -> Vector3:
	if player2:
		return player2.global_transform.origin
	else:
		return global_transform.origin 
