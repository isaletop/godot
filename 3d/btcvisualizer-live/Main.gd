extends Node3D

const MAX_HISTORY := 10
const BOX_SIZE := Vector3(0.2, 0.1, 0.2)
const HISTORY_SPACING := 0.3
const MIN_HEIGHT := 0.1
const INITIAL_ALPHA := 0.2
const API_URL_INITIAL := "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=1"
const API_URL_UPDATE := "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin&order=market_cap_desc&per_page=1"
const FETCH_INTERVAL := 60.0 # Seconds between API calls to avoid fetch limits

@onready var indicator = $Indicator
@onready var price_label = $PriceLabel
@onready var timer = $Timer
@onready var columns_container = $History
@onready var debug_panel = $CanvasLayer/DebugPanel
@onready var fetching_label = $CanvasLayer2/FetchingLabel
@onready var http_request = HTTPRequest.new()

var columns_data: Array[MeshInstance3D] = []
var price_data: Array[float] = []
var current_price := 0.0
var max_price := 0.0
var min_price := 0.0
var materials := {}
var is_initial_fetch := true

func _ready() -> void:
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	timer.wait_time = FETCH_INTERVAL
	#timer.timeout.connect(_on_timer_timeout)
	
	init_materials()
	init_columns()
	init_debug_panel()
	fetch_price()

func init_materials() -> void:
	materials.green = StandardMaterial3D.new()
	materials.green.albedo_color = Color(0.0, 1.0, 0.0)
	
	materials.red = StandardMaterial3D.new()
	materials.red.albedo_color = Color(1.0, 0.0, 0.0)
	
	materials.gray = StandardMaterial3D.new()
	materials.gray.albedo_color = Color(0.5, 0.5, 0.5, INITIAL_ALPHA)
	materials.gray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func init_columns() -> void:
	for i in MAX_HISTORY:
		var indicator_box = MeshInstance3D.new()
		indicator_box.mesh = BoxMesh.new()
		indicator_box.scale = BOX_SIZE
		indicator_box.material_override = materials.gray.duplicate()
		indicator_box.position = Vector3(-float(i) * HISTORY_SPACING, BOX_SIZE.y / 2, 0)
		columns_container.add_child(indicator_box)
		columns_data.append(indicator_box)

func init_debug_panel() -> void:
	for i in MAX_HISTORY:
		var label = Label.new()
		label.text = "-"
		debug_panel.add_child(label)

func fetch_price() -> void:
	fetching_label.text = "Fetching..."
	var url = API_URL_INITIAL if is_initial_fetch else API_URL_UPDATE
	var error = http_request.request(url)
	if error != OK:
		fetching_label.text = "Error initiating request: " + str(error)
		timer.start(FETCH_INTERVAL / 2) # Retry sooner on error

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		fetching_label.text = "API Error: " + str(response_code)
		timer.start(FETCH_INTERVAL / 2)
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		fetching_label.text = "Invalid API response"
		timer.start(FETCH_INTERVAL / 2)
		return
	
	if is_initial_fetch:
		if json.has("prices") and json.prices is Array:
			price_data.clear()
			var prices = json.prices
			# Take the last 10 hourly prices (or fewer if not enough data)
			var start_idx = max(0, prices.size() - MAX_HISTORY)
			for i in range(start_idx, prices.size()):
				var price = prices[i][1] # prices[i] = [timestamp, price]
				if price is float or price is int:
					price_data.append(float(price))
			if not price_data.is_empty():
				current_price = price_data[-1]
				max_price = price_data.max()
				min_price = price_data.min()
				is_initial_fetch = false
				update_price(current_price)
			else:
				fetching_label.text = "No valid price data"
				timer.start(FETCH_INTERVAL / 2)
		else:
			fetching_label.text = "Invalid price data format"
			timer.start(FETCH_INTERVAL / 2)
	else:
		if json is Array and json.size() > 0 and json[0].has("current_price"):
			var new_price = json[0].current_price
			if new_price is float or new_price is int:
				update_price(float(new_price))
			else:
				fetching_label.text = "Invalid price data"
				timer.start(FETCH_INTERVAL / 2)
		else:
			fetching_label.text = "Invalid API response"
			timer.start(FETCH_INTERVAL / 2)
	
	timer.start(FETCH_INTERVAL)

func update_price(new_price: float) -> void:
	if price_data.is_empty():
		current_price = new_price
		max_price = new_price
		min_price = new_price
	else:
		price_data.append(new_price)
		if price_data.size() > MAX_HISTORY:
			price_data.pop_front()
	
	price_label.text = "BTC $%.2f" % new_price
	fetching_label.text = ""
	
	indicator.material_override = materials.green if new_price > current_price else materials.red
	
	max_price = price_data.max()
	min_price = price_data.min()
	current_price = new_price
	
	update_debug_panel()
	update_history_indicators()

func update_debug_panel() -> void:
	var labels = debug_panel.get_children()
	for i in price_data.size():
		var price = price_data[i]
		var prev_price = price_data[i-1] if i > 0 else (price_data[0] if price_data.size() > 0 else current_price)
		var change = (price - prev_price) / prev_price * 100 if prev_price != 0 else 0.0
		
		var arrow = "↑" if change > 0 else "↓" if change < 0 else ""
		var color = Color.GREEN if change > 0 else Color.RED if change < 0 else Color.WHITE
		
		labels[i].text = "$%.2f %s (%.2f%%)" % [price, arrow, abs(change)]
		labels[i].add_theme_color_override("font_color", color)

func update_history_indicators() -> void:
	for i in price_data.size():
		var price = price_data[i]
		var prev_price = price_data[i-1] if i > 0 else (price_data[0] if price_data.size() > 0 else current_price)
		
		var height = price_to_height(price)
		var indicator_box = columns_data[MAX_HISTORY-i-1]
		
		indicator_box.scale = Vector3(BOX_SIZE.x, height, BOX_SIZE.z)
		indicator_box.position.y = height / 2
		indicator_box.material_override = materials.green if price > prev_price else materials.red

func price_to_height(price: float) -> float:
	if max_price == min_price:
		return MIN_HEIGHT
	var relative_height = (price - min_price) / (max_price - min_price)
	return lerp(MIN_HEIGHT, MIN_HEIGHT + 1.2, relative_height)

func _on_timer_timeout() -> void:
	fetch_price()
