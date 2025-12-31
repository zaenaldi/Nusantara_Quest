extends Node2D

# Node references
@onready var puzzle_container = $UI/PuzzleContainer
@onready var header = $UI/Header
@onready var moves_label = $UI/MovesLabel
@onready var result_container = $UI/ResultContainer
@onready var result_label = $UI/ResultContainer/ResultLabel
@onready var next_island_btn = $UI/NextIslandBtn
@onready var restart_btn = $UI/RestartBtn

# Puzzle variables
var grid_size = 3
var tile_size = 100
var tiles = []
var tile_positions = []
var current_moves = 0
var level_completed = false

# Timer variables
var timer_value = 300
var timer_running = false

# Wayang data
var wayang_data = {
	"arjuna": {
		"image": "res://assets/images/puzzles/wayang_arjuna.jpg",
		"name": "Wayang Arjuna",
		"description": "Arjuna adalah tokoh wayang terkenal dari Mahabharata, dikenal sebagai ksatria pemberani, bijaksana, dan sakti.",
		"fact": "Wayang Arjuna melambangkan kesempurnaan lahir batin."
	}
}

var current_puzzle
var wayang_texture
var selected_tile = null
var progress_saved = false
var is_returning_to_map = false  # 🆕 VARIABLE BARU: Mencegah multiple returns

func _ready():
	print("🎭 Pulau Jawa Level 2 - Wayang Slide Puzzle Loaded")
	
	# 🎯 PERBAIKAN: Gunakan metode konsisten
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_island_progress"):
		var progress = main.get_island_progress("jawa")
		if progress and progress.get("level2_completed", false):
			print("🔄 Level 2 sudah selesai, menunjukkan completion screen...")
			call_deferred("show_already_completed_screen")
			return
	else:
		# Fallback untuk metode lama
		if main and main.has_method("get_player_data"):
			var player_data = main.get_player_data()
			if player_data:
				var level_key = "jawa_2"
				if player_data.has("completed_levels") and level_key in player_data["completed_levels"]:
					print("🔄 Level 2 Jawa sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return
	
	initialize_puzzle()

func initialize_puzzle():
	current_puzzle = wayang_data["arjuna"]
	wayang_texture = load(current_puzzle["image"])
	
	if header:
		header.text = "PULAU JAWA - LEVEL 2\n Susun Gambar Wayang Arjuna"
	
	create_puzzle_grid()
	shuffle_tiles()
	
	timer_value = 300
	timer_running = true
	update_moves_display()
	
	# 🆕 RESET FLAG RETURN
	is_returning_to_map = false

func create_puzzle_grid():
	# Clear existing tiles
	for tile in tiles:
		if tile and is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()
	tile_positions.clear()
	
	# Setup container
	puzzle_container.custom_minimum_size = Vector2(grid_size * tile_size, grid_size * tile_size)
	puzzle_container.size = Vector2(grid_size * tile_size, grid_size * tile_size)
	
	# Initialize tiles array
	tiles.resize(grid_size * grid_size)
	tile_positions.resize(grid_size * grid_size)
	
	var tex_width = wayang_texture.get_width()
	var tex_height = wayang_texture.get_height()
	
	for y in range(grid_size):
		for x in range(grid_size):
			var index = x + y * grid_size
			
			var tile = TextureRect.new()
			tile.name = "Tile_%d_%d" % [x, y]
			tile.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			
			# Create AtlasTexture
			var region_width = tex_width / grid_size
			var region_height = tex_height / grid_size
			var region_rect = Rect2(
				x * region_width,
				y * region_height,
				region_width,
				region_height
			)
			
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = wayang_texture
			atlas_texture.region = region_rect
			tile.texture = atlas_texture
			
			tile.custom_minimum_size = Vector2(tile_size, tile_size)
			tile.size = Vector2(tile_size, tile_size)
			tile.position = Vector2(x * tile_size, y * tile_size)
			
			# Store correct position for this tile
			tile_positions[index] = Vector2(x, y)
			
			# Enable input
			tile.mouse_filter = Control.MOUSE_FILTER_PASS
			tile.gui_input.connect(_on_tile_input.bind(tile))
			
			# Add visual style
			var style = StyleBoxFlat.new()
			style.bg_color = Color(1, 1, 1, 0.9)
			style.border_color = Color.WHITE
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			tile.add_theme_stylebox_override("panel", style)
			
			puzzle_container.add_child(tile)
			tiles[index] = tile

func shuffle_tiles():
	# Fisher-Yates shuffle algorithm
	for i in range(tiles.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		swap_tiles_by_index(i, j)
	
	current_moves = 0
	update_moves_display()
	reset_selection()

func _on_tile_input(event, tile):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not level_completed and timer_running:
			handle_tile_click(tile)

func handle_tile_click(tile):
	if selected_tile == null:
		# First tile selection
		select_tile(tile)
	else:
		if selected_tile == tile:
			# Clicking the same tile - deselect
			deselect_tile(tile)
		else:
			# Second tile selection - swap them
			swap_selected_tiles(selected_tile, tile)
			current_moves += 1
			update_moves_display()
			
			# Check if puzzle is solved
			if check_puzzle_solved():
				handle_puzzle_solved()
			else:
				reset_selection()

func select_tile(tile):
	selected_tile = tile
	# Visual feedback for selected tile
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.border_color = Color.YELLOW
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	tile.add_theme_stylebox_override("panel", style)
	
	print("Tile selected: ", get_tile_index(tile))

func deselect_tile(tile):
	reset_tile_appearance(tile)
	selected_tile = null

func reset_selection():
	if selected_tile:
		reset_tile_appearance(selected_tile)
		selected_tile = null

func swap_selected_tiles(tile1, tile2):
	var index1 = get_tile_index(tile1)
	var index2 = get_tile_index(tile2)
	
	if index1 >= 0 and index2 >= 0:
		swap_tiles_by_index(index1, index2)
		flash_tile(tile1, Color.GREEN)
		flash_tile(tile2, Color.GREEN)
		print("Swapped tiles: ", index1, " and ", index2)

func get_tile_index(tile):
	return tiles.find(tile)

func reset_tile_appearance(tile):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.9)
	style.border_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	tile.add_theme_stylebox_override("panel", style)

func flash_tile(tile, color: Color):
	var original_style = tile.get_theme_stylebox("panel").duplicate()
	
	var flash_style = StyleBoxFlat.new()
	flash_style.bg_color = color
	flash_style.border_color = Color.WHITE
	flash_style.border_width_left = 2
	flash_style.border_width_top = 2
	flash_style.border_width_right = 2
	flash_style.border_width_bottom = 2
	tile.add_theme_stylebox_override("panel", flash_style)
	
	await get_tree().create_timer(0.3).timeout
	tile.add_theme_stylebox_override("panel", original_style)

func swap_tiles_by_index(index1: int, index2: int):
	if index1 < 0 or index2 < 0 or index1 >= tiles.size() or index2 >= tiles.size():
		return
	
	# Swap in arrays
	var temp_tile = tiles[index1]
	tiles[index1] = tiles[index2]
	tiles[index2] = temp_tile
	
	var temp_pos = tile_positions[index1]
	tile_positions[index1] = tile_positions[index2]
	tile_positions[index2] = temp_pos
	
	# Update visual positions
	var pos1 = Vector2((index1 % grid_size) * tile_size, (index1 / grid_size) * tile_size)
	var pos2 = Vector2((index2 % grid_size) * tile_size, (index2 / grid_size) * tile_size)
	
	tiles[index1].position = pos1
	tiles[index2].position = pos2

func check_puzzle_solved() -> bool:
	# Check if all tiles are in their correct positions
	for i in range(tiles.size()):
		var _current_tile = tiles[i]
		var current_position = tile_positions[i]
		
		# The correct position for tile at index i should be:
		# x = i % grid_size, y = i / grid_size
		var correct_x = i % grid_size
		var correct_y = i / grid_size
		
		var should_be_position = Vector2(correct_x, correct_y)
		
		# If the stored position doesn't match where it should be, puzzle is not solved
		if current_position != should_be_position:
			return false
	
	print("🎉 PUZZLE SOLVED! All tiles in correct positions")
	return true

func handle_puzzle_solved():
	print("🎉 Puzzle solved in ", current_moves, " moves!")
	timer_running = false
	level_completed = true
	
	# Visual celebration
	for tile in tiles:
		celebrate_tile(tile)
	
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	# Save progress
	save_progress(stars, knowledge_points)
	
	# Show result after short delay
	await get_tree().create_timer(1.0).timeout
	show_result_screen(stars, knowledge_points)

func celebrate_tile(tile):
	# Create celebration tween
	var tween = create_tween()
	tween.tween_property(tile, "modulate", Color.GOLD, 0.3)
	tween.tween_property(tile, "modulate", Color.WHITE, 0.3)
	tween.set_loops(3)

func _process(delta):
	if timer_running and not level_completed:
		timer_value -= delta
		update_moves_display()
		
		if timer_value <= 0:
			timer_running = false
			handle_timeout()

func update_moves_display():
	if moves_label:
		var minutes = int(timer_value) / 60
		var seconds = int(timer_value) % 60
		moves_label.text = "Langkah: %d | Waktu: %02d:%02d" % [current_moves, minutes, seconds]

func calculate_stars() -> int:
	var time_ratio = timer_value / 300.0
	var move_penalty = float(current_moves) / 50.0
	
	if time_ratio > 0.7 and move_penalty < 0.3: return 3
	if time_ratio > 0.4 and move_penalty < 0.6: return 2
	return 1

func calculate_knowledge_points() -> int:
	var base_points = 60
	var time_bonus = int((timer_value / 300.0) * 40)
	var move_penalty = int(current_moves * 0.5)
	return base_points + time_bonus - move_penalty

func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving Jawa Level 2 progress...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		print("✅ Using Main.complete_level()")
		var success = main.complete_level("jawa", 2, stars, knowledge_points)
		if success:
			progress_saved = true
			print("✅ Progress saved successfully via Main system!")
		else:
			print("⚠️ Main system save failed, using manual save...")
			manual_save_progress(stars, knowledge_points)
	else:
		print("❌ Main.complete_level() not available")
		manual_save_progress(stars, knowledge_points)

func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Manual save for Jawa Level 2...")
	
	var save_path = "user://game_save.dat"
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	var saved_data = {}
	if file:
		saved_data = file.get_var()
		file.close()
	
	# Initialize data structure
	if not saved_data:
		saved_data = {}
	if not saved_data.has("completed_levels"):
		saved_data["completed_levels"] = {}
	if not saved_data.has("unlocked_islands"):
		saved_data["unlocked_islands"] = ["sumatra", "jawa"]
	if not saved_data.has("completed_islands"):
		saved_data["completed_islands"] = []
	
	# Mark level 2 as completed
	saved_data["completed_levels"]["jawa_2"] = true
	
	# Update stars
	if saved_data.has("total_stars"):
		saved_data["total_stars"] += stars
	else:
		saved_data["total_stars"] = stars
	
	# Update knowledge points
	if saved_data.has("knowledge_points"):
		saved_data["knowledge_points"] += knowledge_points
	else:
		saved_data["knowledge_points"] = knowledge_points
	
	# Check if entire island is completed
	var level1_completed = saved_data["completed_levels"].get("jawa_1", false)
	if level1_completed and "jawa" not in saved_data["completed_islands"]:
		saved_data["completed_islands"].append("jawa")
		print("✅ Pulau Jawa marked as completed")
	
	# Unlock next island if Jawa is completed
	if "jawa" in saved_data["completed_islands"] and "kalimantan" not in saved_data["unlocked_islands"]:
		saved_data["unlocked_islands"].append("kalimantan")
		print("🔓 Pulau Kalimantan unlocked!")
	
	# Save back
	file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(saved_data)
		file.close()
		progress_saved = true
		print("✅ Manual save successful!")
	else:
		print("❌ Manual save failed - cannot write file")
		progress_saved = false

func show_result_screen(stars, points):
	result_container.visible = true
	
	var result_text = "🎉 SELAMAT! 🎉\n"
	result_text += "Kamu berhasil menyusun gambar %s!\n\n" % current_puzzle["name"]
	result_text += "📊 Hasil:\n"
	result_text += "   • Langkah: %d\n" % current_moves
	result_text += "   • Waktu: %02d:%02d\n" % [int(timer_value) / 60, int(timer_value) % 60]
	result_text += "   • ⭐ Bintang: %d/3\n" % stars
	result_text += "   • 📚 Poin: +%d\n\n" % points
	result_text += "💡 Fakta: %s\n\n" % current_puzzle["fact"]
	
	result_text += "🔓 KUNCI DIPEROLEH!\n"
	result_text += "Pulau Kalimantan sekarang terbuka!\n"
	
	result_label.text = result_text
	
	next_island_btn.text = "Kembali ke Peta"
	next_island_btn.show()
	restart_btn.show()

func handle_timeout():
	result_label.text = "⏰ WAKTU HABIS!\nCoba lagi!"
	result_container.visible = true
	restart_btn.show()
	reset_selection()

func _on_restart_btn_pressed():
	print("🔄 Restarting puzzle...")
	current_moves = 0
	level_completed = false
	timer_value = 300
	timer_running = true
	result_container.visible = false
	restart_btn.hide()
	next_island_btn.hide()
	progress_saved = false
	is_returning_to_map = false  # 🆕 RESET FLAG
	initialize_puzzle()

func _on_next_island_btn_pressed():
	# 🆕 PERBAIKAN KRITIS: CEGAH MULTIPLE CALLS
	if is_returning_to_map:
		print("⚠️ Already returning to map, ignoring duplicate call")
		return
	
	is_returning_to_map = true
	print("🗺️ Returning to Map from Jawa Level 2...")
	print("🔍 Progress saved:", progress_saved)
	print("🔍 Level completed:", level_completed)
	
	# 🆕 NONAKTIFKAN TOMBOL SELAMA TRANSISI
	next_island_btn.disabled = true
	restart_btn.disabled = true
	
	# 🆕 TUNGGU SEBENTAR SEBELUM PINDAH SCENE
	await get_tree().create_timer(0.1).timeout
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("show_map"):
		print("✅ Using Main.show_map()")
		# 🆕 TUNGGU FRAME BERIKUTNYA UNTUK MEMASTIKAN SEMUA PROSES SELESAI
		await get_tree().process_frame
		main.show_map()
	else:
		print("❌ Main.show_map() not available, using fallback")
		# Fallback dengan delay untuk mencegah race condition
		await get_tree().create_timer(0.2).timeout
		get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func show_already_completed_screen():
	print("🔄 Showing already completed screen for Jawa Level 2")
	
	var main = get_node_or_null("/root/Main")
	var stars = 0
	var knowledge_points = 0
	var unlocked_islands = []
	
	# Ambil data dari Main system
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			stars = player_data.get("total_stars", 0)
			knowledge_points = player_data.get("knowledge_points", 0)
			unlocked_islands = player_data.get("unlocked_islands", [])
	
	# Setup tampilan
	header.text = "PULAU JAWA - LEVEL 2\nSUDAH SELESAI! 🎉"
	
	# Nonaktifkan gameplay
	puzzle_container.visible = false
	moves_label.visible = false
	restart_btn.visible = false
	
	# Show completion info
	result_container.visible = true
	var result_text = "Kamu sudah menyelesaikan level ini!\n\n"
	result_text += "📊 Progress Saat Ini:\n"
	result_text += "   • ⭐ Total Bintang: " + str(stars) + "\n"
	result_text += "   • 📚 Total Poin: " + str(knowledge_points) + "\n\n"
	
	if "kalimantan" in unlocked_islands:
		result_text += "🔓 Pulau Kalimantan sudah terbuka!\n"
		result_text += "Kunjungi Pulau Kalimantan untuk petualangan berikutnya!\n"
	else:
		result_text += "🔒 Selesaikan level untuk membuka pulau berikutnya!\n"
	
	result_text += "\nTekan tombol untuk kembali ke peta"
	
	result_label.text = result_text
	next_island_btn.text = "Kembali ke Peta"
	next_island_btn.show()
	
	level_completed = true
	progress_saved = true

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("🔙 ESC pressed - returning to map")
			# 🆕 CALL FUNCTION YANG SAMA DENGAN TOMBOL
			_on_next_island_btn_pressed()
		elif event.keycode == KEY_ENTER and level_completed and next_island_btn.visible:
			print("🔑 ENTER pressed - continuing")
			_on_next_island_btn_pressed()

func _exit_tree():
	print("🎭 Jawa Level 2 exiting...")
	print("📊 Final State:")
	print("   Level completed:", level_completed)
	print("   Moves:", current_moves)
	print("   Time remaining:", timer_value)
	print("   Progress saved:", progress_saved)
	print("   Is returning to map:", is_returning_to_map)
