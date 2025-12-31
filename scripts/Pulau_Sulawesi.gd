extends Control

var true_false_questions = [
	{
		"question": "Toraja adalah suku asli yang berasal dari Sulawesi Selatan.",
		"answer": true,
		"fact": "Benar! Suku Toraja adalah suku asli yang mendiami pegunungan Sulawesi Selatan, terkenal dengan rumah adat Tongkonan."
	},
	{
		"question": "Rumah Tongkonan hanya boleh dibangun oleh bangsawan.",
		"answer": true,
		"fact": "Benar! Tongkonan adalah rumah adat Toraja yang hanya boleh dimiliki dan dibangun oleh keluarga bangsawan (bangsawan Toraja)."
	},
	{
		"question": "Upacara Rambu Solo' adalah upacara kelahiran dalam adat Toraja.",
		"answer": false,
		"fact": "Salah! Rambu Solo' adalah upacara kematian (pemakaman) dalam adat Toraja, bukan upacara kelahiran."
	},
	{
		"question": "Tau-tau adalah patung kayu yang melambangkan leluhur dalam budaya Toraja.",
		"answer": true,
		"fact": "Benar! Tau-tau adalah patung kayu yang dibuat menyerupai orang yang telah meninggal, ditempatkan di tebing sebagai penjaga."
	},
	{
		"question": "Upacara Ma'nene dilakukan setiap 10 tahun sekali untuk membersihkan jasad leluhur.",
		"answer": true,
		"fact": "Benar! Ma'nene adalah ritual membersihkan dan mengganti pakaian jasad leluhur yang dilakukan secara berkala oleh keluarga."
	}
]

var current_question_index = 0
var score = 0
var timer_value = 10
var timer_running = false
var level_completed = false

@onready var header = $UI/Header as Label
@onready var question_text = $UI/QuestionContainer/QuestionText as Label
@onready var timer_bar = $UI/TimerBar as ProgressBar
@onready var timer_label = $UI/TimerLabel as Label
@onready var true_button = $UI/TrueButton as TextureButton
@onready var false_button = $UI/FalseButton as TextureButton
@onready var result_container = $UI/ResultContainer as Panel
@onready var result_text = $UI/ResultContainer/ResultText as Label
@onready var next_button = $UI/ResultContainer/NextButton as Button

func _ready():
	print("🏝️ Pulau Sulawesi Level 1 Loaded")
	
	# Cek jika level sudah completed
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			# Cek jika pulau Sulawesi sudah selesai
			if player_data.has("completed_islands") and "sulawesi" in player_data["completed_islands"]:
				print("🔄 Pulau Sulawesi sudah selesai, menunjukkan completion screen...")
				call_deferred("show_already_completed_screen")
				return
			# Cek hanya level 1 yang selesai
			elif player_data.has("completed_levels"):
				var level_key = "sulawesi_1"
				if player_data["completed_levels"].has(level_key) and player_data["completed_levels"][level_key]:
					print("🔄 Level 1 Sulawesi sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return
	
	# Lanjut dengan setup normal jika belum completed
	call_deferred("setup_ui_properties")
	call_deferred("initialize_level")

func setup_ui_properties():
	print("📝 Setting up UI properties...")
	
	if header:
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 28)
		print("✅ Header properties set")
	
	if question_text:
		question_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		question_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		question_text.add_theme_font_size_override("font_size", 22)
		print("✅ QuestionText properties set")
	
	if timer_bar:
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.2, 0.6, 0.8)  # Biru Sulawesi
		fill_style.corner_radius_top_left = 5
		fill_style.corner_radius_top_right = 5
		fill_style.corner_radius_bottom_right = 5
		fill_style.corner_radius_bottom_left = 5
		timer_bar.add_theme_stylebox_override("fill", fill_style)
		print("✅ TimerBar properties set")
	
	if timer_label:
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timer_label.add_theme_font_size_override("font_size", 16)
		print("✅ TimerLabel properties set")
	
	if result_container:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
		panel_style.border_color = Color(0.8, 0.6, 0.2)  # Emas
		panel_style.border_width_left = 3
		panel_style.border_width_top = 3
		panel_style.border_width_right = 3
		panel_style.border_width_bottom = 3
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.corner_radius_bottom_left = 15
		result_container.add_theme_stylebox_override("panel", panel_style)
		print("✅ ResultContainer properties set")
	
	if result_text:
		result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		result_text.add_theme_font_size_override("font_size", 16)
		result_text.clip_text = false
		print("✅ ResultText properties set")
	
	if next_button:
		next_button.add_theme_font_size_override("font_size", 14)
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.2, 0.6, 0.2)
		button_style.corner_radius_top_left = 8
		button_style.corner_radius_top_right = 8
		button_style.corner_radius_bottom_right = 8
		button_style.corner_radius_bottom_left = 8
		next_button.add_theme_stylebox_override("normal", button_style)
		print("✅ NextButton properties set")

func initialize_level():
	print("🔄 Initializing level...")
	setup_buttons()
	
	if result_container:
		result_container.visible = false
	if next_button:
		next_button.visible = false
	
	start_question(0)
	print("✅ Level 1 Sulawesi initialized")

func setup_buttons():
	print("🔗 Setting up buttons...")
	
	if true_button:
		true_button.pressed.connect(_on_answer_selected.bind(true))
		print("✅ TrueButton connected")
	if false_button:
		false_button.pressed.connect(_on_answer_selected.bind(false))
		print("✅ FalseButton connected")
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		print("✅ NextButton connected")
	
	print("✅ Buttons setup completed")

func start_question(question_index):
	print("🔍 Starting question ", question_index)
	
	if question_index < true_false_questions.size():
		current_question_index = question_index
		var question_data = true_false_questions[question_index]
		
		if question_text:
			question_text.text = question_data["question"]
			print("✅ Question text set: ", question_data["question"])
		
		if header:
			header.text = "PULAU SULAWESI - LEVEL 1\nPertanyaan " + str(question_index + 1) + "/" + str(true_false_questions.size())
			print("✅ Header text set")
		
		timer_value = 6
		if timer_bar:
			timer_bar.value = 100
		if timer_label:
			timer_label.text = str(timer_value) + "s"
		
		if true_button:
			true_button.disabled = false
		if false_button:
			false_button.disabled = false
		if result_container:
			result_container.visible = false
		if next_button:
			next_button.visible = false
		
		timer_running = true
		print("❓ Question ", question_index + 1, " started successfully")
	else:
		finish_level()

func _process(delta):
	if timer_running:
		timer_value -= delta
		if timer_bar:
			timer_bar.value = (timer_value / 6.0) * 100
			
			if timer_value < 2:
				var fill_style = timer_bar.get_theme_stylebox("fill").duplicate()
				fill_style.bg_color = Color.RED
				timer_bar.add_theme_stylebox_override("fill", fill_style)
			elif timer_value < 4:
				var fill_style = timer_bar.get_theme_stylebox("fill").duplicate()
				fill_style.bg_color = Color.YELLOW
				timer_bar.add_theme_stylebox_override("fill", fill_style)
		
		if timer_label:
			timer_label.text = str(ceil(timer_value)) + "s"
		
		if timer_value <= 0:
			timer_running = false
			on_timeout()

func on_timeout():
	print("⏰ Timeout!")
	
	if true_button:
		true_button.disabled = true
	if false_button:
		false_button.disabled = true
	
	var question_data = true_false_questions[current_question_index]
	if result_text:
		result_text.text = "Waktu habis!\nJawaban yang benar: " + ("BENAR" if question_data["answer"] else "SALAH")
		result_text.modulate = Color(1, 0.5, 0.5)
	if result_container:
		result_container.visible = true
	if next_button:
		next_button.visible = true

func _on_answer_selected(player_answer):
	if not timer_running:
		return
	
	timer_running = false
	
	var question_data = true_false_questions[current_question_index]
	var is_correct = (player_answer == question_data["answer"])
	
	if is_correct:
		score += 1
		print("✅ Correct answer! Score:", score)
	else:
		print("❌ Wrong answer! Score:", score)
	
	show_result(is_correct, question_data)

func show_result(is_correct, question_data):
	print("📊 Showing result...")
	
	if true_button:
		true_button.disabled = true
	if false_button:
		false_button.disabled = true
	
	var result_message = ""
	if is_correct:
		result_message = "✅ BENAR!\n"
		if result_text:
			result_text.modulate = Color(0.5, 1, 0.5)
	else:
		result_message = "❌ SALAH!\n"
		if result_text:
			result_text.modulate = Color(1, 0.5, 0.5)
	
	result_message += question_data["fact"]
	
	if result_text:
		result_text.text = result_message
	if result_container:
		result_container.visible = true
	if next_button:
		next_button.visible = true

func _on_next_pressed():
	print("➡️ Next button pressed")
	
	if next_button:
		next_button.visible = false
	if result_container:
		result_container.visible = false
	
	await get_tree().create_timer(0.3).timeout
	start_question(current_question_index + 1)

func finish_level():
	print("🎯 Level 1 completed! Final score:", score, "/", true_false_questions.size())
	
	# Hitung stars berdasarkan performance
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	# UPDATE PROGRESS KE MAIN SYSTEM
	save_progress(stars, knowledge_points)
	
	show_completion_screen(stars, knowledge_points)

func calculate_stars() -> int:
	var percentage = float(score) / true_false_questions.size()
	if percentage >= 0.8:    # 80% atau lebih
		return 3
	elif percentage >= 0.6:  # 60% atau lebih  
		return 2
	else:                    # Kurang dari 60%
		return 1

func calculate_knowledge_points() -> int:
	var base_points = score * 25  # 25 points per correct answer
	var efficiency_bonus = 0
	
	if score == true_false_questions.size():  # Semua benar
		efficiency_bonus = 50
	elif score >= true_false_questions.size() - 1:  # Hanya salah 1
		efficiency_bonus = 25
	
	return base_points + efficiency_bonus

func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving progress to Main system...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		var success = main.complete_level("sulawesi", 1, stars, knowledge_points)
		if success:
			print("✅ Progress saved successfully via Main system!")
			level_completed = true
		else:
			print("⚠️ Main system save failed, using manual save...")
			manual_save_progress(stars, knowledge_points)
	else:
		print("❌ Main node or complete_level method not found!")
		print("🔧 Using manual save as fallback...")
		manual_save_progress(stars, knowledge_points)

func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Attempting manual save for Sulawesi Level 1...")
	
	var save_path = "user://game_save.dat"
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var saved_data = file.get_var()
		file.close()
		
		if saved_data:
			# Initialize if not exists
			if not saved_data.has("completed_levels"):
				saved_data["completed_levels"] = {}
			if not saved_data.has("completed_islands"):
				saved_data["completed_islands"] = []
			if not saved_data.has("unlocked_islands"):
				saved_data["unlocked_islands"] = ["sumatra", "jawa", "kalimantan"]
			
			# Mark level 1 completed
			saved_data["completed_levels"]["sulawesi_1"] = true
			
			# Update total stars
			if saved_data.has("total_stars"):
				saved_data["total_stars"] += stars
			else:
				saved_data["total_stars"] = stars
			
			# Update knowledge points
			if saved_data.has("knowledge_points"):
				saved_data["knowledge_points"] += knowledge_points
			else:
				saved_data["knowledge_points"] = knowledge_points
			
			# Unlock next island (Papua) jika Sulawesi selesai
			var level2_completed = saved_data["completed_levels"].get("sulawesi_2", false)
			if saved_data["completed_levels"].get("sulawesi_1", false) and level2_completed:
				if "papua" not in saved_data["unlocked_islands"]:
					saved_data["unlocked_islands"].append("papua")
					print("🔓 Pulau Papua unlocked!")
			
			# Save back
			file = FileAccess.open(save_path, FileAccess.WRITE)
			if file:
				file.store_var(saved_data)
				file.close()
				level_completed = true
				print("✅ Manual save successful for Sulawesi Level 1!")
			else:
				print("❌ Manual save failed - cannot write file")
	else:
		print("❌ Manual save failed - no save file found")

func show_completion_screen(stars, knowledge_points):
	print("🏆 Showing completion screen with ", stars, " stars")
	
	if header:
		header.text = "PULAU SULAWESI - LEVEL 1 SELESAI!"
	if question_text:
		question_text.text = "🎉 SELAMAT! 🎉\n\n"
		question_text.text += "📊 Hasil Akhir:\n"
		question_text.text += "• Skor: " + str(score) + "/" + str(true_false_questions.size()) + "\n"
		question_text.text += "• ⭐ Bintang: " + str(stars) + "/3\n"
		question_text.text += "• 📚 Poin: +" + str(knowledge_points) + "\n\n"
		question_text.text += "💡 Budaya Toraja Sulawesi kaya akan tradisi unik\n"
		question_text.text += "seperti upacara Rambu Solo' dan rumah Tongkonan."
		question_text.add_theme_font_size_override("font_size", 18)
	
	if timer_bar:
		timer_bar.visible = false
	if timer_label:
		timer_label.visible = false
	if true_button:
		true_button.visible = false
	if false_button:
		false_button.visible = false
	
	if next_button:
		next_button.text = "Lanjut ke Level 2"
		next_button.visible = true
	if result_container:
		result_container.visible = true
		if result_text:
			result_text.text = "Tekan tombol untuk melanjutkan petualangan budaya Sulawesi!"
			result_text.add_theme_font_size_override("font_size", 16)
	
	if next_button:
		if next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.disconnect(_on_next_pressed)
		next_button.pressed.connect(_on_continue_to_level2)

func show_already_completed_screen():
	print("🔄 Showing already completed screen for Sulawesi Level 1")
	
	var main = get_node_or_null("/root/Main")
	var stars = 0
	var knowledge_points = 0
	var unlocked_islands = []
	
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			stars = player_data.get("total_stars", 0)
			knowledge_points = player_data.get("knowledge_points", 0)
			unlocked_islands = player_data.get("unlocked_islands", [])
			print("📊 Loaded progress - Stars:", stars, " Points:", knowledge_points)
	
	if header:
		header.text = "PULAU SULAWESI - LEVEL 1\nSUDAH SELESAI! 🎉"
	if question_text:
		question_text.text = "Kamu sudah menyelesaikan level ini!\n\n"
		question_text.text += "📊 Progress Saat Ini:\n"
		question_text.text += "⭐ Total Bintang: " + str(stars) + "\n"
		question_text.text += "📚 Total Poin: " + str(knowledge_points) + "\n\n"
		
		if "papua" in unlocked_islands:
			question_text.text += "🔓 Pulau Papua sudah terbuka!\n"
			question_text.text += "Kunjungi pulau terakhir untuk petualangan puncak!"
		else:
			question_text.text += "🔒 Lanjut ke Level 2 untuk membuka pulau berikutnya!"
		
		question_text.add_theme_font_size_override("font_size", 18)
	
	if timer_bar:
		timer_bar.visible = false
	if timer_label:
		timer_label.visible = false
	if true_button:
		true_button.visible = false
	if false_button:
		false_button.visible = false
	
	if next_button:
		next_button.text = "Lanjut ke Level 2"
		next_button.visible = true
	if result_container:
		result_container.visible = true
		if result_text:
			result_text.text = "Tekan tombol untuk melanjutkan ke Level 2 Sulawesi!"
	
	if next_button:
		if next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.disconnect(_on_next_pressed)
		next_button.pressed.connect(_on_continue_to_level2)

func _on_continue_to_level2():
	print("🚀 Continuing to Level 2 Sulawesi...")
	get_tree().change_scene_to_file("res://scenes/Level2_Sulawesi.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if next_button and next_button.visible:
				next_button.emit_signal("pressed")
		elif event.keycode == KEY_ESCAPE:
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				main.show_map()

func _exit_tree():
	print("🏝️ Pulau Sulawesi Level 1 exiting...")
