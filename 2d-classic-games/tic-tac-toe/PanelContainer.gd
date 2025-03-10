extends PanelContainer

enum Player { NONE, X, O }

var board: Array = []
var current_player: Player = Player.X
var game_over: bool = false

signal game_over_signal(winner: String)

func _ready():
	reset_board()

	for i in range($GridContainer.get_child_count()):
		var button = $GridContainer.get_child(i)
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(i))

	connect("game_over_signal", Callable(self, "_on_game_over_signal"))

	$ResetButton.connect("pressed", Callable(self, "_on_reset_button_pressed"))
	$ResetButton.hide()


func reset_board():
	board.clear()
	for i in range(3):
		board.append([Player.NONE, Player.NONE, Player.NONE]) 

	for button in $GridContainer.get_children():
		button.text = ""
		button.disabled = false

	current_player = Player.X
	game_over = false

	$Label.text = ""
	$Label.hide()
	$ResetButton.hide()


func _on_button_pressed(button_index: int):
	if game_over:
		return

	var row = button_index / 3
	var col = button_index % 3

	if board[row][col] != Player.NONE:
		return

	make_move(row, col, Player.X)

	if game_over:
		return

	current_player = Player.O
	robot_move()
	current_player = Player.X


func make_move(row: int, col: int, player: Player):
	var button_index = row * 3 + col
	var button = $GridContainer.get_child(button_index)
	button.text = "O" if player == Player.O else "X"
		
	board[row][col] = player
	button.disabled = true

	if check_winner():
		emit_signal("game_over_signal", str(player))
		game_over = true


func robot_move():
	if game_over:
		return

	var best_move = minimax(board, true, -INF, INF)
	make_move(best_move.x, best_move.y, Player.O)


func minimax(current_board, is_maximizing, alpha, beta):
	if check_winner_for_player(Player.O):
		return {"score": 1}
	elif check_winner_for_player(Player.X):
		return {"score": -1}
	elif is_draw():
		return {"score": 0}

	var best_move = {}
	if is_maximizing:
		var best_score = -INF
		for i in range(3):
			for j in range(3):
				if current_board[i][j] == Player.NONE:
					current_board[i][j] = Player.O
					var score = minimax(current_board, false, alpha, beta).score
					current_board[i][j] = Player.NONE
					
					if score > best_score:
						best_score = score
						best_move = {"x": i, "y": j, "score": best_score}
					
					alpha = max(alpha, best_score)
					if beta <= alpha:
						break
		return best_move
	else:
		var best_score = INF
		for i in range(3):
			for j in range(3):
				if current_board[i][j] == Player.NONE:
					current_board[i][j] = Player.X
					var score = minimax(current_board, true, alpha, beta).score
					current_board[i][j] = Player.NONE

					if score < best_score:
						best_score = score
						best_move = {"x": i, "y": j, "score": best_score}
					
					beta = min(beta, best_score)
					if beta <= alpha:
						break
		return best_move


func check_winner_for_player(player: Player) -> bool:
	for i in range(3):
		if board[i][0] == player and board[i][1] == player and board[i][2] == player:
			return true
		if board[0][i] == player and board[1][i] == player and board[2][i] == player:
			return true

	if board[0][0] == player and board[1][1] == player and board[2][2] == player:
		return true
	if board[0][2] == player and board[1][1] == player and board[2][0] == player:
		return true

	return false


func is_draw() -> bool:
	for row in board:
		for cell in row:
			if cell == Player.NONE:
				return false
	return true


func check_winner() -> bool:
	if check_winner_for_player(Player.X) or check_winner_for_player(Player.O):
		return true
	if is_draw():
		emit_signal("game_over_signal", "Draw")
		game_over = true
		return false
	return false


func _on_game_over_signal(winner: String):
	if winner == "Draw":
		$Label.text = "Draw!"
	else:
		$Label.text = "You win!" if winner == "X" else "AI wins!"
	
	$Label.show()
	$ResetButton.show()


func _on_reset_button_pressed():
	reset_board()
