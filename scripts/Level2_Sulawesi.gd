extends Control

@onready var header = $UI/Header
@onready var story_description = $UI/StoryDescription
@onready var sequence_container = $UI/SequenceContainer
@onready var image_container = $UI/ImageContainer
@onready var result_container = $UI/ResultContainer
@onready var result_label = $UI/ResultContainer/ResultLabel
@onready var next_island_btn = $UI/NextIslandBtn
@onready var restart_btn = $UI/RestartBtn

var culinary_stories = {
	"coto_makassar": {
		"description": "Coto Makassar adalah sup daging sapi khas Sulawesi Selatan yang kaya rempah.\nSusun gambar sesuai urutan pembuatan yang benar!",
		"steps": [
			{
				"image": "res://assets/images/puzzles/step1.png",
				"text": "Siapkan bahan utama: daging sapi, jeroan, dan rempah-rempah",
				"correct_pos": 0
			},
			{
				"image": "res://assets/images/puzzles/step2.png", 
				"text": "Rebus daging dan jeroan hingga empuk dalam air kaldu",
				"correct_pos": 1
			},
			{
				"image": "res://assets/images/puzzles/step3.png",
				"text": "Tumis bumbu halus (bawang, kemiri, ketumbar) hingga harum",
				"correct_pos": 2
			},
			{
				"image": "res://assets/images/puzzles/step4.png",
				"text": "Masukkan bumbu tumis ke dalam kaldu rebusan daging",
				"correct_pos": 3
			},
			{
				"image": "res://assets/images/puzzles/step5.png",
				"text": "Sajikan panas dengan ketupat dan taburan bawang goreng",
				"correct_pos": 4
			}
		],
		"fact": "Coto Makassar sudah ada sejak abad ke-16 dan merupakan warisan kuliner Kerajaan Gowa.",
		"explanation": "Urutan tepat: 1) Siapkan bahan, 2) Rebus daging, 3) Tumis bumbu, 4) Campur bumbu ke kaldu, 5) Sajikan."
	}
}

var current_story
var draggable_buttons = []
var sequence_slots = []
var slot_text_panels = []
var current_attempts = 0
var level_completed = false
var progress_saved = false

# 🆕 Reference ke Main node
var main_node = null

func _ready():
	print("🍲 Pulau Sulawesi Level 2 - Visual Storytelling Kuliner Loaded")
	
	# 🆕 Cari Main node jika belum di-inject
	if main_node == null:
		find_main_node()
	
	# Setup container styles terlebih dahulu
	setup_container_styles()
	
	# 🎯 Cek progress
	check_progress()
	
	if not level_completed:
		initialize_level()
	
	# Connect signals
	next_island_btn.pressed.connect(_on_next_island_btn_pressed)
	restart_btn.pressed.connect(_on_restart_btn_pressed)

# 🆕 Method untuk menerima Main reference dari Main.gd
func set_main_reference(main_reference):
	print("🎮 Main reference received by Level2_Sulawesi")
	main_node = main_reference

# 🆕 Cari Main node secara agresif
func find_main_node():
	print("🔍 Searching for Main node...")
	
	# Method 1: Coba langsung dari root
	main_node = get_node_or_null("/root/Main")
	if main_node:
		print("✅ Main found at /root/Main")
		return
	
	# Method 2: Cari di parent chain
	var parent = get_parent()
	while parent:
		if parent.name == "Main" or parent.has_method("get_player_data"):
			main_node = parent
			print("✅ Main found in parent chain:", parent.name)
			return
		parent = parent.get_parent()
	
	# Method 3: Cari di scene tree
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "Main" or child.has_method("complete_level"):
			main_node = child
			print("✅ Main found as root child:", child.name)
			return
	
	print("❌ Main node not found")

func check_progress():
	print("🔍 Checking existing progress...")
	
	if main_node and main_node.has_method("get_player_data"):
		var player_data = main_node.get_player_data()
		if player_data and player_data.has("completed_levels"):
			var level_key = "sulawesi_2"
			if player_data["completed_levels"].get(level_key, false):
				print("🔄 Level 2 sudah selesai, menunjukkan completion screen...")
				call_deferred("show_already_completed_screen")
				return
	
	# Fallback: cek file save langsung
	var save_path = "user://nusantara_quest_save.dat"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var saved_data = file.get_var()
			file.close()
			if saved_data and saved_data.has("player_data"):
				var player_data = saved_data["player_data"]
				if player_data.has("completed_levels") and player_data["completed_levels"].get("sulawesi_2", false):
					print("🔄 Level 2 sudah selesai (from save file)...")
					call_deferred("show_already_completed_screen")
					return

func setup_container_styles():
	# Setup background style untuk sequence container
	var sequence_bg_style = StyleBoxFlat.new()
	sequence_bg_style.bg_color = Color(0.08, 0.06, 0.04, 0.7)
	sequence_bg_style.border_color = Color(0.8, 0.6, 0.3, 0.8)
	sequence_bg_style.border_width_left = 2
	sequence_bg_style.border_width_top = 2
	sequence_bg_style.border_width_right = 2
	sequence_bg_style.border_width_bottom = 2
	sequence_bg_style.corner_radius_top_left = 10
	sequence_bg_style.corner_radius_top_right = 10
	sequence_bg_style.corner_radius_bottom_right = 10
	sequence_bg_style.corner_radius_bottom_left = 10
	sequence_container.add_theme_stylebox_override("panel", sequence_bg_style)
	
	# Setup background style untuk image container
	var image_bg_style = StyleBoxFlat.new()
	image_bg_style.bg_color = Color(0.08, 0.06, 0.04, 0.7)
	image_bg_style.border_color = Color(0.8, 0.6, 0.3, 0.8)
	image_bg_style.border_width_left = 2
	image_bg_style.border_width_top = 2
	image_bg_style.border_width_right = 2
	image_bg_style.border_width_bottom = 2
	image_bg_style.corner_radius_top_left = 10
	image_bg_style.corner_radius_top_right = 10
	image_bg_style.corner_radius_bottom_right = 10
	image_bg_style.corner_radius_bottom_left = 10
	image_container.add_theme_stylebox_override("panel", image_bg_style)
	
	# Setup background style untuk result container
	var result_bg_style = StyleBoxFlat.new()
	result_bg_style.bg_color = Color(0.05, 0.04, 0.03, 0.95)
	result_bg_style.border_color = Color(1, 0.8, 0.4, 0.9)
	result_bg_style.border_width_left = 3
	result_bg_style.border_width_top = 3
	result_bg_style.border_width_right = 3
	result_bg_style.border_width_bottom = 3
	result_bg_style.corner_radius_top_left = 12
	result_bg_style.corner_radius_top_right = 12
	result_bg_style.corner_radius_bottom_right = 12
	result_bg_style.corner_radius_bottom_left = 12
	result_container.add_theme_stylebox_override("panel", result_bg_style)

func initialize_level():
	print("🎮 Initializing level...")
	
	current_story = culinary_stories["coto_makassar"]
	current_attempts = 0
	
	# Setup UI
	header.text = "PULAU SULAWESI - LEVEL 2"
	story_description.text = current_story["description"]
	
	# Clear containers
	for child in image_container.get_children():
		if child.name != "ResultLabel":
			child.queue_free()
	
	# Clear sequence container secara manual
	for child in sequence_container.get_children():
		child.queue_free()
	
	draggable_buttons.clear()
	sequence_slots.clear()
	slot_text_panels.clear()
	
	# Create sequence slots
	create_sequence_slots()
	
	# Create draggable buttons (shuffled)
	create_draggable_buttons()
	
	# Reset UI state
	result_container.visible = false
	next_island_btn.hide()
	restart_btn.hide()
	
	print("🍽️ Level initialized - Story: Coto Makassar")

func create_sequence_slots():
	var slot_height = 60
	var slot_spacing = 6
	
	# Setup VBoxContainer untuk sequence slots dengan properti yang benar
	var vbox = VBoxContainer.new()
	vbox.name = "SequenceVBox"
	vbox.custom_minimum_size = Vector2(350, slot_height * len(current_story["steps"]) + slot_spacing * (len(current_story["steps"]) - 1))
	vbox.size = vbox.custom_minimum_size
	
	# Setup VBoxContainer alignment
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", slot_spacing)
	
	# Center VBox dalam sequence container
	vbox.position = Vector2(
		(sequence_container.size.x - vbox.size.x) / 2,
		8
	)
	
	sequence_container.add_child(vbox)
	
	for i in range(len(current_story["steps"])):
		# Container utama untuk slot
		var slot_container = HBoxContainer.new()
		slot_container.name = "SlotContainer_%d" % i
		slot_container.custom_minimum_size = Vector2(320, slot_height)
		slot_container.size = Vector2(320, slot_height)
		slot_container.add_theme_constant_override("separation", 6)
		
		# Slot untuk gambar (panel dengan background)
		var slot_panel = Panel.new()
		slot_panel.name = "SlotPanel_%d" % i
		slot_panel.custom_minimum_size = Vector2(slot_height, slot_height)
		slot_panel.size = Vector2(slot_height, slot_height)
		
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.15, 0.12, 0.08, 0.9)
		slot_style.border_color = Color(0.8, 0.6, 0.2)
		slot_style.border_width_left = 2
		slot_style.border_width_top = 2
		slot_style.border_width_right = 2
		slot_style.border_width_bottom = 2
		slot_style.corner_radius_top_left = 5
		slot_style.corner_radius_top_right = 5
		slot_style.corner_radius_bottom_right = 5
		slot_style.corner_radius_bottom_left = 5
		slot_panel.add_theme_stylebox_override("panel", slot_style)
		
		# Number label
		var number_label = Label.new()
		number_label.name = "NumberLabel"
		number_label.text = str(i + 1) + "."
		number_label.add_theme_font_size_override("font_size", 14)
		number_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		number_label.position = Vector2(5, (slot_height - 18) / 2)
		number_label.size = Vector2(20, 18)
		slot_panel.add_child(number_label)
		
		# Panel untuk text description
		var text_panel = Panel.new()
		text_panel.name = "TextPanel_%d" % i
		text_panel.custom_minimum_size = Vector2(320 - slot_height - 6, slot_height)
		text_panel.size = text_panel.custom_minimum_size
		
		var text_style = StyleBoxFlat.new()
		text_style.bg_color = Color(0.12, 0.09, 0.06, 0.8)
		text_style.border_color = Color(0.6, 0.4, 0.1)
		text_style.border_width_left = 1
		text_style.border_width_top = 1
		text_style.border_width_right = 1
		text_style.border_width_bottom = 1
		text_style.corner_radius_top_left = 5
		text_style.corner_radius_top_right = 5
		text_style.corner_radius_bottom_right = 5
		text_style.corner_radius_bottom_left = 5
		text_panel.add_theme_stylebox_override("panel", text_style)
		
		# Placeholder text label
		var placeholder_label = Label.new()
		placeholder_label.name = "PlaceholderText"
		placeholder_label.text = "Langkah " + str(i + 1) + " - Pilih gambar"
		placeholder_label.add_theme_font_size_override("font_size", 11)
		placeholder_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
		placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder_label.size = text_panel.size - Vector2(6, 6)
		placeholder_label.position = Vector2(6, 3)
		placeholder_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_panel.add_child(placeholder_label)
		
		slot_container.add_child(slot_panel)
		slot_container.add_child(text_panel)
		vbox.add_child(slot_container)
		
		# Simpan references
		sequence_slots.append(slot_panel)
		slot_text_panels.append(text_panel)
	
	# Center VBox setelah semua slot dibuat
	call_deferred("center_sequence_vbox")

func center_sequence_vbox():
	var vbox = sequence_container.get_node("SequenceVBox")
	if vbox:
		vbox.position = Vector2(
			(sequence_container.size.x - vbox.size.x) / 2,
			8
		)

func create_draggable_buttons():
	var steps = current_story["steps"].duplicate(true)
	steps.shuffle()
	
	var button_size = 85
	var grid_cols = 2
	var spacing = 12
	var container_width = button_size + 12
	var container_height = button_size + 35
	
	# Hitung start position untuk centering
	var total_width = grid_cols * container_width + (grid_cols - 1) * spacing
	var start_x = (image_container.size.x - total_width) / 2
	var start_y = 12
	
	for i in range(len(steps)):
		var step_data = steps[i]
		
		# Container untuk button + text
		var container = Panel.new()
		container.name = "ImageContainer_%d" % i
		container.custom_minimum_size = Vector2(container_width, container_height)
		container.size = Vector2(container_width, container_height)
		
		var container_style = StyleBoxFlat.new()
		container_style.bg_color = Color(0.12, 0.09, 0.06, 0.85)
		container_style.border_color = Color(0.8, 0.6, 0.3)
		container_style.border_width_left = 2
		container_style.border_width_top = 2
		container_style.border_width_right = 2
		container_style.border_width_bottom = 2
		container_style.corner_radius_top_left = 7
		container_style.corner_radius_top_right = 7
		container_style.corner_radius_bottom_right = 7
		container_style.corner_radius_bottom_left = 7
		container.add_theme_stylebox_override("panel", container_style)
		
		# Create button
		var button = Button.new()
		button.name = "Button_%d" % i
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		
		# Set icon
		var image_texture = load(step_data["image"])
		if image_texture:
			button.icon = image_texture
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.expand_icon = true
			button.custom_minimum_size = Vector2(button_size * 0.8, button_size * 0.8)
			button.icon = image_texture
			button.expand_icon = true
		else:
			print("⚠️ Could not load image: ", step_data["image"])
			button.text = "Step " + str(i+1)
		
		# Set button size dan posisi
		button.custom_minimum_size = Vector2(button_size, button_size)
		button.size = Vector2(button_size, button_size)
		button.position = Vector2(6, 6)
		
		# Store step data
		button.set_meta("step_data", step_data)
		button.set_meta("step_text", step_data["text"])
		
		# Button style
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.2, 0.16, 0.12, 1.0)
		button_style.border_color = Color(0.9, 0.7, 0.4)
		button_style.border_width_left = 2
		button_style.border_width_top = 2
		button_style.border_width_right = 2
		button_style.border_width_bottom = 2
		button_style.corner_radius_top_left = 4
		button_style.corner_radius_top_right = 4
		button_style.corner_radius_bottom_right = 4
		button_style.corner_radius_bottom_left = 4
		button.add_theme_stylebox_override("normal", button_style)
		
		# Hover style
		var hover_style = button_style.duplicate()
		hover_style.bg_color = Color(0.25, 0.2, 0.15, 1.0)
		hover_style.border_color = Color(1.0, 0.8, 0.5)
		button.add_theme_stylebox_override("hover", hover_style)
		
		# Pressed style
		var pressed_style = button_style.duplicate()
		pressed_style.bg_color = Color(0.3, 0.24, 0.18, 1.0)
		pressed_style.border_color = Color(1.0, 0.9, 0.6)
		button.add_theme_stylebox_override("pressed", pressed_style)
		
		# Connect signal
		button.pressed.connect(_on_image_button_pressed.bind(button, container))
		
		# Text label
		var text_label = Label.new()
		text_label.name = "StepText"
		text_label.text = step_data["text"]
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.custom_minimum_size = Vector2(button_size, 28)
		text_label.size = Vector2(button_size, 28)
		text_label.position = Vector2(6, button_size + 8)
		text_label.add_theme_font_size_override("font_size", 9)
		text_label.add_theme_color_override("font_color", Color(1, 1, 0.95))
		text_label.clip_text = true
		
		container.add_child(button)
		container.add_child(text_label)
		
		# Calculate grid position
		var col = i % grid_cols
		var row = i / grid_cols
		var pos_x = start_x + col * (container_width + spacing)
		var pos_y = start_y + row * (container_height + spacing)
		container.position = Vector2(pos_x, pos_y)
		
		image_container.add_child(container)
		draggable_buttons.append(button)
	
	print("🎨 Created draggable buttons: ", len(draggable_buttons))

func _on_image_button_pressed(button, container):
	if level_completed:
		return
	
	print("🟡 Button pressed")
	
	# Find first empty slot
	var empty_slot_index = -1
	for i in range(len(sequence_slots)):
		var slot = sequence_slots[i]
		if slot.get_child_count() <= 1:  # Hanya ada number label
			empty_slot_index = i
			break
	
	if empty_slot_index != -1:
		move_button_to_slot(button, container, empty_slot_index)
		check_sequence_completion()
	else:
		print("⚠️ No empty slots available")

func move_button_to_slot(button, container, slot_index):
	var slot = sequence_slots[slot_index]
	
	# Hapus button dari container lama
	container.remove_child(button)
	
	# Dapatkan text
	var step_text = button.get_meta("step_text", "")
	
	# Hapus container lama
	image_container.remove_child(container)
	container.queue_free()
	
	# Update button untuk slot
	button.custom_minimum_size = Vector2(50, 50)
	button.size = Vector2(50, 50)
	button.position = Vector2(6, 6)
	button.disabled = true
	
	# Tambahkan ke slot
	slot.add_child(button)
	
	# Update text di panel sebelah
	var text_panel = slot_text_panels[slot_index]
	var placeholder_label = text_panel.get_node("PlaceholderText")
	if placeholder_label:
		placeholder_label.text = step_text
		placeholder_label.add_theme_font_size_override("font_size", 10)
		placeholder_label.add_theme_color_override("font_color", Color.WHITE)
	
	print("📌 Button placed in slot ", slot_index + 1)

func check_sequence_completion():
	var all_filled = true
	for slot in sequence_slots:
		if slot.get_child_count() <= 1:
			all_filled = false
			break
	
	if all_filled:
		current_attempts += 1
		validate_sequence()

func validate_sequence():
	print("🔍 Validating sequence...")
	
	var correct_count = 0
	var total_steps = len(current_story["steps"])
	
	for i in range(len(sequence_slots)):
		var slot = sequence_slots[i]
		if slot.get_child_count() > 1:
			var button = slot.get_child(1) as Button
			var step_data = button.get_meta("step_data")
			
			if step_data["correct_pos"] == i:
				correct_count += 1
				highlight_button(button, true)
			else:
				highlight_button(button, false)
	
	if correct_count == total_steps:
		handle_correct_sequence()
	else:
		handle_wrong_sequence(correct_count, total_steps)

func highlight_button(button: Button, is_correct: bool):
	var highlight_style = StyleBoxFlat.new()
	
	if is_correct:
		highlight_style.bg_color = Color(0.1, 0.5, 0.1, 0.9)
		highlight_style.border_color = Color(0.4, 0.9, 0.4)
	else:
		highlight_style.bg_color = Color(0.5, 0.1, 0.1, 0.9)
		highlight_style.border_color = Color(0.9, 0.4, 0.4)
	
	highlight_style.border_width_left = 2
	highlight_style.border_width_top = 2
	highlight_style.border_width_right = 2
	highlight_style.border_width_bottom = 2
	highlight_style.corner_radius_top_left = 4
	highlight_style.corner_radius_top_right = 4
	highlight_style.corner_radius_bottom_right = 4
	highlight_style.corner_radius_bottom_left = 4
	
	button.add_theme_stylebox_override("normal", highlight_style)

func handle_correct_sequence():
	print("✅ Sequence correct! Attempts: ", current_attempts)
	level_completed = true
	
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	save_progress(stars, knowledge_points)
	
	await get_tree().create_timer(1.0).timeout
	show_result_screen(stars, knowledge_points, true)

func handle_wrong_sequence(correct_count: int, total_steps: int):
	print("❌ Sequence wrong: ", correct_count, "/", total_steps)
	
	result_container.visible = true
	result_label.text = "❌ Belum tepat!\n"
	result_label.text += "Kamu mendapatkan " + str(correct_count) + " dari " + str(total_steps) + " langkah benar.\n"
	result_label.text += "Coba susun ulang dengan logika memasak yang benar!"
	result_label.modulate = Color(1, 0.7, 0.7)
	
	await get_tree().create_timer(3.0).timeout
	if not level_completed:
		reset_sequence()

func reset_sequence():
	print("🔄 Resetting sequence...")
	
	# Clear image container
	for child in image_container.get_children():
		if child.name.begins_with("ImageContainer_"):
			child.queue_free()
	
	# Reset slots
	for i in range(len(sequence_slots)):
		var slot = sequence_slots[i]
		while slot.get_child_count() > 1:
			var child = slot.get_child(1)
			slot.remove_child(child)
			child.queue_free()
		
		# Reset placeholder text
		var text_panel = slot_text_panels[i]
		var placeholder_label = text_panel.get_node("PlaceholderText")
		if placeholder_label:
			placeholder_label.text = "Langkah " + str(i + 1) + " - Pilih gambar"
			placeholder_label.add_theme_font_size_override("font_size", 11)
			placeholder_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	
	# Recreate draggable buttons
	draggable_buttons.clear()
	create_draggable_buttons()
	
	result_container.visible = false

func calculate_stars() -> int:
	if current_attempts == 1:
		return 3
	elif current_attempts == 2:
		return 2
	else:
		return 1

func calculate_knowledge_points() -> int:
	var base_points = 100
	var efficiency_bonus = 0
	
	if current_attempts == 1:
		efficiency_bonus = 60
	elif current_attempts == 2:
		efficiency_bonus = 30
	elif current_attempts == 3:
		efficiency_bonus = 15
	
	return base_points + efficiency_bonus

func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving Sulawesi Level 2 progress...")
	
	# 🎯 PRIORITAS 1: Gunakan Main node jika ada
	if main_node and main_node.has_method("complete_level"):
		print("✅ Using Main.complete_level()")
		var success = main_node.complete_level("sulawesi", 2, stars, knowledge_points)
		if success:
			progress_saved = true
			print("✅ Progress saved successfully via Main system!")
			return
	
	# 🎯 PRIORITAS 2: Manual save
	print("⚠️ Using manual save...")
	manual_save_progress(stars, knowledge_points)

func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Manual save for Sulawesi Level 2...")
	
	var save_path = "user://nusantara_quest_save.dat"
	var file = FileAccess.open(save_path, FileAccess.READ)
	
	var saved_data = {}
	if file:
		saved_data = file.get_var()
		file.close()
	
	# Initialize data structure
	if not saved_data:
		saved_data = {}
	if not saved_data.has("player_data"):
		saved_data["player_data"] = {}
	if not saved_data["player_data"].has("completed_levels"):
		saved_data["player_data"]["completed_levels"] = {}
	if not saved_data["player_data"].has("unlocked_islands"):
		saved_data["player_data"]["unlocked_islands"] = ["sumatra", "jawa", "kalimantan", "sulawesi"]
	if not saved_data["player_data"].has("completed_islands"):
		saved_data["player_data"]["completed_islands"] = []
	
	# Mark level 2 as completed
	saved_data["player_data"]["completed_levels"]["sulawesi_2"] = true
	
	# Update stars
	if saved_data["player_data"].has("total_stars"):
		saved_data["player_data"]["total_stars"] += stars
	else:
		saved_data["player_data"]["total_stars"] = stars
	
	# Update knowledge points
	if saved_data["player_data"].has("knowledge_points"):
		saved_data["player_data"]["knowledge_points"] += knowledge_points
	else:
		saved_data["player_data"]["knowledge_points"] = knowledge_points
	
	# Check if entire island is completed
	var level1_completed = saved_data["player_data"]["completed_levels"].get("sulawesi_1", false)
	var level2_completed = saved_data["player_data"]["completed_levels"].get("sulawesi_2", false)
	
	if level1_completed and level2_completed and "sulawesi" not in saved_data["player_data"]["completed_islands"]:
		saved_data["player_data"]["completed_islands"].append("sulawesi")
		print("✅ Pulau Sulawesi marked as completed")
	
	# Unlock next island if Sulawesi is completed
	if "sulawesi" in saved_data["player_data"]["completed_islands"] and "papua" not in saved_data["player_data"]["unlocked_islands"]:
		saved_data["player_data"]["unlocked_islands"].append("papua")
		print("🔓 Pulau Papua unlocked!")
	
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

func show_result_screen(stars: int, points: int, is_success: bool):
	result_container.visible = true
	
	if is_success:
		var result_text = "🎉 SELAMAT! 🎉\n"
		result_text += "Kamu berhasil menyusun alur pembuatan Coto Makassar!\n\n"
		result_text += "📊 HASIL:\n"
		result_text += "• Percobaan: " + str(current_attempts) + " kali\n"
		result_text += "• ⭐ Bintang: " + str(stars) + "/3\n"
		result_text += "• 📚 Poin: +" + str(points) + "\n\n"
		result_text += "💡 FAKTA: " + current_story["fact"] + "\n\n"
		
		# Cek apakah Papua sudah terbuka
		var unlocked_papua = false
		if main_node and main_node.has_method("get_player_data"):
			var player_data = main_node.get_player_data()
			if player_data and player_data.has("unlocked_islands"):
				unlocked_papua = "papua" in player_data["unlocked_islands"]
		
		if progress_saved:
			result_text += "✅ Progress tersimpan!\n"
			if unlocked_papua:
				result_text += "🔓 KUNCI DIPEROLEH!\n"
				result_text += "Pulau Papua terbuka!"
			else:
				result_text += "Selesaikan level berikutnya!"
		else:
			result_text += "⚠️ Progress belum tersimpan!\n"
		
		result_label.text = result_text
		result_label.add_theme_font_size_override("font_size", 12)
		result_label.modulate = Color(0.7, 1, 0.7)
		
		next_island_btn.text = "Kembali ke Peta"
		next_island_btn.show()
		
		restart_btn.text = "Main Lagi"
		restart_btn.show()
	else:
		result_label.text = "⏰ WAKTU HABIS!\nCoba lagi!"
		result_label.modulate = Color(1, 0.7, 0.7)
		restart_btn.show()

# 🎯 PERBAIKAN UTAMA: Fungsi kembali ke peta yang lebih stabil
func _on_next_island_btn_pressed():
	print("🗺️ _on_next_island_btn_pressed() - Returning to Map")
	print("📊 Progress saved:", progress_saved)
	print("📊 Level completed:", level_completed)
	
	# 🚨 CRITICAL: Nonaktifkan button untuk mencegah double click
	next_island_btn.disabled = true
	restart_btn.disabled = true
	
	# 🎯 OPTION 1: Gunakan change_scene_to_file - PALING STABIL
	print("🔄 Using get_tree().change_scene_to_file()")
	
	# Pastikan progress tersimpan
	if not progress_saved and level_completed:
		var stars = calculate_stars()
		var knowledge_points = calculate_knowledge_points()
		manual_save_progress(stars, knowledge_points)
	
	# Delay kecil untuk memastikan save selesai
	await get_tree().create_timer(0.1).timeout
	
	# Direct scene transition - metode paling reliable
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _on_restart_btn_pressed():
	print("🔄 Restarting level...")
	level_completed = false
	progress_saved = false
	result_container.visible = false
	next_island_btn.hide()
	restart_btn.hide()
	
	# Cleanup
	cleanup_before_exit()
	
	# Reinitialize
	initialize_level()

func show_already_completed_screen():
	print("🔄 Showing already completed screen for Sulawesi Level 2")
	
	# Ambil data
	var stars = 0
	var knowledge_points = 0
	var unlocked_islands = []
	var completed_islands = []
	
	if main_node and main_node.has_method("get_player_data"):
		var player_data = main_node.get_player_data()
		if player_data:
			stars = player_data.get("total_stars", 0)
			knowledge_points = player_data.get("knowledge_points", 0)
			unlocked_islands = player_data.get("unlocked_islands", [])
			completed_islands = player_data.get("completed_islands", [])
	
	# Update UI
	header.text = "PULAU SULAWESI - LEVEL 2\nSUDAH SELESAI! 🎉"
	story_description.text = "Kamu sudah menyelesaikan level ini!\n\nVisual Storytelling: Alur Pembuatan Coto Makassar"
	
	# Nonaktifkan gameplay
	sequence_container.visible = false
	image_container.visible = false
	
	# Show result
	result_container.visible = true
	var result_text = "Level ini sudah selesai! 🎉\n\n"
	result_text += "📊 PROGRESS SAAT INI:\n"
	result_text += "⭐ Total Bintang: " + str(stars) + "\n"
	result_text += "📚 Total Poin: " + str(knowledge_points) + "\n\n"
	
	if "papua" in unlocked_islands:
		result_text += "🔓 Pulau Papua sudah terbuka!\n"
		result_text += "Kunjungi Pulau Papua untuk petualangan terakhir!"
	else:
		result_text += "🔒 Selesaikan level untuk membuka pulau berikutnya!"
	
	result_text += "\n\nTekan tombol untuk kembali ke peta"
	
	result_label.text = result_text
	result_label.modulate = Color(1, 0.85, 0.3)
	
	next_island_btn.text = "Kembali ke Peta"
	next_island_btn.show()
	
	level_completed = true
	progress_saved = true

# 🆕 Cleanup function untuk scene management
func cleanup_before_exit():
	print("🧹 cleanup_before_exit() called")
	
	# Clear semua arrays dan references
	draggable_buttons.clear()
	sequence_slots.clear()
	slot_text_panels.clear()
	current_story = null
	main_node = null
	
	# Disconnect signals
	if next_island_btn and next_island_btn.pressed.is_connected(_on_next_island_btn_pressed):
		next_island_btn.pressed.disconnect(_on_next_island_btn_pressed)
	if restart_btn and restart_btn.pressed.is_connected(_on_restart_btn_pressed):
		restart_btn.pressed.disconnect(_on_restart_btn_pressed)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("🔙 ESC pressed - returning to map")
			_on_next_island_btn_pressed()
		elif event.keycode == KEY_ENTER and level_completed and next_island_btn.visible:
			print("🔑 ENTER pressed - continuing")
			_on_next_island_btn_pressed()

func _exit_tree():
	print("🍲 Pulau Sulawesi Level 2 exiting...")
	print("📊 Final State:")
	print("   Level completed:", level_completed)
	print("   Attempts:", current_attempts)
	print("   Progress saved:", progress_saved)
	print("   Main node available:", main_node != null)