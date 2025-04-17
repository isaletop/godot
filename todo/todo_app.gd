extends Node2D

@onready var input_field = $VBoxContainer/LineEdit
@onready var task_list = $VBoxContainer/ScrollContainer/ItemList

const SAVE_PATH = "res://todo_data.txt"

func _ready():
	load_data()

func _on_item_list_item_activated(index):
	task_list.remove_item(index)
	save_data()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	for i in range(task_list.item_count - 1, -1, -1):
		file.store_line(task_list.get_item_text(i))
	file.close()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var tasks = []
		
		while not file.eof_reached():
			var task = file.get_line().strip_edges()
			if task != "":
				tasks.append(task)
		file.close()
		
		for i in range(tasks.size() - 1, -1, -1):
			task_list.add_item(tasks[i])


func _on_button_pressed() -> void:
	var task = input_field.text.strip_edges()
	if task != "":
		task_list.add_item(task)
		task_list.move_item(task_list.item_count - 1, 0)
		input_field.clear()
		save_data()
