extends Node2D

@export var symbols: Array[String] = ["🍎", "🍋", "🍇"]
@export var speed: float = 0.1
var spinning: bool = false

# Initialize drums
@onready var drum1 = $Panel/Drum1
@onready var drum2 = $Panel/Drum2
@onready var drum3 = $Panel/Drum3

# Button to start spinning
@onready var spin_button = $SpinButton
@onready var result = $ResultLabel

# Time the drums will spin
var rotation_time: float = 1.0  # For example, 2 seconds for spinning
var time_left: float = 0.0  # Remaining time for spinning

func _ready():
	# Initially update symbols on drums
	_update_symbols()

	# Connect button signal
	spin_button.pressed.connect(_on_spin_pressed)

# Method to handle button press
func _on_spin_pressed():
	start_spin()

# Method to start spinning
func start_spin():
	spinning = true
	time_left = rotation_time  # Set spinning time

# Method to stop spinning
func stop_spin():
	spinning = false
	_update_symbols()  # Update symbols after stopping
	_check_result()  # Check the result

# Process updates
func _process(delta):
	if spinning:
		_rotate_symbols(delta)
		time_left -= delta  # Decrease remaining time
		if time_left <= 0:
			stop_spin()  # Stop spinning when time runs out

# Method to rotate symbols
func _rotate_symbols(delta):
	# Index for each drum
	_update_drum_symbols(drum1)
	_update_drum_symbols(drum2)
	_update_drum_symbols(drum3)

# Method to update symbols for each drum
func _update_symbols():
	# Update symbols on each drum
	_update_drum_symbols(drum1)
	_update_drum_symbols(drum2)
	_update_drum_symbols(drum3)

# Method to update symbols on a specific drum
func _update_drum_symbols(drum):
	# If drum exists, update it
	if drum:
		var drum_symbol_index = randi() % symbols.size()  # Random index for drum
		for i in range(drum.get_child_count()):
			var label = drum.get_child(i)
			if label is Label:
				# Symbol index depends on label position on drum
				var symbol_index = (drum_symbol_index + i) % symbols.size()
				label.text = symbols[symbol_index]

# Check result
func _check_result():
	var result1 = drum1.get_child(1).text  # Center symbol of first drum
	var result2 = drum2.get_child(1).text  # Center symbol of second drum
	var result3 = drum3.get_child(1).text  # Center symbol of third drum

	if result1 == result2 and result2 == result3:
		result.text = "Win 🎉"
	else:
		result.text = "Lose"
