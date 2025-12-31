extends Control

# Dialog sequence untuk NPC
var npc_dialogs = [
	"Selamat datang, Penjelajah aku senang kamu sudah sampai di sini.",
	"Sebelum memulai petualangan, izinkan aku menjelaskan sedikit...",
	"Kamu akan menjelajahi Nusantara, dimulai dari pulau Sumatera.",
	"Setiap pulau memiliki tantangan dan pengetahuan yang unik.",
	"Selesaikan kuis disetiap pulau untuk mendapatkan kunci ke pulau berikutnya.",
	"Sekarang pilih pulau Sumatera untuk memulai petualanganmu!"
]

var completion_dialog = [
	"Selamat! Kamu telah menyalakan cahaya pengetahuan di seluruh Nusantara.",
	"Cintailah Negeri ini, karena disinilah akar dan jati dirimu."
]

var current_dialog = 0
var is_dialog_active = true
var is_completion_dialog = false
var is_all_completed = false  # Flag untuk menandakan semua pulau selesai

# Node references dengan @onready
@onready var dialog_container = $NPCContainer/DialogContainer
@onready var dialog_text = $NPCContainer/DialogContainer/DialogText
@onready var continue_button = $NPCContainer/DialogContainer/ContinueButton
@onready var interactive_areas = $InteractiveAreas
@onready var island_overlay = $IslandsOverlay
@onready var status_container = $UILayer/StatusContainer
@onready var back_button = $UILayer/BackButton

# VARIABLE UNTUK MAIN NODE
var main_node = null

func _ready():
	print("🗺️ MapScene Loaded")
	call_deferred("initialize_scene")

func initialize_scene():
	print("🔧 Initializing scene...")
	
	find_main_node()
	setup_required_nodes()
	setup_interactions()
	setup_status_display()
	
	var should_show_dialog = true
	
	if main_node and main_node.has_method("get_is_first_visit"):
		should_show_dialog = main_node.get_is_first_visit()
		print("💡 First visit check:", should_show_dialog)
	else:
		print("⚠️ Main node not found or missing method, using default dialog")
	
	if should_show_dialog:
		start_npc_dialog()
		print("💬 Starting NPC dialog - first visit")
	else:
		# Cek apakah semua pulau sudah selesai
		is_all_completed = check_all_islands_completed()
		if is_all_completed:
			print("🎯 Semua pulau telah selesai, menampilkan mode penyelesaian")
			# Tidak menampilkan dialog secara otomatis, tapi siapkan back button
		if dialog_container:
			dialog_container.visible = false
		is_dialog_active = false
		print("💬 Skipping NPC dialog - not first visit")
	
	# Tunggu sedikit untuk memastikan scene siap
	await get_tree().create_timer(0.1).timeout
	update_islands_status()
	
	# Setup tombol kembali jika semua pulau selesai
	setup_completion_ui()
	
	print_scene_structure()

func check_all_islands_completed():
	"""Cek apakah semua pulau sudah selesai untuk menampilkan dialog penyelesaian"""
	if not main_node:
		return false
	
	var completed_islands = []
	var unlocked_islands = []
	
	if main_node.has_method("get_player_data"):
		var player_data = main_node.get_player_data()
		if player_data:
			completed_islands = player_data.get("completed_islands", [])
			unlocked_islands = player_data.get("unlocked_islands", ["sumatra"])
	
	# Daftar semua pulau yang tersedia
	var all_islands = ["sumatra", "jawa", "kalimantan", "sulawesi", "papua"]
	
	# Cek apakah semua pulau telah terbuka DAN selesai
	var all_unlocked = true
	var all_completed = true
	
	for island in all_islands:
		if island not in unlocked_islands:
			all_unlocked = false
		if island not in completed_islands:
			all_completed = false
	
	# Jika semua pulau sudah terbuka dan selesai
	if all_unlocked and all_completed:
		print("🎉 Semua pulau telah selesai!")
		return true
	
	return false

func setup_completion_ui():
	"""Setup UI khusus untuk mode penyelesaian (semua pulau selesai)"""
	if not is_all_completed:
		return
	
	print("🔄 Setting up completion UI...")
	
	# Buat atau update tombol kembali
	if not back_button:
		create_back_button()
	
	# Tampilkan tombol kembali
	back_button.visible = true
	
	# Update dialog text jika sedang aktif
	if is_dialog_active and is_completion_dialog:
		dialog_text.text = "Petualanganmu di Nusantara telah selesai!\nGunakan tombol 'Kembali' untuk melanjutkan."

func create_back_button():
	"""Buat tombol kembali ke OpeningScene"""
	print("🔙 Creating back button...")
	
	if not has_node("UILayer"):
		create_ui_layer()
	
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "🏠 Kembali ke Menu Utama"
	
	# Posisi tombol - di pojok kiri atas
	back_button.anchor_left = 0.02
	back_button.anchor_top = 0.02
	back_button.anchor_right = 0.02
	back_button.anchor_bottom = 0.1
	back_button.offset_left = 10
	back_button.offset_top = 10
	back_button.offset_right = -10
	back_button.offset_bottom = -10
	
	# Style untuk tombol
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
	button_style.border_color = Color.WHITE
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_right = 8
	button_style.corner_radius_bottom_left = 8
	back_button.add_theme_stylebox_override("normal", button_style)
	
	# Style untuk hover
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.5, 0.9, 1.0)
	back_button.add_theme_stylebox_override("hover", hover_style)
	
	back_button.add_theme_font_size_override("font_size", 16)
	
	# Tambahkan ke UILayer
	$UILayer.add_child(back_button)
	
	# Connect signal
	back_button.pressed.connect(_on_back_button_pressed)
	
	print("✅ Back button created")

func find_main_node():
	print("🔍 Looking for Main node...")
	
	main_node = get_node_or_null("/root/Main")
	
	if main_node:
		print("✅ Main node found at /root/Main")
		return true
	
	main_node = get_tree().root.get_node_or_null("Main")
	if main_node:
		print("✅ Main node found as child of root")
		return true
	
	var parent = get_parent()
	if parent and parent.has_method("show_map"):
		main_node = parent
		print("✅ Main node found as parent with show_map method")
		return true
	
	print("❌ Main node not found - running in standalone mode")
	return false

func setup_required_nodes():
	"""Pastikan semua node yang diperlukan ada"""
	print("🔧 Setting up required nodes...")
	
	if not has_node("Background"):
		create_background()
	
	if not has_node("InteractiveAreas"):
		create_interactive_areas()
	
	if not has_node("NPCContainer"):
		create_npc_container()
	
	if not has_node("UILayer"):
		create_ui_layer()
	
	# PERBAIKAN: Debug IslandOverlay untuk melihat TextureButton yang ada
	print("🔍 Checking IslandOverlay for TextureButtons...")
	if not island_overlay:
		island_overlay = get_node_or_null("IslandsOverlay")
		if island_overlay:
			print("✅ IslandOverlay found")
			# Cari semua TextureButton di IslandOverlay
			var texture_buttons = []
			for child in island_overlay.get_children():
				if child is TextureButton:
					texture_buttons.append(child.name)
				elif child is TextureRect:
					print("   - TextureRect:", child.name)
				elif child is Button:
					print("   - Button:", child.name)
			
			if texture_buttons.size() > 0:
				print("✅ Found TextureButtons in IslandOverlay:", texture_buttons)
			else:
				print("⚠️ No TextureButtons found in IslandOverlay")
		else:
			print("❌ IslandOverlay not found in scene")

func create_background():
	print("🎨 Creating background...")
	var bg = TextureRect.new()
	bg.name = "Background"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var bg_texture = load("res://assets/images/backgrounds/map_background.png")
	if bg_texture:
		bg.texture = bg_texture
		print("✅ Background texture loaded")
	else:
		bg.texture = null
		bg.color = Color("#1a2a6c")
		print("✅ Background color set (texture not found)")
	
	add_child(bg)
	move_child(bg, 0)

func create_interactive_areas():
	print("🗺️ Creating interactive areas...")
	var areas = Node2D.new()
	areas.name = "InteractiveAreas"
	add_child(areas)
	interactive_areas = areas

func create_npc_container():
	print("💬 Creating NPC container...")
	var npc_container = Panel.new()
	npc_container.name = "NPCContainer"
	npc_container.anchor_right = 1.0
	npc_container.anchor_bottom = 0.3
	npc_container.offset_left = 100
	npc_container.offset_top = 50
	npc_container.offset_right = -100
	npc_container.offset_bottom = 250
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	panel_style.border_color = Color.GOLD
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	npc_container.add_theme_stylebox_override("panel", panel_style)
	
	add_child(npc_container)
	
	# Create dialog container
	var new_dialog_container = Panel.new()
	new_dialog_container.name = "DialogContainer"
	new_dialog_container.anchor_right = 1.0
	new_dialog_container.anchor_bottom = 1.0
	new_dialog_container.offset_left = 20
	new_dialog_container.offset_top = 20
	new_dialog_container.offset_right = -20
	new_dialog_container.offset_bottom = -20
	npc_container.add_child(new_dialog_container)
	
	# Create dialog text
	var new_dialog_text = Label.new()
	new_dialog_text.name = "DialogText"
	new_dialog_text.anchor_right = 1.0
	new_dialog_text.anchor_bottom = 0.7
	new_dialog_text.offset_left = 20
	new_dialog_text.offset_top = 20
	new_dialog_text.offset_right = -20
	new_dialog_text.offset_bottom = -60
	new_dialog_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_dialog_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	new_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_dialog_text.text = "Selamat datang, Penjelajah aku senang kamu sudah sampai di sini."
	new_dialog_text.add_theme_font_size_override("font_size", 18)
	new_dialog_container.add_child(new_dialog_text)
	
	# Create continue button
	var new_continue_button = Button.new()
	new_continue_button.name = "ContinueButton"
	new_continue_button.anchor_left = 0.5
	new_continue_button.anchor_top = 0.8
	new_continue_button.anchor_right = 0.5
	new_continue_button.anchor_bottom = 0.95
	new_continue_button.offset_left = -60
	new_continue_button.offset_top = -35
	new_continue_button.offset_right = 60
	new_continue_button.offset_bottom = 35
	new_continue_button.text = "Lanjutkan"
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.6, 0.2)
	button_style.border_color = Color.WHITE
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_right = 8
	button_style.corner_radius_bottom_left = 8
	new_continue_button.add_theme_stylebox_override("normal", button_style)
	new_continue_button.add_theme_font_size_override("font_size", 16)
	
	new_dialog_container.add_child(new_continue_button)
	
	# Update references
	dialog_container = new_dialog_container
	dialog_text = new_dialog_text
	continue_button = new_continue_button
	
	print("✅ Created NPC Container")

func create_ui_layer():
	print("📊 Creating UI layer...")
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

func setup_interactions():
	print("🎮 Setting up interactions...")
	
	if not continue_button:
		print("❌ Continue button not found")
		return
	
	continue_button.pressed.connect(_on_continue_pressed)
	print("✅ Continue button connected")
	
	setup_island_buttons()

func setup_island_buttons():
	print("📍 Setting up island buttons...")
	
	if not interactive_areas:
		print("❌ InteractiveAreas not found")
		return
	
	var screen_size = get_viewport_rect().size
	var island_data = {
		"Sumatra": Vector2(screen_size.x * 0.3, screen_size.y * 0.6),
		"Jawa": Vector2(screen_size.x * 0.5, screen_size.y * 0.7),
		"Kalimantan": Vector2(screen_size.x * 0.4, screen_size.y * 0.5),
		"Sulawesi": Vector2(screen_size.x * 0.7, screen_size.y * 0.6),
		"Papua": Vector2(screen_size.x * 0.8, screen_size.y * 0.4)
	}
	
	for island_name in island_data.keys():
		var button = interactive_areas.get_node_or_null(island_name)
		
		if not button:
			button = TextureButton.new()
			button.name = island_name
			button.position = island_data[island_name]
			button.custom_minimum_size = Vector2(80, 80)
			button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			
			# Coba load texture untuk button interaktif
			var texture_path = "res://assets/images/ui/island_" + island_name.to_lower() + ".png"
			var texture = load(texture_path)
			if texture:
				button.texture_normal = texture
				print("✅ Loaded texture for interactive button:", island_name)
			else:
				print("❌ Cannot load texture:", texture_path)
				button.custom_minimum_size = Vector2(80, 80)
				if island_name == "Sumatra":
					button.modulate = Color(0.5, 0.8, 0.5)
				else:
					button.modulate = Color(0.8, 0.5, 0.5)
			
			interactive_areas.add_child(button)
			print("✅ Created interactive island button:", island_name)
		
		# Connect signals hanya untuk button interaktif
		button.pressed.connect(_on_island_pressed.bind(island_name.to_lower()))
		button.mouse_entered.connect(_on_island_hover.bind(island_name, true))
		button.mouse_exited.connect(_on_island_hover.bind(island_name, false))

func setup_status_display():
	print("📊 Setting up status display...")
	
	if not status_container:
		create_status_container()
	
	update_status_display()

func create_status_container():
	print("🎯 Creating status container...")
	
	if not has_node("UILayer"):
		create_ui_layer()
	
	status_container = Panel.new()
	status_container.name = "StatusContainer"
	status_container.anchor_left = 0.7
	status_container.anchor_top = 0.02
	status_container.anchor_right = 0.98
	status_container.anchor_bottom = 0.2
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	panel_style.border_color = Color.GOLD
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	status_container.add_theme_stylebox_override("panel", panel_style)
	
	$UILayer.add_child(status_container)
	
	# Create VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	status_container.add_child(vbox)
	
	# Create status labels
	var title = Label.new()
	title.name = "Title"
	title.text = "STATUS PENJELAJAH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.GOLD)
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Rank label
	var rank_label = Label.new()
	rank_label.name = "RankLabel"
	rank_label.text = "🏆 Peringkat: Pemula"
	rank_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rank_label)
	
	# Stars label
	var stars_label = Label.new()
	stars_label.name = "StarsLabel"
	stars_label.text = "⭐ Bintang: 0/25"
	stars_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stars_label)
	
	# Points label
	var points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "📚 Poin: 0"
	points_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(points_label)
	
	# Energy label
	var energy_label = Label.new()
	energy_label.name = "EnergyLabel"
	energy_label.text = "⚡ Energi: 100/100"
	energy_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(energy_label)
	
	# Progress label
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "🔓 Progress: 0/5 Pulau"
	progress_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(progress_label)

func start_npc_dialog():
	print("💬 Starting NPC dialog...")
	is_dialog_active = true
	is_completion_dialog = false
	if dialog_container:
		dialog_container.visible = true
	current_dialog = 0
	show_dialog(current_dialog)

func start_completion_dialog():
	print("🎉 Starting completion dialog...")
	is_dialog_active = true
	is_completion_dialog = true
	if dialog_container:
		dialog_container.visible = true
	current_dialog = 0
	show_completion_dialog(current_dialog)
	
	# Set flag semua pulau selesai
	is_all_completed = true
	setup_completion_ui()

func show_dialog(dialog_index):
	if dialog_index < npc_dialogs.size() and dialog_text:
		dialog_text.text = npc_dialogs[dialog_index]
		current_dialog = dialog_index
		print("💬 Dialog", dialog_index + 1, ":", dialog_text.text)
		
		# Update teks tombol untuk dialog terakhir
		if dialog_index == npc_dialogs.size() - 1:
			continue_button.text = "Mulai Petualangan!"
	else:
		end_npc_dialog()

func show_completion_dialog(dialog_index):
	if dialog_index < completion_dialog.size() and dialog_text:
		dialog_text.text = completion_dialog[dialog_index]
		current_dialog = dialog_index
		print("🎉 Completion dialog", dialog_index + 1, ":", dialog_text.text)
		
		# Update teks tombol untuk dialog terakhir
		if dialog_index == completion_dialog.size() - 1:
			continue_button.text = "Kembali ke Menu"
	else:
		end_completion_dialog()

func _on_continue_pressed():
	print("➡️ Continue button pressed")
	
	if is_completion_dialog:
		# Jika di dialog penyelesaian, tombol "Kembali ke Menu" akan kembali ke OpeningScene
		if current_dialog == completion_dialog.size() - 1:
			return_to_opening_scene()
		else:
			show_completion_dialog(current_dialog + 1)
	else:
		show_dialog(current_dialog + 1)

func _on_back_button_pressed():
	print("🔙 Back button pressed")
	return_to_opening_scene()

func return_to_opening_scene():
	"""Kembali ke OpeningScene"""
	print("🏠 Returning to OpeningScene")
	if main_node and main_node.has_method("show_opening_scene"):
		main_node.show_opening_scene()
	else:
		print("⚠️ Main node not found, trying direct scene change")
		get_tree().change_scene_to_file("res://scenes/OpeningScene.tscn")

func show_locked_message(island_name):
	if dialog_container and dialog_text:
		dialog_container.visible = true
		is_dialog_active = true
		dialog_text.text = "Pulau " + island_name.capitalize() + " masih terkunci!\nSelesaikan pulau sebelumnya terlebih dahulu."
		
		await get_tree().create_timer(3.0).timeout
		dialog_container.visible = false
		is_dialog_active = false

func update_islands_status():
	print("🔄 Updating islands status...")
	
	if not main_node:
		print("❌ Main node not found - cannot update islands status")
		show_standalone_mode_message()
		return
	
	print("🔍 Main node found, checking player data...")
	
	var unlocked_islands = ["sumatra"]
	var completed_islands = []
	
	if main_node.has_method("get_player_data"):
		var player_data = main_node.get_player_data()
		if player_data:
			unlocked_islands = player_data.get("unlocked_islands", ["sumatra"])
			completed_islands = player_data.get("completed_islands", [])
			print("✅ Player data loaded via get_player_data():")
			print("   Unlocked islands:", unlocked_islands)
			print("   Completed islands:", completed_islands)
		else:
			print("❌ Player data is null from get_player_data(), using defaults")
	else:
		print("❌ Main node doesn't have get_player_data method")
		if main_node.has_method("get_game_data"):
			var game_data = main_node.get_game_data()
			if game_data:
				unlocked_islands = game_data.get("unlocked_islands", ["sumatra"])
				completed_islands = game_data.get("completed_islands", [])
				print("✅ Game data loaded via get_game_data():")
				print("   Unlocked islands:", unlocked_islands)
				print("   Completed islands:", completed_islands)
		else:
			print("⚠️ Using default islands data")
	
	if not interactive_areas:
		print("❌ InteractiveAreas not found")
		return
	
	var island_order = ["sumatra", "jawa", "kalimantan", "sulawesi", "papua"]
	
	if "sumatra" not in unlocked_islands:
		print("⚠️ Sumatra not in unlocked_islands, adding it automatically")
		unlocked_islands.append("sumatra")
	
	print("🎯 Final islands status:")
	print("   Unlocked:", unlocked_islands)
	print("   Completed:", completed_islands)
	
	# PERBAIKAN: Update indicator TextureButtons di IslandOverlay
	update_island_overlay_indicators(unlocked_islands, completed_islands)
	
	# Update button interaktif di InteractiveAreas
	for i in range(island_order.size()):
		var island_name = island_order[i]
		var button_node = interactive_areas.get_node_or_null(island_name.capitalize())
		
		if not button_node:
			print("❌ Interactive button not found for:", island_name)
			continue
		
		if island_name in unlocked_islands:
			button_node.disabled = false
			
			if island_name in completed_islands:
				button_node.modulate = Color(1, 0.84, 0, 0.8)  # Gold untuk completed
				print("⭐", island_name, ": COMPLETED")
			else:
				button_node.modulate = Color(1, 1, 1, 0.8)  # Normal untuk unlocked
				print("✅", island_name, ": UNLOCKED (not completed)")
		else:
			button_node.disabled = true
			button_node.modulate = Color(0.3, 0.3, 0.3, 0.4)  # Gelap untuk locked
			print("🔒", island_name, ": LOCKED")
	
	update_status_display()

func update_island_overlay_indicators(unlocked_islands: Array, completed_islands: Array):
	"""Update TextureButton indicators di IslandOverlay berdasarkan status pulau"""
	print("📍 Updating IslandOverlay TextureButton indicators...")
	
	if not island_overlay:
		print("❌ IslandOverlay not found, cannot update indicators")
		return
	
	# Daftar nama TextureButton yang dicari di IslandOverlay
	var island_names = ["Sumatra", "Jawa", "Kalimantan", "Sulawesi", "Papua"]
	
	# Cari dan update setiap TextureButton
	for island_display_name in island_names:
		var indicator_name = island_display_name
		var island_name_lower = island_display_name.to_lower()
		
		# Cari TextureButton di IslandOverlay
		var indicator = island_overlay.get_node_or_null(indicator_name)
		
		if not indicator:
			print("⚠️ TextureButton indicator not found for:", indicator_name)
			# Coba dengan nama lain
			continue
		
		# Pastikan ini adalah TextureButton
		if not indicator is TextureButton:
			print("⚠️ Node", indicator_name, "is not a TextureButton, it's a", indicator.get_class())
			continue
		
		print("✅ Found TextureButton indicator for:", island_display_name)
		
		# Tentukan status dan update indicator
		if island_name_lower in completed_islands:
			update_indicator_texture(indicator, "completed")
			print("📍", island_display_name, "indicator: COMPLETED")
		elif island_name_lower in unlocked_islands:
			update_indicator_texture(indicator, "unlocked")
			print("📍", island_display_name, "indicator: UNLOCKED")
		else:
			update_indicator_texture(indicator, "locked")
			print("📍", island_display_name, "indicator: LOCKED")
	
	print("✅ IslandOverlay indicators updated")

func update_indicator_texture(indicator: TextureButton, status: String):
	"""Update texture untuk TextureButton indicator berdasarkan status"""
	print("🎨 Updating TextureButton indicator for status:", status)
	
	var texture_path = ""
	match status:
		"locked":
			texture_path = "res://assets/images/ui/indicator_locked.png"
			indicator.modulate = Color(1, 0.3, 0.3, 1.0)  # MERAH untuk locked
		"unlocked":
			texture_path = "res://assets/images/ui/indicator_unlocked.png"
			indicator.modulate = Color(0.3, 1, 0.3, 1.0)  # HIJAU untuk unlocked
		"completed":
			texture_path = "res://assets/images/ui/indicator_unlocked.png"  # Gunakan unlocked texture
			indicator.modulate = Color(1, 0.84, 0, 1.0)  # EMAS untuk completed
	
	var texture = load(texture_path)
	if texture:
		indicator.texture_normal = texture  # PERBAIKAN: Gunakan texture_normal untuk TextureButton
		indicator.visible = true
		print("✅ Applied", status, "texture to TextureButton indicator")
	else:
		print("❌ Cannot load indicator texture:", texture_path)
		# Fallback: gunakan warna saja
		indicator.texture_normal = null
		indicator.visible = true

func update_status_display():
	if not status_container:
		print("❌ Status container not found")
		return
	
	if not main_node:
		print("❌ Main node not found - using default status")
		show_default_status()
		return
	
	print("🔍 Updating status display with real data...")
	
	var rank = "Pemula"
	var total_stars = 0
	var knowledge_points = 0
	var energy = 100
	var completed_islands = []
	var unlocked_islands = ["sumatra"]
	
	if main_node.has_method("get_player_data"):
		var player_data = main_node.get_player_data()
		if player_data:
			# Ambil data dari player_data
			total_stars = player_data.get("total_stars", 0)
			knowledge_points = player_data.get("knowledge_points", 0)
			energy = player_data.get("energy", 100)
			completed_islands = player_data.get("completed_islands", [])
			unlocked_islands = player_data.get("unlocked_islands", ["sumatra"])
			
			# Tentukan rank berdasarkan jumlah pulau yang selesai atau total stars
			var completed_count = completed_islands.size()
			
			# Sistem ranking: 0-1 pulau: Pemula, 2-3 pulau: Penjelajah, 4-5 pulau: Ahli Budaya
			if completed_count >= 4:
				rank = "Ahli Budaya"
			elif completed_count >= 2:
				rank = "Penjelajah"
			else:
				rank = "Pemula"
			
			print("✅ Using real player data from get_player_data()")
		else:
			print("❌ Player data is null, using defaults")
	else:
		print("❌ get_player_data method not found, trying direct access")
		if main_node.has_method("get_game_data"):
			var game_data = main_node.get_game_data()
			if game_data:
				total_stars = game_data.get("total_stars", 0)
				knowledge_points = game_data.get("knowledge_points", 0)
				energy = game_data.get("energy", 100)
				completed_islands = game_data.get("completed_islands", [])
				unlocked_islands = game_data.get("unlocked_islands", ["sumatra"])
				
				# Tentukan rank berdasarkan jumlah pulau yang selesai
				var completed_count = completed_islands.size()
				if completed_count >= 4:
					rank = "Ahli Budaya"
				elif completed_count >= 2:
					rank = "Penjelajah"
				else:
					rank = "Pemula"
				
				print("✅ Using game data from get_game_data()")
	
	print("📊 Final display data:")
	print("   Rank:", rank)
	print("   Total Stars:", total_stars)
	print("   Knowledge Points:", knowledge_points)
	print("   Energy:", energy)
	print("   Completed Islands:", completed_islands)
	print("   Unlocked Islands:", unlocked_islands)
	
	if has_node("UILayer/StatusContainer/VBoxContainer/RankLabel"):
		$UILayer/StatusContainer/VBoxContainer/RankLabel.text = "🏆 Peringkat: " + str(rank)
	
	if has_node("UILayer/StatusContainer/VBoxContainer/StarsLabel"):
		$UILayer/StatusContainer/VBoxContainer/StarsLabel.text = "⭐ Bintang: " + str(total_stars) + "/25"
	
	if has_node("UILayer/StatusContainer/VBoxContainer/PointsLabel"):
		$UILayer/StatusContainer/VBoxContainer/PointsLabel.text = "📚 Poin: " + str(knowledge_points)
	
	if has_node("UILayer/StatusContainer/VBoxContainer/EnergyLabel"):
		$UILayer/StatusContainer/VBoxContainer/EnergyLabel.text = "⚡ Energi: " + str(energy) + "/100"
	
	if has_node("UILayer/StatusContainer/VBoxContainer/ProgressLabel"):
		var progress_count = completed_islands.size()
		$UILayer/StatusContainer/VBoxContainer/ProgressLabel.text = "🔓 Progress: " + str(progress_count) + "/5 Pulau"
	
	print("✅ Status display updated")

func show_default_status():
	if has_node("UILayer/StatusContainer/VBoxContainer/RankLabel"):
		$UILayer/StatusContainer/VBoxContainer/RankLabel.text = "🏆 Peringkat: Pemula"
	if has_node("UILayer/StatusContainer/VBoxContainer/StarsLabel"):
		$UILayer/StatusContainer/VBoxContainer/StarsLabel.text = "⭐ Bintang: 0/25"
	if has_node("UILayer/StatusContainer/VBoxContainer/PointsLabel"):
		$UILayer/StatusContainer/VBoxContainer/PointsLabel.text = "📚 Poin: 0"
	if has_node("UILayer/StatusContainer/VBoxContainer/EnergyLabel"):
		$UILayer/StatusContainer/VBoxContainer/EnergyLabel.text = "⚡ Energi: 100/100"
	if has_node("UILayer/StatusContainer/VBoxContainer/ProgressLabel"):
		$UILayer/StatusContainer/VBoxContainer/ProgressLabel.text = "🔓 Progress: 0/5 Pulau"

func show_standalone_mode_message():
	if dialog_container and dialog_text:
		dialog_container.visible = true
		is_dialog_active = true
		dialog_text.text = "⚠️ STANDALONE MODE\n\nMapScene sedang dijalankan secara terpisah.\nTekan ESC untuk kembali."
		print("🔧 Running in standalone mode")

func _on_island_pressed(island_name):
	print("🏝️ Island pressed:", island_name)
	
	# Jika semua pulau sudah selesai, beri pesan khusus
	if is_all_completed:
		show_completion_message()
		return
	
	if not is_dialog_active:
		if not main_node:
			print("❌ Main node not found - cannot start island")
			show_standalone_mode_message()
			return
		
		var unlocked_islands = ["sumatra"]
		
		if main_node.has_method("get_player_data"):
			var player_data = main_node.get_player_data()
			if player_data:
				unlocked_islands = player_data.get("unlocked_islands", ["sumatra"])
		
		if island_name == "sumatra":
			if "sumatra" not in unlocked_islands:
				print("⚠️ Sumatra not in unlocked_islands, but allowing access anyway")
				unlocked_islands.append("sumatra")
		
		print("🔍 Checking if", island_name, "is unlocked:", island_name in unlocked_islands)
		
		if island_name in unlocked_islands:
			print("🚀 Starting island:", island_name)
			
			var button_node = interactive_areas.get_node_or_null(island_name.capitalize())
			if button_node:
				var tween = create_tween()
				tween.tween_property(button_node, "scale", Vector2(0.95, 0.95), 0.1)
				tween.tween_property(button_node, "scale", Vector2(1.0, 1.0), 0.1)
				tween.tween_callback(_start_island_level.bind(island_name))
		else:
			print("🔒 Island locked:", island_name)
			show_locked_message(island_name)

func show_completion_message():
	"""Tampilkan pesan bahwa semua pulau sudah selesai"""
	if dialog_container and dialog_text:
		dialog_container.visible = true
		is_dialog_active = true
		dialog_text.text = "🎉 Selamat! Semua pulau telah selesai!\n\nGunakan tombol 'Kembali ke Menu Utama' untuk melanjutkan."
		
		# Ganti teks tombol continue
		continue_button.text = "OK"
		continue_button.visible = true
		
		await get_tree().create_timer(3.0).timeout
		dialog_container.visible = false
		is_dialog_active = false

func _start_island_level(island_name):
	print("🎯 Loading island:", island_name)
	if main_node and main_node.has_method("start_island"):
		main_node.start_island(island_name)
	else:
		print("❌ Main.start_island() method not found!")
		show_standalone_mode_message()

func end_npc_dialog():
	print("💬 NPC dialog ended")
	is_dialog_active = false
	if dialog_container:
		dialog_container.visible = false
	
	if main_node and main_node.has_method("mark_first_visit_complete"):
		main_node.mark_first_visit_complete()

func end_completion_dialog():
	print("🎉 Completion dialog ended")
	is_dialog_active = false
	is_completion_dialog = false
	if dialog_container:
		dialog_container.visible = false
	
	print("✨ Selamat! Petualangan di Nusantara telah selesai!")

func _on_island_hover(island_name: String, is_hovered: bool):
	if not is_dialog_active:
		var button_node = interactive_areas.get_node_or_null(island_name)
		if not button_node or not main_node:
			return
			
		var island_name_lower = island_name.to_lower()
		
		var unlocked_islands = []
		var completed_islands = []
		
		if main_node.has_method("get_player_data"):
			var player_data = main_node.get_player_data()
			if player_data:
				unlocked_islands = player_data.get("unlocked_islands", [])
				completed_islands = player_data.get("completed_islands", [])
		
		if island_name_lower in unlocked_islands:
			if is_hovered:
				if island_name_lower in completed_islands:
					button_node.modulate = Color(1, 0.95, 0.5, 1.0)
				else:
					button_node.modulate = Color(1, 1, 1, 1.0)
				print("🐭 Hover on:", island_name)
			else:
				if island_name_lower in completed_islands:
					button_node.modulate = Color(1, 0.84, 0, 0.8)
				else:
					button_node.modulate = Color(1, 1, 1, 0.8)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if is_dialog_active:
				_on_continue_pressed()
		elif event.keycode == KEY_ESCAPE:
			print("🔙 Returning to OpeningScene")
			return_to_opening_scene()

func print_scene_structure():
	print("=== MAP SCENE STRUCTURE ===")
	print_scene_tree_recursive(self, 0)

func print_scene_tree_recursive(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	var node_info = indent + "📁 " + node.name + " (" + node.get_class() + ")"
	
	if node is Control:
		node_info += " 📏 " + str(node.size)
	elif node is TextureRect:
		node_info += " 🖼️ " + ("Has Texture" if node.texture else "No Texture")
	elif node is Button:
		node_info += " 🔘 " + ("Enabled" if not node.disabled else "Disabled")
	elif node is TextureButton:
		node_info += " 🔘 " + ("Enabled" if not node.disabled else "Disabled")
	
	print(node_info)
	
	for child in node.get_children():
		print_scene_tree_recursive(child, depth + 1)

func refresh_map_data():
	print("🔄 Refreshing map data...")
	
	find_main_node()
	
	# Cek apakah semua pulau sudah selesai
	is_all_completed = check_all_islands_completed()
	
	update_islands_status()
	update_status_display()
	
	# Update UI penyelesaian
	setup_completion_ui()

func _exit_tree():
	print("🗺️ MapScene exiting...")

func _enter_tree():
	print("🗺️ MapScene entering tree...")
	call_deferred("refresh_map_data")
