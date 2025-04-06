extends Control

const WIDTH = 40
const HEIGHT = 20
const ROOM_MAX_SIZE = 8
const ROOM_MIN_SIZE = 4
const MAX_ROOMS = 6
const VISION_RADIUS = 4  # Радиус видимости игрока

@onready var label: Label = $AsciiLabel
var map = []
var visibility = []
var player_pos = Vector2i(0, 0)

func _ready():
	generate_map()
	update_visibility()
	render_map()

func generate_map():
	# Инициализируем карту стенами и скрываем видимость
	map = []
	visibility = []
	for y in range(HEIGHT):
		var row = []
		var vis_row = []
		for x in range(WIDTH):
			row.append("#")
			vis_row.append(false)
		map.append(row)
		visibility.append(vis_row)

	var rooms = []
	var first_room = true

	for _i in range(MAX_ROOMS):
		var w = randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		var h = randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		var x = randi_range(1, WIDTH - w - 2)
		var y = randi_range(1, HEIGHT - h - 2)

		var new_room = Rect2i(x, y, w, h)
		var overlaps = false
		for room in rooms:
			# Немного расширяем предыдущие комнаты для проверки пересечения
			if new_room.grow(1).intersects(room):
				overlaps = true
				break

		if not overlaps:
			create_room(new_room)
			if first_room:
				# Центр первой комнаты – позиция игрока
				player_pos = Vector2i(x + int(w/2), y + int(h/2))
				first_room = false
			else:
				connect_rooms(rooms[-1], new_room)
			rooms.append(new_room)

	# Ставим игрока на карте
	map[player_pos.y][player_pos.x] = "@"

func create_room(room):
	# Выкапываем пол комнаты
	for y in range(room.position.y + 1, room.end.y - 1):
		for x in range(room.position.x + 1, room.end.x - 1):
			map[y][x] = "."
	# Рисуем стены по периметру комнаты только если там ещё не создан пол
	for x in range(room.position.x, room.end.x):
		if map[room.position.y][x] != ".":  # верхняя стена
			map[room.position.y][x] = "#"
		if map[room.end.y - 1][x] != ".":
			map[room.end.y - 1][x] = "#"
	for y in range(room.position.y, room.end.y):
		if map[y][room.position.x] != ".":
			map[y][room.position.x] = "#"
		if map[y][room.end.x - 1] != ".":
			map[y][room.end.x - 1] = "#"

func connect_rooms(room1, room2):
	# Вычисляем центры комнат
	var center1 = Vector2i(room1.position.x + int(room1.size.x/2), room1.position.y + int(room1.size.y/2))
	var center2 = Vector2i(room2.position.x + int(room2.size.x/2), room2.position.y + int(room2.size.y/2))
	
	# Создаём коридор в виде буквы "Г" с единой дверью в точке соединения
	if randf() < 0.5:
		create_h_tunnel(center1.x, center2.x, center1.y)
		create_v_tunnel(center1.y, center2.y, center2.x)
		# Ставим дверь на стыке горизонтального и вертикального коридора
		place_door(Vector2i(center2.x, center1.y))
	else:
		create_v_tunnel(center1.y, center2.y, center1.x)
		create_h_tunnel(center1.x, center2.x, center2.y)
		place_door(Vector2i(center1.x, center2.y))

func create_h_tunnel(x1, x2, y):
	for x in range(min(x1, x2), max(x1, x2) + 1):
		# Коридор всегда выкапывается, даже если там стена
		map[y][x] = "."

func create_v_tunnel(y1, y2, x):
	for y in range(min(y1, y2), max(y1, y2) + 1):
		map[y][x] = "."

func place_door(pos):
	# Ставим дверь только если клетка уже вырыта (пол) и вокруг неё есть стена и пол
	if map[pos.y][pos.x] == ".":
		var count_walls = 0
		# Проверяем четыре стороны
		if map[pos.y - 1][pos.x] == "#":
			count_walls += 1
		if map[pos.y + 1][pos.x] == "#":
			count_walls += 1
		if map[pos.y][pos.x - 1] == "#":
			count_walls += 1
		if map[pos.y][pos.x + 1] == "#":
			count_walls += 1
		# Если есть хотя бы две стены (причём напротив друг друга) — ставим дверь
		if count_walls >= 2:
			map[pos.y][pos.x] = "+"

func update_visibility():
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var dist = player_pos.distance_to(Vector2i(x, y))
			if dist <= VISION_RADIUS:
				visibility[y][x] = true

func render_map():
	var output = ""
	for y in range(HEIGHT):
		for x in range(WIDTH):
			if visibility[y][x]:
				output += map[y][x]
			else:
				output += " "
		output += "\n"
	label.text = output

func _input(event):
	if event is InputEventKey and event.pressed:
		var direction = Vector2i.ZERO
		if event.keycode == KEY_W:
			direction = Vector2i(0, -1)
		elif event.keycode == KEY_S:
			direction = Vector2i(0, 1)
		elif event.keycode == KEY_A:
			direction = Vector2i(-1, 0)
		elif event.keycode == KEY_D:
			direction = Vector2i(1, 0)
		if direction != Vector2i.ZERO:
			move_player(direction)

func move_player(direction):
	var new_pos = player_pos + direction
	if new_pos.y >= 0 and new_pos.y < HEIGHT and new_pos.x >= 0 and new_pos.x < WIDTH:
		if map[new_pos.y][new_pos.x] == "." or map[new_pos.y][new_pos.x] == "+":
			map[player_pos.y][player_pos.x] = "."
			player_pos = new_pos
			map[player_pos.y][player_pos.x] = "@"
			update_visibility()
			render_map()
