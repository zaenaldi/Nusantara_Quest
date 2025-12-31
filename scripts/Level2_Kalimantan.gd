extends Control

@onready var header = $UI/Header
@onready var puzzle_text = $UI/PuzzleText
@onready var options_container = $UI/OptionsContainer
@onready var result_container = $UI/ResultContainer
@onready var result_label = $UI/ResultContainer/ResultLabel
@onready var next_island_btn = $UI/NextIslandBtn
@onready var restart_btn = $UI/RestartBtn
@onready var hint_label = $UI/HintLabel

var logic_puzzles = {
	"urutan_adat": {
		"puzzle": "Dalam upacara Naik Dango (syukuran panen) Dayak Kanayatn:\n\n1. [   ?   ] - Persiapan sesajen\n2. [   ?   ] - Tari Balian\n3. [   ?   ] - Pembacaan mantra\n4. [   ?   ] - Makan bersama\n\nManakah urutan yang BENAR?",
		"options": [
			{"text": "Mantra → Sesajen → Tari → Makan", "correct": false, "explanation": "Salah, persiapan sesajen harus dilakukan sebelum mantra dibacakan."},
			{"text": "Sesajen → Mantra → Tari → Makan", "correct": false, "explanation": "Mendekati, tapi tari biasanya dilakukan setelah mantra untuk mengiringi doa."},
			{"text": "Sesajen → Tari → Mantra → Makan", "correct": true, "explanation": "TEPAT! Urutan benar: persiapan, tarian pemujaan, pembacaan mantra, kemudian makan bersama sebagai penutup."},
			{"text": "Tari → Sesajen → Makan → Mantra", "correct": false, "explanation": "Sangat salah, mantra harus dibaca sebelum makan bersama."}
		],
		"hint": "Pikirkan logika ritual: persiapan → pemujaan → doa → penutup.",
		"fact": "Upacara Naik Dango adalah wujud syukur atas hasil panen dan permohonan agar panen berikutnya lebih baik.",
		"explanation": "Urutan logis ritual: 1) Siapkan sesajen sebagai persembahan, 2) Tari Balian untuk memuja dewi padi, 3) Baca mantra untuk menguatkan doa, 4) Makan bersama sebagai simbol kebersamaan dan penutup ritual."
	}
}

var current_puzzle
var current_attempts = 0
var level_completed = false
var progress_saved = false

func _ready():
	print("🧩 Pulau Kalimantan Level 2 - Teka-teki Ritual Dayak Loaded")
	
	# 🎯 PERBAIKAN: Gunakan metode yang konsisten seperti pulau lain
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_island_progress"):
		var progress = main.get_island_progress("kalimantan")
		if progress and progress.get("level2_completed", false):
			print("🔄 Level 2 sudah selesai, menunjukkan completion screen...")
			call_deferred("show_already_completed_screen")
			return
	else:
		# Fallback untuk metode lama
		if main and main.has_method("get_player_data"):
			var player_data = main.get_player_data()
			if player_data:
				var level_key = "kalimantan_2"
				if player_data.has("completed_levels") and level_key in player_data["completed_levels"]:
					print("🔄 Level 2 Kalimantan sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return
	
	# Setup UI layout terlebih dahulu
	call_deferred("setup_ui_layout")
	
	# Initialize puzzle setelah layout setup
	call_deferred("initialize_puzzle")

func setup_ui_layout():
	print("📐 Setting up UI layout...")
	
	# Dapatkan ukuran viewport
	var viewport_size = get_viewport_rect().size
	print("🖥️ Viewport size: ", viewport_size)
	
	# ✅ PERBAIKAN LAYOUT: PuzzleText di kiri, OptionsContainer di kanan (sejajar)
	# PuzzleText: Posisi di kiri atas (setelah header)
	puzzle_text.position = Vector2(50, 130)
	puzzle_text.size = Vector2(500, 200)
	puzzle_text.custom_minimum_size = Vector2(500, 200)
	
	# ✅ OptionsContainer: Posisi di kanan, sejajar dengan PuzzleText
	options_container.position = Vector2(600, 130)  # Sejajar vertikal dengan PuzzleText
	options_container.size = Vector2(450, 260)
	options_container.custom_minimum_size = Vector2(450, 260)
	
	# ✅ ResultContainer: Posisi di bawah PuzzleText dan OptionsContainer
	result_container.position = Vector2(50, 350)  # Di bawah keduanya
	result_container.size = Vector2(1000, 250)   # Lebar untuk mencakup PuzzleText + OptionsContainer
	result_container.custom_minimum_size = Vector2(1000, 250)
	
	# ✅ ResultLabel: Di dalam ResultContainer dengan margin
	result_label.position = Vector2(20, 20)
	result_label.size = Vector2(960, 150)  # Lebih kecil untuk memberi ruang tombol
	result_label.custom_minimum_size = Vector2(960, 150)
	
	# ✅ Tombol: Posisi di bawah ResultContainer (atau di bawah ResultLabel)
	next_island_btn.position = Vector2(400, 610)  # Di bawah ResultContainer
	restart_btn.position = Vector2(600, 610)      # Di sebelah next_island_btn
	
	# Style untuk OptionsContainer
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.08, 0.06, 0.5)
	container_style.border_color = Color(0.8, 0.5, 0.2)
	container_style.border_width_left = 3
	container_style.border_width_top = 3
	container_style.border_width_right = 3
	container_style.border_width_bottom = 3
	container_style.corner_radius_top_left = 15
	container_style.corner_radius_top_right = 15
	container_style.corner_radius_bottom_right = 15
	container_style.corner_radius_bottom_left = 15
	options_container.add_theme_stylebox_override("panel", container_style)
	
	# Style untuk ResultContainer
	var result_style = StyleBoxFlat.new()
	result_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	result_style.border_color = Color(0.8, 0.6, 0.3)
	result_style.border_width_left = 4
	result_style.border_width_top = 4
	result_style.border_width_right = 4
	result_style.border_width_bottom = 4
	result_style.corner_radius_top_left = 20
	result_style.corner_radius_top_right = 20
	result_style.corner_radius_bottom_right = 20
	result_style.corner_radius_bottom_left = 20
	result_container.add_theme_stylebox_override("panel", result_style)
	
	# Konfigurasi ResultLabel agar teks tidak keluar
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.clip_text = true
	
	# Konfigurasi PuzzleText
	puzzle_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	print("✅ UI layout setup complete")

func initialize_puzzle():
	print("🎮 Initializing puzzle...")
	
	current_puzzle = logic_puzzles["urutan_adat"]
	current_attempts = 0
	
	# Setup UI text
	header.text = "PULAU KALIMANTAN - LEVEL 2\n"
	puzzle_text.text = current_puzzle["puzzle"]
	hint_label.text = "💡 " + current_puzzle["hint"]
	hint_label.position = Vector2(50, 340)  # Pindah hint ke bawah PuzzleText
	
	# Clear existing options
	for child in options_container.get_children():
		if child.name.begins_with("OptionButton_"):
			child.queue_free()
	
	# Create option buttons
	create_option_buttons()
	
	# Reset UI state
	result_container.visible = false
	next_island_btn.hide()
	restart_btn.hide()
	
	# Atur font size untuk ResultLabel agar sesuai
	result_label.add_theme_font_size_override("font_size", 18)
	
	print("🧠 Puzzle initialized - Upacara Naik Dango")

func create_option_buttons():
	print("🛠️ Creating option buttons...")
	
	var options = current_puzzle["options"].duplicate(true)
	
	# Ukuran button yang sesuai
	var button_width = 420
	var button_height = 50
	var vertical_spacing = 15
	var start_y = 15
	
	for i in range(len(options)):
		var option_data = options[i]
		
		# Create button
		var option_button = Button.new()
		option_button.name = "OptionButton_" + str(i)
		
		# Potong teks yang terlalu panjang
		var button_text = option_data["text"]
		if button_text.length() > 35:
			button_text = button_text.substr(0, 32) + "..."
		option_button.text = button_text
		
		# Set button size
		option_button.custom_minimum_size = Vector2(button_width, button_height)
		option_button.size = Vector2(button_width, button_height)
		
		# Set button position - center dalam container
		var button_x = (options_container.size.x - button_width) / 2
		var button_y = start_y + (i * (button_height + vertical_spacing))
		option_button.position = Vector2(button_x, button_y)
		
		# Configure button properties
		option_button.clip_text = true
		option_button.autowrap_mode = TextServer.AUTOWRAP_WORD
		option_button.focus_mode = Control.FOCUS_NONE
		
		# Store option data in metadata
		option_button.set_meta("option_data", option_data)
		
		# Apply button styles
		apply_button_styles(option_button)
		
		# Connect pressed signal
		option_button.pressed.connect(_on_option_button_pressed.bind(option_button))
		
		# Add button to container
		options_container.add_child(option_button)
		
		print("✅ Created button ", i, " with text: ", button_text)
	
	print("🎯 Total buttons created: ", len(options))

func apply_button_styles(button: Button):
	# Normal state style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.1, 0.08, 0.95)
	normal_style.border_color = Color(0.8, 0.5, 0.2)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.corner_radius_bottom_left = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover state style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.25, 0.2, 0.15, 1.0)
	hover_style.border_color = Color(0.9, 0.6, 0.3)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed state style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.35, 0.3, 0.25, 1.0)
	pressed_style.border_color = Color(1.0, 0.7, 0.4)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Disabled state style
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.1, 0.08, 0.06, 0.7)
	disabled_style.border_color = Color(0.4, 0.3, 0.2)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Font styling
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 0.8))
	button.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7))

func _on_option_button_pressed(option_button):
	if level_completed:
		return
	
	current_attempts += 1
	var option_data = option_button.get_meta("option_data")
	
	print("🟡 Option selected: ", option_button.text)
	print("📊 Is correct: ", option_data["correct"])
	print("📈 Attempt: ", current_attempts)
	
	# Disable all buttons temporarily
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true
	
	if option_data["correct"]:
		handle_correct_answer(option_button)
	else:
		handle_wrong_answer(option_button, option_data)

func handle_correct_answer(option_button):
	print("✅ Correct answer! Attempts: ", current_attempts)
	level_completed = true
	
	# Highlight correct button dengan warna hijau
	var correct_style = StyleBoxFlat.new()
	correct_style.bg_color = Color(0.1, 0.5, 0.1, 0.95)
	correct_style.border_color = Color(0.3, 0.8, 0.3)
	correct_style.border_width_left = 3
	correct_style.border_width_top = 3
	correct_style.border_width_right = 3
	correct_style.border_width_bottom = 3
	correct_style.corner_radius_top_left = 8
	correct_style.corner_radius_top_right = 8
	correct_style.corner_radius_bottom_right = 8
	correct_style.corner_radius_bottom_left = 8
	option_button.add_theme_stylebox_override("normal", correct_style)
	
	# Calculate rewards
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	# Save progress
	save_progress(stars, knowledge_points)
	
	# Show result after delay
	await get_tree().create_timer(1.0).timeout
	show_result_screen(stars, knowledge_points, true)

func handle_wrong_answer(option_button, option_data):
	print("❌ Wrong answer")
	
	# Highlight wrong button dengan warna merah
	var wrong_style = StyleBoxFlat.new()
	wrong_style.bg_color = Color(0.5, 0.1, 0.1, 0.95)
	wrong_style.border_color = Color(0.8, 0.3, 0.3)
	wrong_style.border_width_left = 3
	wrong_style.border_width_top = 3
	wrong_style.border_width_right = 3
	wrong_style.border_width_bottom = 3
	wrong_style.corner_radius_top_left = 8
	wrong_style.corner_radius_top_right = 8
	wrong_style.corner_radius_bottom_right = 8
	wrong_style.corner_radius_bottom_left = 8
	option_button.add_theme_stylebox_override("normal", wrong_style)
	
	# Show feedback - teks lebih singkat agar muat
	result_container.visible = true
	result_label.text = "❌ Belum tepat!\n\n"
	result_label.text += "Penjelasan: " + option_data["explanation"] + "\n\n"
	result_label.text += "Coba pilih jawaban lain!"
	result_label.modulate = Color(1, 0.7, 0.7)
	
	# Re-enable buttons after delay
	await get_tree().create_timer(2.5).timeout
	
	if not level_completed:
		# Update hint berdasarkan attempts
		update_hint_based_on_attempts()
		
		# Re-enable all buttons except the wrong one
		for child in options_container.get_children():
			if child is Button:
				if child != option_button:
					child.disabled = false
				else:
					# Keep wrong button disabled but change style
					child.disabled = true
					var disabled_wrong_style = wrong_style.duplicate()
					disabled_wrong_style.bg_color = Color(0.4, 0.1, 0.1, 0.7)
					child.add_theme_stylebox_override("normal", disabled_wrong_style)
		
		# Hide result
		result_container.visible = false

func update_hint_based_on_attempts():
	if current_attempts == 1:
		hint_label.text = "💡 Hint: Ingatlah bahwa sesajen harus disiapkan dulu sebelum ritual dimulai!"
	elif current_attempts == 2:
		hint_label.text = "💡 Hint: Tari biasanya mengiringi atau menguatkan doa/mantra yang dibacakan."
	elif current_attempts >= 3:
		hint_label.text = "💡 Hint: Makan bersama selalu menjadi penutup ritual sebagai simbol kebersamaan."

func calculate_stars() -> int:
	if current_attempts == 1:
		return 3
	elif current_attempts == 2:
		return 2
	else:
		return 1

func calculate_knowledge_points() -> int:
	var base_points = 80
	var efficiency_bonus = 0
	
	if current_attempts == 1:
		efficiency_bonus = 50
	elif current_attempts == 2:
		efficiency_bonus = 25
	elif current_attempts == 3:
		efficiency_bonus = 10
	
	return base_points + efficiency_bonus

# 🎯 PERBAIKAN: Fungsi save_progress yang konsisten dengan pulau lain
func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving Kalimantan Level 2 progress...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		print("✅ Using Main.complete_level()")
		var success = main.complete_level("kalimantan", 2, stars, knowledge_points)
		if success:
			progress_saved = true
			print("✅ Progress saved successfully via Main system!")
			print("   Island: kalimantan, Level: 2")
			print("   Stars:", stars, ", Knowledge Points:", knowledge_points)
		else:
			print("⚠️ Main system save failed, using manual save...")
			manual_save_progress(stars, knowledge_points)
	else:
		print("❌ Main.complete_level() not available")
		manual_save_progress(stars, knowledge_points)

# 🎯 PERBAIKAN: Manual save yang konsisten
func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Manual save for Kalimantan Level 2...")
	
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
		saved_data["unlocked_islands"] = ["sumatra", "jawa", "kalimantan"]
	if not saved_data.has("completed_islands"):
		saved_data["completed_islands"] = []
	
	# Mark level 2 as completed
	saved_data["completed_levels"]["kalimantan_2"] = true
	
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
	var level1_completed = saved_data["completed_levels"].get("kalimantan_1", false)
	var level2_completed = saved_data["completed_levels"].get("kalimantan_2", false)
	
	if level1_completed and level2_completed and "kalimantan" not in saved_data["completed_islands"]:
		saved_data["completed_islands"].append("kalimantan")
		print("✅ Pulau Kalimantan marked as completed")
	
	# Unlock next island if Kalimantan is completed
	if "kalimantan" in saved_data["completed_islands"] and "sulawesi" not in saved_data["unlocked_islands"]:
		saved_data["unlocked_islands"].append("sulawesi")
		print("🔓 Pulau Sulawesi unlocked!")
	
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
		# ✅ PERBAIKAN: Teks hasil yang lebih ringkas agar muat
		var result_text = "🎉 SELAMAT!\n\n"
		result_text += "Kamu berhasil memahami urutan ritual Naik Dango!\n\n"
		result_text += "📊 HASIL:\n"
		result_text += "• Percobaan: " + str(current_attempts) + " kali\n"
		result_text += "• ⭐ Bintang: " + str(stars) + "/3\n"
		result_text += "• 📚 Poin: +" + str(points) + "\n\n"
		result_text += "💡 FAKTA:\n" + current_puzzle["fact"] + "\n\n"
		
		# 🎯 PERBAIKAN: Ambil data dari Main system untuk informasi unlock
		var main = get_node_or_null("/root/Main")
		var unlocked_next = false
		
		if main and main.has_method("get_player_data"):
			var player_data = main.get_player_data()
			if player_data and player_data.has("unlocked_islands"):
				unlocked_next = "sulawesi" in player_data["unlocked_islands"]
		
		if progress_saved:
			result_text += "✅ Progress tersimpan!\n"
			if unlocked_next:
				result_text += "🔓 KUNCI DIPEROLEH!\n"
				result_text += "Pulau Sulawesi terbuka!"
			else:
				result_text += "Selesaikan level berikutnya!"
		else:
			result_text += "⚠️ Progress belum tersimpan!\n"
		
		result_label.text = result_text
		result_label.modulate = Color(0.5, 1, 0.5)
		
		# ✅ PERBAIKAN: Posisi tombol di bawah ResultContainer (atau di bawah ResultLabel)
		next_island_btn.position = Vector2(350, 610)  # Di bawah ResultContainer
		next_island_btn.text = "Kembali ke Peta"
		next_island_btn.show()
		
		# Tampilkan restart button juga untuk memberi pilihan
		restart_btn.position = Vector2(550, 610)      # Di sebelah next_island_btn
		restart_btn.text = "Main Lagi"
		restart_btn.show()
	else:
		result_label.text = "⏰ WAKTU HABIS!\nCoba lagi!"
		result_label.modulate = Color(1, 0.7, 0.7)
		restart_btn.position = Vector2(450, 610)
		restart_btn.show()

func _on_next_island_btn_pressed():
	# 🎯 PERBAIKAN: Kembali ke peta dengan metode yang sama seperti pulau lain
	print("🗺️ Returning to Map from Kalimantan Level 2...")
	print("🔍 Progress saved:", progress_saved)
	print("🔍 Level completed:", level_completed)
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("show_map"):
		print("✅ Using Main.show_map()")
		main.show_map()
	else:
		print("❌ Main.show_map() not available, using fallback")
		# Fallback: langsung ke MapScene
		get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _on_restart_btn_pressed():
	print("🔄 Restarting puzzle...")
	level_completed = false
	progress_saved = false
	result_container.visible = false
	next_island_btn.hide()
	restart_btn.hide()
	
	# Reset semua button
	for child in options_container.get_children():
		if child is Button:
			child.queue_free()
	
	initialize_puzzle()

# 🎯 PERBAIKAN: Fungsi untuk menunjukkan screen "sudah selesai"
func show_already_completed_screen():
	print("🔄 Showing already completed screen for Kalimantan Level 2")
	
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
	
	# Update UI
	header.text = "PULAU KALIMANTAN - LEVEL 2\nSUDAH SELESAI! 🎉"
	puzzle_text.text = "Kamu sudah menyelesaikan level ini!\n\nTebak urutan ritual Naik Dango (upacara syukuran panen Dayak)"
	hint_label.visible = false
	
	# Hide gameplay elements
	options_container.visible = false
	
	# Show result dengan teks yang lebih ringkas
	result_container.visible = true
	var result_text = "Level ini sudah selesai! 🎉\n\n"
	result_text += "📊 PROGRESS SAAT INI:\n"
	result_text += "⭐ Total Bintang: " + str(stars) + "\n"
	result_text += "📚 Total Poin: " + str(knowledge_points) + "\n\n"
	
	if "sulawesi" in unlocked_islands:
		result_text += "🔓 Pulau Sulawesi sudah terbuka!\n"
		result_text += "Kunjungi Pulau Sulawesi!"
	else:
		result_text += "🔒 Selesaikan level untuk membuka pulau berikutnya!"
	
	result_text += "\n\nTekan tombol untuk kembali ke peta"
	
	result_label.text = result_text
	result_label.modulate = Color.GOLD
	
	next_island_btn.position = Vector2(450, 610)
	next_island_btn.text = "Kembali ke Peta"
	next_island_btn.show()
	level_completed = true
	progress_saved = true

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("🔙 ESC pressed - returning to map")
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				main.show_map()
			else:
				get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
		elif event.keycode == KEY_ENTER and level_completed and next_island_btn.visible:
			print("🔑 ENTER pressed - continuing")
			_on_next_island_btn_pressed()

func _exit_tree():
	print("🧩 Pulau Kalimantan Level 2 exiting...")
	print("📊 Final State:")
	print("   Level completed:", level_completed)
	print("   Attempts:", current_attempts)
	print("   Progress saved:", progress_saved)
