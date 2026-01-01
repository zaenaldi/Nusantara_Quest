extends Node

var player_data = {
	"player_name": "Penjelajah",
	"energy": 100,
	"knowledge_points": 0,
	"total_stars": 0,
	"rank": "Pemula",
	"completed_islands": [],
	"unlocked_islands": ["sumatra"],
	"daily_fact_seen": false,
	"last_play_date": "",
	"current_island": ""
}

var island_progress = {
	"sumatra": {
		"name": "Pulau Sumatera",
		"theme": "Fauna dan Tari",
		"completed": false,
		"stars_earned": 0,
		"level1_completed": false,
		"level2_completed": false,
		"description": "Pulau dengan harimau sumatera dan tarian tradisional"
	},
	"jawa": {
		"name": "Pulau Jawa", 
		"theme": "Sejarah dan Peninggalan",
		"completed": false,
		"stars_earned": 0,
		"level1_completed": false,
		"level2_completed": false,
		"description": "Pusat kerajaan-kerajaan besar Nusantara"
	},
	"kalimantan": {
		"name": "Pulau Kalimantan",
		"theme": "Rumah Adat dan Suku Dayak", 
		"completed": false,
		"stars_earned": 0,
		"level1_completed": false,
		"level2_completed": false,
		"description": "Pulau dengan rumah betang dan budaya Dayak"
	},
	"sulawesi": {
		"name": "Pulau Sulawesi",
		"theme": "Kuliner Nusantara",
		"completed": false, 
		"stars_earned": 0,
		"level1_completed": false,
		"level2_completed": false,
		"description": "Surga kuliner dengan cita rasa yang unik"
	},
	"papua": {
		"name": "Pulau Papua",
		"theme": "Seni dan Musik",
		"completed": false,
		"stars_earned": 0,
		"level1_completed": false,
		"level2_completed": false,
		"description": "Keindahan seni dan musik tradisional Papua"
	}
}

const MAX_ENERGY = 100
const ISLAND_ORDER = ["sumatra", "jawa", "kalimantan", "sulawesi", "papua"]
const RANK_THRESHOLDS = {
	"Pemula": 0,
	"Penjelajah": 3,
	"Ahli Budaya Nusantara": 15
}

var first_map_visit = true
var scene_container
var ui_layer
var loading_screen
var current_active_scene = null
var is_changing_scene = false

# 🆕 Track Main node reference untuk scenes
var main_node_reference = null

func _ready():
	print("🎮 Nusantara Quest - Main System STARTING...")
	print("🎯 Version 3.3 - Enhanced Scene Management & Progress System")
	
	# 🆕 Simpan reference ke diri sendiri
	main_node_reference = self
	name = "Main"  # Pastikan nama konsisten
	
	setup_nodes()
	load_game_data()
	
	print("📂 LOADED DATA:")
	print("   Unlocked islands:", player_data.unlocked_islands)
	print("   Completed islands:", player_data.completed_islands)
	print("   Total stars:", player_data.total_stars)
	print("   Player rank:", player_data.rank)
	print("   Current island:", player_data.current_island)
	
	check_daily_reset()
	show_opening_scene()

func setup_nodes():
	print("=== SETTING UP NODES ===")
	scene_container = $SceneContainer
	ui_layer = $UILayer
	
	if has_node("UILayer/LoadingScreen"):
		loading_screen = $UILayer/LoadingScreen
	else:
		create_loading_screen()
	
	print("✅ Nodes setup completed")

func create_loading_screen():
	loading_screen = ColorRect.new()
	loading_screen.name = "LoadingScreen"
	loading_screen.anchor_right = 1.0
	loading_screen.anchor_bottom = 1.0
	loading_screen.color = Color(0.1, 0.1, 0.2, 0.9)
	loading_screen.visible = false
	
	var label = Label.new()
	label.name = "LoadingLabel"
	label.text = "Memuat Pulau Nusantara..."
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	loading_screen.add_child(label)
	ui_layer.add_child(loading_screen)

func show_opening_scene():
	print("🎯 Loading OpeningScene...")
	change_scene("res://scenes/OpeningScene.tscn")

func show_map():
	print("🗺️ Main.show_map() called - Loading MapScene with cleanup")
	
	# 🚨 CRITICAL: Clean up current scene sebelum load MapScene
	if current_active_scene:
		print("🧹 Cleaning up current active scene:", current_active_scene.name)
		if current_active_scene.has_method("cleanup_before_exit"):
			current_active_scene.cleanup_before_exit()
		
		# Remove from container
		scene_container.remove_child(current_active_scene)
		current_active_scene.queue_free()
		current_active_scene = null
	
	# Reset Main reference
	main_node_reference = self
	
	# Load MapScene
	change_scene("res://scenes/MapScene.tscn")

func start_island(island_id: String):
	print("🏝️ start_island() called for:", island_id)
	
	if is_changing_scene:
		print("⚠️ Already changing scene, ignoring duplicate call")
		return
	
	if island_id in player_data.unlocked_islands:
		player_data.current_island = island_id
		var island_info = island_progress[island_id]
		
		var scene_path = ""
		var scene_type = ""
		
		if not island_info.level1_completed:
			scene_path = "res://scenes/Pulau_{island}.tscn".format({"island": island_id.capitalize()})
			scene_type = "Level 1"
		elif island_info.level1_completed and not island_info.level2_completed:
			scene_path = "res://scenes/Level2_{island}.tscn".format({"island": island_id.capitalize()})
			scene_type = "Level 2"
		else:
			scene_path = "res://scenes/Level2_{island}.tscn".format({"island": island_id.capitalize()})
			scene_type = "Level 2 Completion (Replay)"
		
		print("   Scene type:", scene_type)
		print("   Path:", scene_path)
		
		if ResourceLoader.exists(scene_path):
			change_scene(scene_path)
		else:
			print("❌ Scene file not found:", scene_path)
			show_map()
	else:
		print("❌ Island locked:", island_id)
		show_map()

func start_island_level_2(island_id: String):
	print("🏝️ start_island_level_2() called for:", island_id)
	
	if is_changing_scene:
		print("⚠️ Already changing scene, ignoring duplicate call")
		return
	
	if island_id in player_data.unlocked_islands:
		player_data.current_island = island_id
		
		var scene_path = "res://scenes/Level2_{island}.tscn".format({"island": island_id.capitalize()})
		print("   Scene path:", scene_path)
		
		if ResourceLoader.exists(scene_path):
			change_scene(scene_path)
		else:
			print("❌ Scene file not found:", scene_path)
			show_map()
	else:
		print("❌ Island locked:", island_id)
		show_map()

# 🎯 PERBAIKAN KRITIS: change_scene() dengan cleanup yang lebih baik
func change_scene(scene_path: String):
	if is_changing_scene:
		print("⚠️ Already in the process of changing scene, ignoring:", scene_path)
		return
	
	is_changing_scene = true
	print("🔄 change_scene() STARTED for:", scene_path)
	
	# Show loading screen
	show_loading_screen()
	
	# 🆕 Force frame process
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	
	# 🆕 CLEAN UP SCENE CONTAINER
	if scene_container:
		print("🧹 Cleaning up scene container...")
		
		# Hapus semua child dari scene container
		var children = scene_container.get_children()
		for child in children:
			print("   Removing child:", child.name)
			
			# 🆕 Panggil cleanup method jika ada
			if child.has_method("cleanup_before_exit"):
				child.cleanup_before_exit()
			
			# Nonaktifkan node
			child.set_process(false)
			child.set_physics_process(false)
			child.set_process_input(false)
			
			# Hapus child
			scene_container.remove_child(child)
			child.queue_free()
		
		print("   Scene container cleared")
	
	# Load scene baru
	print("📦 Loading new scene:", scene_path)
	var scene_resource = load(scene_path)
	
	if scene_resource:
		var new_scene = scene_resource.instantiate()
		new_scene.name = scene_path.get_file().get_basename()
		
		# 🆕 INJEKSI MAIN REFERENCE KE SCENE BARU
		inject_main_reference(new_scene)
		
		# Tambahkan ke scene container
		scene_container.add_child(new_scene)
		current_active_scene = new_scene
		
		print("✅ Scene loaded and added:", new_scene.name)
		print("   Scene type:", new_scene.get_class())
		
		# 🆕 Force scene to be ready
		await get_tree().process_frame
	else:
		print("❌ Failed to load scene resource:", scene_path)
		create_fallback_scene(scene_path)
	
	# Hide loading screen
	hide_loading_screen()
	
	# 🆕 RESET FLAG
	is_changing_scene = false
	print("🔄 change_scene() COMPLETED for:", scene_path)

# 🆕 FUNGSI BARU: Inject Main reference ke scene
func inject_main_reference(scene_node):
	print("🎮 Injecting Main reference to:", scene_node.name)
	
	# Coba inject melalui method jika ada
	if scene_node.has_method("set_main_reference"):
		scene_node.set_main_reference(self)
	
	# Juga inject ke child nodes jika diperlukan
	for child in scene_node.get_children():
		if child.has_method("set_main_reference"):
			child.set_main_reference(self)

# ================= GAME LOGIC =================
func complete_level(island_id: String, level: int, stars: int, knowledge_points: int = 0):
	print("🎉 Level Completed: {island} Level {level}".format({"island": island_id, "level": level}))
	
	print("📊 BEFORE UPDATE:")
	print("   Island:", island_id)
	print("   Level 1 completed:", island_progress[island_id].level1_completed)
	print("   Level 2 completed:", island_progress[island_id].level2_completed)
	print("   Stars earned:", island_progress[island_id].stars_earned)
	print("   Total stars:", player_data.total_stars)
	print("   Completed islands:", player_data.completed_islands)
	
	# Update level completion
	if level == 1:
		island_progress[island_id]["level1_completed"] = true
		print("✅ Level 1 marked as completed for", island_id)
	elif level == 2:
		island_progress[island_id]["level2_completed"] = true
		print("✅ Level 2 marked as completed for", island_id)
	
	# Update stars
	if stars > island_progress[island_id]["stars_earned"]:
		var star_difference = stars - island_progress[island_id]["stars_earned"]
		player_data["total_stars"] += star_difference
		island_progress[island_id]["stars_earned"] = stars
		print("⭐ Stars updated:", island_progress[island_id]["stars_earned"], "Total:", player_data["total_stars"])
	
	# Update knowledge points
	player_data["knowledge_points"] += knowledge_points
	print("📚 Knowledge points added:", knowledge_points, "Total:", player_data["knowledge_points"])
	
	# Bonus energi
	player_data["energy"] = min(player_data["energy"] + 15, MAX_ENERGY)
	print("⚡ Energy bonus: +15, Total:", player_data["energy"])
	
	# Check island completion
	print("🔍 CHECKING ISLAND COMPLETION:")
	print("   L1:", island_progress[island_id]["level1_completed"])
	print("   L2:", island_progress[island_id]["level2_completed"])
	
	if island_progress[island_id]["level1_completed"] and island_progress[island_id]["level2_completed"]:
		if not island_id in player_data["completed_islands"]:
			player_data["completed_islands"].append(island_id)
			island_progress[island_id]["completed"] = true
			print("🎊 ISLAND FULLY COMPLETED - ADDED TO LIST:", island_id)
			
			# Unlock next island
			unlock_next_island(island_id)
		else:
			print("ℹ️ Island already in completed list")
	else:
		print("ℹ️ Island not fully completed yet")
	
	# Update rank
	update_player_rank()
	
	# Save progress
	var save_success = save_game_data()
	print("💾 Save success:", save_success)
	
	print("📊 AFTER UPDATE:")
	print("   Level 1 completed:", island_progress[island_id].level1_completed)
	print("   Level 2 completed:", island_progress[island_id].level2_completed) 
	print("   Stars earned:", island_progress[island_id].stars_earned)
	print("   Total stars:", player_data.total_stars)
	print("   Completed islands:", player_data.completed_islands)
	print("   Unlocked islands:", player_data.unlocked_islands)
	print("   Player rank:", player_data.rank)
	
	print("⏳ Level {level} completed, waiting for player to continue...".format({"level": level}))
	return true

func unlock_next_island(completed_island: String):
	print("🔑 Attempting to unlock next island after:", completed_island)
	
	var current_index = ISLAND_ORDER.find(completed_island)
	print("   Current index:", current_index, "Total islands:", ISLAND_ORDER.size())
	
	if current_index != -1 and current_index + 1 < ISLAND_ORDER.size():
		var next_island = ISLAND_ORDER[current_index + 1]
		print("   Next island should be:", next_island)
		
		if not next_island in player_data["unlocked_islands"]:
			player_data["unlocked_islands"].append(next_island)
			var next_island_name = island_progress[next_island]["name"]
			print("🔓 SUCCESS: NEW ISLAND UNLOCKED:", next_island_name)
			
			show_island_unlock_notification(next_island)
			save_game_data()
		else:
			print("ℹ️ Next island already unlocked:", next_island)
	else:
		print("❌ Cannot unlock next island - invalid index or last island")

func update_player_rank():
	var new_rank = "Pemula"
	var total_stars = player_data.total_stars
	
	print("🎖️ Checking rank update... Current:", player_data.rank, "Stars:", total_stars)
	print("   Thresholds - Penjelajah:", RANK_THRESHOLDS["Penjelajah"], "Ahli:", RANK_THRESHOLDS["Ahli Budaya Nusantara"])
	
	if total_stars >= RANK_THRESHOLDS["Ahli Budaya Nusantara"]:
		new_rank = "Ahli Budaya Nusantara"
	elif total_stars >= RANK_THRESHOLDS["Penjelajah"]:
		new_rank = "Penjelajah"
	
	if new_rank != player_data.rank:
		print("🎖️ RANK UP: {old} -> {new}".format({"old": player_data.rank, "new": new_rank}))
		player_data.rank = new_rank
		save_game_data()
		show_rank_up_notification(new_rank)
	else:
		print("ℹ️ Rank unchanged:", player_data.rank)

func show_rank_up_notification(new_rank: String):
	print("🎉 RANK UP ACHIEVED: ", new_rank)

func show_island_unlock_notification(island_id: String):
	var island_name = island_progress[island_id].name
	print("🎉 PULAU BARU TERBUKA: ", island_name)

# ================= SAVE/LOAD SYSTEM =================
func save_game_data() -> bool:
	var success = false
	var save_game = FileAccess.open("user://nusantara_quest_save.dat", FileAccess.WRITE)
	if save_game:
		var save_data = {
			"player_data": player_data,
			"island_progress": island_progress,
			"save_version": "1.0",
			"first_map_visit": first_map_visit,
			"current_active_scene": get_current_scene_name()
		}
		save_game.store_var(save_data)
		save_game.close()
		print("💾 Game progress saved SUCCESSFULLY")
		success = true
	else:
		print("❌ FAILED to save game data! Error:", FileAccess.get_open_error())
	return success

func load_game_data():
	if FileAccess.file_exists("user://nusantara_quest_save.dat"):
		var save_game = FileAccess.open("user://nusantara_quest_save.dat", FileAccess.READ)
		if save_game:
			var loaded_data = save_game.get_var()
			save_game.close()
			
			if loaded_data and loaded_data is Dictionary:
				if loaded_data.has("player_data"):
					player_data = loaded_data["player_data"]
				if loaded_data.has("island_progress"):
					island_progress = loaded_data["island_progress"]
				if loaded_data.has("first_map_visit"):
					first_map_visit = loaded_data["first_map_visit"]
				
				print("📂 Game data loaded successfully")
			else:
				print("❌ Invalid save data, resetting...")
				reset_game_data()
	else:
		print("📂 No save file found, using default data")
		reset_game_data()

func reset_game_data():
	print("🔄 Resetting game data...")
	player_data = {
		"player_name": "Penjelajah",
		"energy": 100,
		"knowledge_points": 0,
		"total_stars": 0,
		"rank": "Pemula",
		"completed_islands": [],
		"unlocked_islands": ["sumatra"],
		"daily_fact_seen": false,
		"last_play_date": Time.get_date_string_from_system(),
		"current_island": ""
	}
	
	for island_id in island_progress:
		island_progress[island_id].completed = false
		island_progress[island_id].stars_earned = 0
		island_progress[island_id].level1_completed = false
		island_progress[island_id].level2_completed = false
	
	first_map_visit = true
	current_active_scene = null
	save_game_data()

# ================= UTILITY FUNCTIONS =================
func use_energy(amount: int) -> bool:
	if player_data.energy >= amount:
		player_data.energy -= amount
		print("⚡ Energy used:", amount, "Remaining:", player_data.energy)
		save_game_data()
		return true
	else:
		print("❌ Not enough energy! Current:", player_data.energy, "Needed:", amount)
		return false

func check_daily_reset():
	var current_date = Time.get_date_string_from_system()
	if player_data.last_play_date != current_date:
		player_data.energy = MAX_ENERGY
		player_data.daily_fact_seen = false
		player_data.last_play_date = current_date
		print("📅 Daily reset - Energy restored to", MAX_ENERGY)
		save_game_data()

func can_play_climax() -> bool:
	return player_data.completed_islands.size() == ISLAND_ORDER.size()

func get_island_progress(island_id: String) -> Dictionary:
	if island_id in island_progress:
		return island_progress[island_id]
	return {}

func get_current_island_info() -> Dictionary:
	if player_data.current_island in island_progress:
		return island_progress[player_data.current_island]
	return {}

func get_is_first_visit() -> bool:
	return first_map_visit

func mark_first_visit_complete():
	first_map_visit = false
	print("📍 First visit to map completed")
	save_game_data()

# ================= 🎯 METHOD UNTUK MAPSCENE =================
func get_player_data():
	print("📊 Scene requesting player data...")
	var data = {
		"player_name": player_data.player_name,
		"unlocked_islands": player_data.unlocked_islands,
		"completed_islands": player_data.completed_islands,
		"total_stars": player_data.total_stars,
		"knowledge_points": player_data.knowledge_points,
		"energy": player_data.energy,
		"rank": player_data.rank,
		"completed_levels": get_completed_levels()
	}
	return data

func get_completed_levels():
	var completed_levels = {}
	for island_id in island_progress:
		if island_progress[island_id].level1_completed:
			completed_levels[island_id + "_1"] = true
		if island_progress[island_id].level2_completed:
			completed_levels[island_id + "_2"] = true
	return completed_levels

func get_game_data():
	print("📊 Returning raw game data")
	return {
		"player_data": player_data,
		"island_progress": island_progress,
		"first_map_visit": first_map_visit
	}

func is_island_unlocked(island_name: String) -> bool:
	var unlocked = island_name in player_data.unlocked_islands
	print("🔍 Island unlock check:", island_name, "->", unlocked)
	return unlocked

func is_island_completed(island_name: String) -> bool:
	var completed = island_name in player_data.completed_islands
	print("🔍 Island completion check:", island_name, "->", completed)
	return completed

func get_island_progress_data(island_name: String) -> Dictionary:
	if island_name in island_progress:
		return island_progress[island_name]
	return {}

# ================= LOADING SCREEN =================
func show_loading_screen():
	if loading_screen:
		loading_screen.visible = true
		print("⏳ Loading screen shown")

func hide_loading_screen():
	if loading_screen:
		loading_screen.visible = false
		print("✅ Loading screen hidden")

# ================= FALLBACK SCENE =================
func create_fallback_scene(scene_path: String):
	print("⚠️ Creating fallback scene for:", scene_path)
	
	var fallback = Control.new()
	fallback.name = "FallbackScene"
	fallback.anchor_right = 1.0
	fallback.anchor_bottom = 1.0
	
	var bg = ColorRect.new()
	bg.name = "FallbackBG"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.8, 0.2, 0.2, 1)
	fallback.add_child(bg)
	
	var label = Label.new()
	label.name = "ErrorLabel"
	label.text = "ERROR: Cannot load scene\n" + scene_path + "\n\nPress F1 to return to Map"
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -200
	label.offset_top = -50
	label.offset_right = 200
	label.offset_bottom = 50
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	fallback.add_child(label)
	
	scene_container.add_child(fallback)
	current_active_scene = fallback

# ================= 🆕 UTILITY FUNCTIONS =================
func get_current_scene_name() -> String:
	if current_active_scene:
		return current_active_scene.name
	return ""

func get_scene_container() -> Node:
	return scene_container

func print_scene_tree():
	print("=== SCENE TREE DEBUG ===")
	print("Root children:", get_tree().get_root().get_child_count())
	
	for child in get_tree().get_root().get_children():
		print("  - " + child.name + " (" + child.get_class() + ")")
		if child == self:
			print("    SceneContainer children:", scene_container.get_child_count())
			for scene_child in scene_container.get_children():
				print("      - " + scene_child.name + " (" + scene_child.get_class() + ")")

# 🆕 Method untuk mendapatkan Main node
func get_main_node():
	return self

# ================= DEBUG KEYS =================
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("🔧 DEBUG F1: Returning to map")
				show_map()
			KEY_F2:
				player_data.unlocked_islands = ISLAND_ORDER.duplicate()
				print("🔧 DEBUG F2: All islands unlocked")
				save_game_data()
			KEY_F3:
				for island_id in ISLAND_ORDER:
					if not island_id in player_data.completed_islands:
						complete_level(island_id, 1, 3, 100)
						complete_level(island_id, 2, 3, 100)
				print("🔧 DEBUG F3: All islands completed with max stars")
			KEY_F4:
				reset_game_data()
				print("🔧 DEBUG F4: Game data reset")
			KEY_F5:
				print("=== GAME STATE DEBUG ===")
				print("Player Rank:", player_data.rank)
				print("Total Stars:", player_data.total_stars)
				print("Energy:", player_data.energy)
				print("Unlocked Islands:", player_data.unlocked_islands)
				print("Completed Islands:", player_data.completed_islands)
				print("First Map Visit:", first_map_visit)
				
				print("=== ISLAND PROGRESS ===")
				for island_id in ISLAND_ORDER:
					var island = island_progress[island_id]
					print("   {name}: L1={l1} L2={l2} Stars={stars} Completed={completed}".format({
						"name": island.name,
						"l1": island.level1_completed,
						"l2": island.level2_completed,
						"stars": island.stars_earned,
						"completed": island.completed
					}))
			KEY_F6:
				print_scene_tree()
			KEY_F7:
				print("🔧 DEBUG F7: Scene debug")
				print("Current active scene:", current_active_scene.name if current_active_scene else "None")
				print("Scene container has", scene_container.get_child_count(), "children")
				if scene_container.get_child_count() > 0:
					for i in range(scene_container.get_child_count()):
						var child = scene_container.get_child(i)
						print("  Child", i, ":", child.name, "(", child.get_class(), ")")

func _exit_tree():
	save_game_data()
	print("🎮 Main system exiting...")
	print("   Current active scene:", get_current_scene_name())
	print("   Scene changes in progress:", is_changing_scene)