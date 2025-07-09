extends Node3D

const MAX_HISTORY := 10
const BOX_SIZE := Vector3(0.2, 0.1, 0.2)
const HISTORY_SPACING := 0.3
const MIN_HEIGHT := 0.1
const INITIAL_ALPHA := 0.2

@onready var indicator = $Indicator
@onready var price_label = $PriceLabel
@onready var timer = $Timer
@onready var columns_container = $History
@onready var debug_panel = $CanvasLayer/DebugPanel
@onready var fetching_label = $CanvasLayer2/FetchingLabel

var columns_data: Array[MeshInstance3D] = []
var price_data: Array[float] = []
var current_price := 100000.0
var max_price := current_price
var min_price := current_price
var materials := {}

func _ready():
	init_materials()
	init_columns()
	init_debug_panel()
	fetch_price()

func init_materials():
	materials.green = StandardMaterial3D.new()
	materials.green.albedo_color = Color(0.0, 1.0, 0.0)
	materials.red = StandardMaterial3D.new()
	materials.red.albedo_color = Color(1.0, 0.0, 0.0)
	materials.gray = StandardMaterial3D.new()
	materials.gray.albedo_color = Color(0.5, 0.5, 0.5)
	materials.gray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func init_columns():
	for i in MAX_HISTORY:
		var indicator_box = MeshInstance3D.new()
		indicator_box.mesh = BoxMesh.new()
		indicator_box.scale = Vector3(BOX_SIZE.x, BOX_SIZE.y, BOX_SIZE.z)
		indicator_box.material_override = materials.gray.duplicate()
		indicator_box.material_override.albedo_color.a = INITIAL_ALPHA
		indicator_box.position.x = -float(i) * HISTORY_SPACING
		indicator_box.transform.origin.y = BOX_SIZE.y / 2
		columns_container.add_child(indicator_box)
		columns_data.append(indicator_box)

func init_debug_panel():
	for i in MAX_HISTORY:
		var label = Label.new()
		debug_panel.add_child(label)

func fetch_price():
	fetching_label.text = "Simulating..."
	var random_change = randf_range(-0.01, 0.01)
	var new_price = current_price * (1.0 + random_change)
	update_price(new_price)

func update_price(new_price: float):
	price_label.text = "BTC $%.0f" % new_price
	fetching_label.text = ""

	indicator.material_override = materials.green if new_price > current_price else materials.red

	price_data.append(new_price)
	if price_data.size() > MAX_HISTORY:
		price_data.pop_front()

	max_price = max(max_price, new_price)
	min_price = min(min_price, new_price)
	
	update_debug_panel()
	update_history_indicators()

func update_debug_panel():
	var labels = debug_panel.get_children()
	var price_data_size = price_data.size()
	
	for i in price_data_size:
		var label = labels[i]
		var prev_price
		
		if i > 0:
			prev_price = price_data[i-1]
		else:
			prev_price = current_price

		var price = price_data[i]

		var change = (price - prev_price) / prev_price * 100

		var arrow = "↑" if change > 0 else "↓" if change < 0 else ""
		var color = Color.GREEN if change > 0 else Color.RED if change < 0 else null

		label.text = "%.0f %s (%.2f%%)" % [price, arrow, abs(change)]
		if color:
			label.add_theme_color_override("font_color", color)
		else:
			label.remove_theme_color_override("font_color")

func update_history_indicators():
	var material = materials.gray
	var price_data_size = price_data.size()
	
	for i in price_data_size:
		var prev_price

		if i > 0:
			prev_price = price_data[i-1]
		else:
			prev_price = current_price

		var price = price_data[i]

		var change = (price - current_price) / prev_price * 100
		
		var height = price_to_height(price)

		var indicator_box = columns_data[MAX_HISTORY-i-1]
		indicator_box.scale = Vector3(BOX_SIZE.x, height, BOX_SIZE.z)
		indicator_box.transform.origin.y = height / 2

		indicator_box.material_override = materials.green if price > prev_price else materials.red

func price_to_height(price: float) -> float:
	if max_price == min_price:
		return MIN_HEIGHT
	var relative_height = (price - min_price) / (max_price - min_price)
	return MIN_HEIGHT + relative_height * 1.2

func _on_timer_timeout():
	fetch_price()
