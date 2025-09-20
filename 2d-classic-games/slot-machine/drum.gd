extends Control

@export var symbols: Array[String] = ["🍎", "🍋", "🍇"]  # Массив символов
@export var speed: float = 0.1  # Скорость обновления
var spinning: bool = false  # Статус вращения
var current_symbol_index: int = 0  # Индекс текущего символа (будет обновляться для каждого барабана)

# Инициализация барабанов
@onready var drum1 = $Panel/Drum1
@onready var drum2 = $Panel/Drum2
@onready var drum3 = $Panel/Drum3

func _ready():
	# Изначально обновляем символы на барабанах
	_update_symbols()

func start_spin():
	spinning = true

func stop_spin():
	spinning = false
	_update_symbols()  # Обновляем символы после остановки вращения

func _process(delta):
	if spinning:
		_rotate_symbols(delta)

# Метод для вращения символов
func _rotate_symbols(delta):
	# Индекс для каждого барабана
	_update_drum_symbols(drum1)
	_update_drum_symbols(drum2)
	_update_drum_symbols(drum3)

# Метод обновления символов для каждого барабана
func _update_symbols():
	# Обновляем символы на каждом барабане
	_update_drum_symbols(drum1)
	_update_drum_symbols(drum2)
	_update_drum_symbols(drum3)

# Метод для обновления символов на конкретном барабане
func _update_drum_symbols(drum):
	# Если барабан существует, обновляем его
	if drum:
		var drum_symbol_index = randi() % symbols.size()  # Рандомный индекс для барабана
		for i in range(drum.get_child_count()):
			var label = drum.get_child(i)
			if label is Label:
				# Индекс для символа зависит от позиции метки на барабане
				var symbol_index = (drum_symbol_index + i) % symbols.size()
				label.text = symbols[symbol_index]
