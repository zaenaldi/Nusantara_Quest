extends Node2D

# Path yang BENAR untuk struktur Anda
@onready var audio_player = $AudioStreamPlayer
@onready var play_button = $UI/AudioContainer/PlayButton
@onready var progress_bar = $UI/AudioContainer/ProgressBar
@onready var wave_animation = $UI/AudioContainer/WaveAnimation
@onready var answer_grid = $UI/AnswerGrid
@onready var next_level_btn = $UI/NextLevelBtn
@onready var header = $UI/Header
@onready var result_container = $UI/ResultContainer
@onready var result_label = $UI/ResultContainer/ResultText

var current_instrument_data: Dictionary
var is_playing = false
var audio_length = 0.0
var audio_position = 0.0
var level_completed = false
var attempts_count = 0  # Menghitung berapa kali mencoba
var progress_saved = false  # 🎯 Flag untuk cek progress sudah disimpan
var current_question_index = 0  # Untuk melacak soal ke berapa
var total_questions = 2  # Total 2 soal
var correct_answers = 0  # Jumlah jawaban benar

# Data alat musik tradisional Papua
var papua_instruments = [
	{
		"audio": "res://assets/audio/tifa.mp3",
		"correct_answer": "Tifa",
		"description": "Tifa adalah alat musik tradisional Papua berbentuk tabung yang dimainkan dengan cara dipukul. Terbuat dari kayu yang dilubangi tengahnya dan ditutup kulit hewan. Tifa memiliki peran penting dalam upacara adat, tarian perang, dan penyambutan tamu.",
		"duration": 20.0,
		"instrument_name": "Tifa",
		"fact": "Setiap suku di Papua memiliki motif ukiran yang berbeda pada Tifa, menunjukkan identitas sukunya!"
	},
	{
		"audio": "res://assets/audio/fuu.mp3", 
		"correct_answer": "Fuu (Suling Papua)",
		"description": "Fuu adalah alat musik tiup tradisional Papua yang terbuat dari bambu. Memiliki suara yang khas dan biasanya dimainkan untuk mengiringi tarian atau sebagai sarana komunikasi jarak jauh antar desa.",
		"duration": 18.0,
		"instrument_name": "Fuu (Suling Papua)",
		"fact": "Fuu bisa menghasilkan nada-nada khusus yang hanya dimengerti oleh anggota suku tertentu!"
	}
]

# Pilihan jawaban untuk setiap alat musik
var instrument_choices = [
	["Tifa", "Gendang Jawa", "Rebana", "Tambur"],
	["Fuu (Suling Papua)", "Suling Sunda", "Seruling Bali", "Serunai"]
]

func _ready():
	# 🎯 PERBAIKAN: Gunakan metode yang kompatibel dengan Main system
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			# Cek jika pulau Papua sudah selesai
			if player_data.has("completed_islands") and "papua" in player_data["completed_islands"]:
				print("🔄 Pulau Papua sudah selesai, menunjukkan completion screen...")
				call_deferred("show_already_completed_screen")
				return
			# Cek hanya level 1 yang selesai
			elif player_data.has("completed_levels"):
				var level_key = "papua_1"
				if player_data["completed_levels"].has(level_key) and player_data["completed_levels"][level_key]:
					print("🔄 Level 1 Papua sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return

	# Debug info untuk memastikan node ditemukan
	print("=== PULAU PAPUA LEVEL 1 INITIALIZATION ===")
	print("AudioStreamPlayer: ", audio_player != null)
	print("PlayButton: ", play_button != null)
	print("ProgressBar: ", progress_bar != null)
	print("AnswerGrid: ", answer_grid != null)
	print("ResultContainer: ", result_container != null)
	print("ResultLabel: ", result_label != null)
	print("NextLevelBtn: ", next_level_btn != null)
	print("Header: ", header != null)
	
	if audio_player == null:
		push_error("❌ ERROR: AudioStreamPlayer not found! Check if node exists directly under PapuaLevel1")
		return
	
	# 🆕 SETUP UI PROPERTIES - Tunggu satu frame untuk memastikan semua node siap
	await get_tree().process_frame
	setup_ui_properties()
	
	# Setup panel style
	setup_audio_panel_style()
	
	print("✅ Pulau Papua Level 1 initialized successfully")

# 🆕 SETUP UI PROPERTIES
func setup_ui_properties():
	print("📝 Setting up UI properties...")
	
	if header:
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 28)
		print("✅ Header properties set")
	
	if result_label:
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.clip_text = false
		print("✅ ResultLabel properties set")
	
	if result_container:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.08, 0.1, 0.08, 0.95)  # Warna hutan Papua
		panel_style.border_color = Color(0.8, 0.6, 0.2)  # Warna emas Papua
		panel_style.border_width_left = 3
		panel_style.border_width_top = 3
		panel_style.border_width_right = 3
		panel_style.border_width_bottom = 3
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.corner_radius_bottom_left = 15
		result_container.add_theme_stylebox_override("panel", panel_style)
		result_container.visible = false
		print("✅ ResultContainer properties set")
	
	if next_level_btn:
		next_level_btn.add_theme_font_size_override("font_size", 16)
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.2, 0.5, 0.2)  # Hijau hutan Papua
		button_style.corner_radius_top_left = 8
		button_style.corner_radius_top_right = 8
		button_style.corner_radius_bottom_right = 8
		button_style.corner_radius_bottom_left = 8
		next_level_btn.add_theme_stylebox_override("normal", button_style)
		print("✅ NextButton properties set")
	
	# Setup UI state awal
	setup_initial_ui_state()
	
	# CONNECT SIGNALS SETELAH SETUP UI
	connect_all_signals()

# 🆕 FUNGSI UNTUK SETUP UI STATE AWAL
func setup_initial_ui_state():
	print("🎮 Setting up initial UI state...")
	
	# Sembunyikan tombol navigasi terlebih dahulu
	if next_level_btn:
		next_level_btn.visible = false
	
	# Setup soal pertama
	setup_question()

# 🆕 FUNGSI UNTUK CONNECT SEMUA SIGNAL
func connect_all_signals():
	print("🔗 Connecting all signals...")
	
	# Connect play button
	if play_button and not play_button.pressed.is_connected(_on_play_button_pressed):
		play_button.pressed.connect(_on_play_button_pressed)
		print("✅ PlayButton connected")
	
	# Connect navigation buttons
	if next_level_btn and not next_level_btn.pressed.is_connected(_on_next_level_button_pressed):
		next_level_btn.pressed.connect(_on_next_level_button_pressed)
		print("✅ NextLevelBtn connected")
	
	# Connect audio player
	if audio_player and not audio_player.finished.is_connected(_on_audio_stream_player_finished):
		audio_player.finished.connect(_on_audio_stream_player_finished)
		print("✅ AudioPlayer connected")
	
	# Connect answer buttons
	connect_answer_buttons()

func setup_audio_panel_style():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.15, 0.1, 0.8)  # Hijau hutan
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.4, 0.7, 0.4)  # Hijau terang
	$UI/AudioContainer.add_theme_stylebox_override("panel", panel_style)

func connect_answer_buttons():
	var answer_buttons = answer_grid.get_children()
	print("🔍 Found ", len(answer_buttons), " answer buttons")
	
	for i in range(len(answer_buttons)):
		var button = answer_buttons[i] as Button
		if button:
			print("   Button ", i, ": ", button.name, " - Text: ", button.text)
			
			# Clear previous connections
			if button.pressed.is_connected(_on_answer_button_pressed):
				button.pressed.disconnect(_on_answer_button_pressed)
			
			# Connect with parameter
			button.pressed.connect(_on_answer_button_pressed.bind(button))
			print("   ✅ Connected button ", i)
		else:
			print("   ❌ Button ", i, " is not a Button node")

func setup_question():
	# Reset untuk soal baru
	attempts_count = 0
	
	# Ambil data alat musik berdasarkan index
	if current_question_index < len(papua_instruments):
		current_instrument_data = papua_instruments[current_question_index]
		
		# Load audio dengan pengecekan yang ketat
		print("🎵 Loading instrument sound: ", current_instrument_data["audio"])
		
		var audio_stream = load(current_instrument_data["audio"])
		if audio_stream:
			print("✅ Audio stream loaded successfully")
			audio_player.stream = audio_stream
			audio_length = current_instrument_data["duration"]
			print("⏱️ Audio duration: ", audio_length, " seconds")
		else:
			push_error("❌ FAILED to load audio: " + current_instrument_data["audio"])
			# Fallback jika audio tidak ditemukan
			audio_length = current_instrument_data["duration"]
			print("⚠️ Using fallback duration: ", audio_length, "s")
		
		progress_bar.max_value = audio_length
		progress_bar.value = 0
		
		# Setup answer buttons
		setup_answer_buttons(current_question_index)
		
		# 🆕 RESET UI STATE dengan pengecekan null
		result_label.text = ""
		result_label.modulate = Color.WHITE
		if result_container:
			result_container.visible = false
		
		play_button.disabled = false
		play_button.text = "▶️ PUTAR SUARA"
		
		# Gunakan visible = false daripada hide() untuk menghindari error
		if next_level_btn:
			next_level_btn.visible = false
		
		# Update header dengan nomor soal
		if header:
			header.text = "PULAU PAPUA - LEVEL 1\n🎵 Soal " + str(current_question_index + 1) + "/" + str(total_questions) + ": Tebak Alat Musik Papua"
		
		print("📝 Question ready - Instrument: ", current_instrument_data["instrument_name"])
	else:
		print("❌ No more questions available")

func setup_answer_buttons(question_index: int):
	var choices = instrument_choices[question_index].duplicate()
	choices.shuffle()
	
	var answer_buttons = answer_grid.get_children()
	for i in range(min(len(answer_buttons), len(choices))):
		var button = answer_buttons[i] as Button
		if button:
			button.text = choices[i]
			button.disabled = false
			
			# Set button style
			var button_style = StyleBoxFlat.new()
			button_style.bg_color = Color(0.15, 0.2, 0.15)  # Hijau gelap
			button_style.border_color = Color(0.5, 0.7, 0.5)
			button_style.border_width_left = 2
			button_style.border_width_top = 2
			button_style.border_width_right = 2
			button_style.border_width_bottom = 2
			button_style.corner_radius_top_left = 8
			button_style.corner_radius_top_right = 8
			button_style.corner_radius_bottom_right = 8
			button_style.corner_radius_bottom_left = 8
			
			button.add_theme_stylebox_override("normal", button_style)
			
			# Hover style
			var hover_style = button_style.duplicate()
			hover_style.bg_color = Color(0.2, 0.25, 0.2)
			hover_style.border_color = Color(0.6, 0.8, 0.6)
			button.add_theme_stylebox_override("hover", hover_style)
			
			# Disabled style
			var disabled_style = button_style.duplicate()
			disabled_style.bg_color = Color(0.1, 0.12, 0.1)
			disabled_style.border_color = Color(0.3, 0.4, 0.3)
			button.add_theme_stylebox_override("disabled", disabled_style)
			
			button.add_theme_font_size_override("font_size", 14)
			
			print("📝 Button ", i, " set to: ", choices[i])
		else:
			print("⚠️ Button ", i, " is not a Button node")

func _on_play_button_pressed():
	print("🎵 Play button pressed")
	if not is_playing:
		play_audio()
	else:
		pause_audio()

func play_audio():
	if audio_player and audio_player.stream:
		audio_player.play()
		play_button.text = "⏸️ JEDA"
		is_playing = true
		if wave_animation:
			wave_animation.visible = true
		disable_answers(false)
		print("🎵 Audio playback started - Duration: ", audio_length, "s")
	else:
		push_error("Cannot play audio - check audio_player and stream")

func pause_audio():
	if audio_player:
		audio_player.stream_paused = !audio_player.stream_paused
		if audio_player.stream_paused:
			play_button.text = "▶️ PUTAR"
			if wave_animation:
				wave_animation.visible = false
			print("⏸️ Audio paused")
		else:
			play_button.text = "⏸️ JEDA"
			if wave_animation:
				wave_animation.visible = true
			print("▶️ Audio resumed")

func _process(delta):
	if is_playing and audio_player and audio_player.playing:
		audio_position = audio_player.get_playback_position()
		progress_bar.value = audio_position
		
		# Stop otomatis setelah waktu tertentu
		if audio_position >= audio_length:
			stop_audio()

func stop_audio():
	if audio_player:
		audio_player.stop()
	is_playing = false
	play_button.text = "▶️ PUTAR LAGI"
	if wave_animation:
		wave_animation.visible = false
	progress_bar.value = 0
	print("⏹️ Audio stopped")

func _on_answer_button_pressed(button: Button):
	print("🟡 Answer button pressed: ", button.text)
	check_answer(button.text)

func check_answer(answer: String):
	attempts_count += 1
	print("🔍 Checking answer: ", answer, " vs correct: ", current_instrument_data["correct_answer"])
	
	disable_answers(true)
	play_button.disabled = true
	
	if answer == current_instrument_data["correct_answer"]:
		handle_correct_answer()
	else:
		handle_wrong_answer(answer)

func handle_correct_answer():
	print("✅ Correct answer! Attempts: ", attempts_count)
	correct_answers += 1
	
	# 🆕 GUNAKAN RESULT CONTAINER
	result_label.text = "✅ BENAR!\n"
	result_label.text += "Alat Musik: " + current_instrument_data["instrument_name"] + "\n\n"
	result_label.text += "📚 DESKRIPSI:\n"
	result_label.text += current_instrument_data["description"] + "\n\n"
	result_label.text += "💡 FAKTA UNIK:\n"
	result_label.text += current_instrument_data["fact"] + "\n\n"
	
	# Tampilkan progress soal
	result_label.text += "📊 SOAL: " + str(current_question_index + 1) + "/" + str(total_questions) + "\n"
	result_label.text += "✅ JAWABAN BENAR: " + str(correct_answers) + "/" + str(total_questions)
	
	result_label.modulate = Color(0.5, 1, 0.5)  # Hijau terang
	
	# 🆕 TAMPILKAN RESULT CONTAINER
	if result_container:
		result_container.visible = true
	
	# Lanjut ke soal berikutnya setelah 3 detik
	await get_tree().create_timer(3.0).timeout
	
	# Pindah ke soal berikutnya atau selesaikan level
	current_question_index += 1
	if current_question_index < total_questions:
		setup_question()
	else:
		finish_level()

func handle_wrong_answer(wrong_answer: String):
	print("❌ Wrong answer: ", wrong_answer, " - Attempt: ", attempts_count)
	
	# 🆕 GUNAKAN RESULT CONTAINER
	result_label.text = "❌ SALAH!\n"
	result_label.text += "Bukan " + wrong_answer + "\n"
	result_label.text += "Coba dengarkan lagi dengan seksama!\n"
	result_label.text += "💡 Hint: " + get_hint_for_instrument()
	result_label.modulate = Color(1, 0.7, 0.7)  # Merah muda
	
	# 🆕 TAMPILKAN RESULT CONTAINER
	if result_container:
		result_container.visible = true
	
	# Reset setelah 3 detik
	await get_tree().create_timer(3.0).timeout
	if not level_completed:  # Pastikan level belum selesai
		# 🆕 SEMBUNYIKAN RESULT CONTAINER SAAT RESET
		if result_container:
			result_container.visible = false
		result_label.text = ""
		setup_question()

func get_hint_for_instrument() -> String:
	var instrument_name = current_instrument_data["instrument_name"]
	
	if instrument_name == "Tifa":
		return "Alat musik pukul berbentuk tabung, sering digunakan dalam upacara adat Papua"
	elif instrument_name == "Fuu (Suling Papua)":
		return "Alat musik tiup dari bambu, suaranya khas Papua"
	
	return "Alat musik tradisional khas Papua"

func finish_level():
	print("🏁 Level finished! Correct answers: ", correct_answers, "/", total_questions)
	
	# 🆕 HITUNG REWARD BERDASARKAN PERFORMANCE
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	# 🎯 PERBAIKAN: Gunakan complete_level dengan benar
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		print("💾 Saving progress via Main.complete_level()...")
		var success = main.complete_level("papua", 1, stars, knowledge_points)
		if success:
			print("✅ Progress saved to Main system - Papua Level 1 completed")
			level_completed = true
			progress_saved = true
		else:
			print("⚠️ Progress save failed, using manual save")
			manual_save_progress(stars, knowledge_points)
			level_completed = true
			progress_saved = true
	else:
		print("❌ Main system not found or complete_level method missing")
		manual_save_progress(stars, knowledge_points)
		level_completed = true
		progress_saved = true
	
	# 🆕 GUNAKAN RESULT CONTAINER UNTUK FINAL RESULT
	result_label.text = "🎉 LEVEL SELESAI! 🎉\n\n"
	result_label.text += "📊 HASIL AKHIR:\n"
	result_label.text += "✅ Jawaban Benar: " + str(correct_answers) + "/" + str(total_questions) + "\n"
	result_label.text += "⭐ Bintang: " + str(stars) + "/3\n"
	result_label.text += "📚 Poin Budaya: +" + str(knowledge_points) + "\n\n"
	
	if correct_answers == total_questions:
		result_label.text += "💫 SEMPURNA! Kamu mengenal semua alat musik Papua!\n"
	elif correct_answers >= 1:
		result_label.text += "👏 BAGUS! Lanjut belajar tentang budaya Papua!\n"
	else:
		result_label.text += "💪 TERUS BELAJAR! Papua memiliki kekayaan budaya yang luar biasa!\n"
	
	result_label.text += "\n💡 INFORMASI:\n"
	result_label.text += "Papua kaya akan alat musik tradisional yang unik dan penuh makna budaya."
	
	result_label.modulate = Color(1, 0.85, 0.3)  # Warna emas
	
	# 🆕 TAMPILKAN RESULT CONTAINER
	if result_container:
		result_container.visible = true
	
	# Tampilkan tombol navigasi dengan visible bukan hide()
	if next_level_btn:
		next_level_btn.text = "Lanjut ke Level 2 →"
		next_level_btn.visible = true
	

func disable_answers(disabled: bool):
	var answer_buttons = answer_grid.get_children()
	for button in answer_buttons:
		if button is Button:
			button.disabled = disabled
	print("🔒 Answers disabled: ", disabled)

# 🆕 FUNGSI REWARD SYSTEM BERDASARKAN PERFORMANCE
func calculate_stars() -> int:
	var accuracy = float(correct_answers) / float(total_questions)
	
	if accuracy >= 1.0:  # 2/2 benar
		return 3  # ⭐⭐⭐
	elif accuracy >= 0.5:  # 1/2 benar
		return 2  # ⭐⭐
	else:
		return 1  # ⭐

func calculate_knowledge_points() -> int:
	var base_points = 50  # Base points untuk level 1
	var accuracy_bonus = int((float(correct_answers) / float(total_questions)) * 50)  # Bonus hingga 50
	return base_points + accuracy_bonus

func _on_next_level_button_pressed():
	print("➡️ Next level button pressed")
	
	# 🎯 PERBAIKAN: Simpan progress dulu sebelum pindah scene
	if level_completed and not progress_saved:
		print("⚠️ Progress not saved, attempting to save...")
		var stars = calculate_stars()
		var points = calculate_knowledge_points()
		manual_save_progress(stars, points)
	
	if level_completed:
		# 🎯 PERBAIKAN: Gunakan path yang benar dan cek keberadaan
		var next_scene_path = "res://scenes/Level2_Papua.tscn"
		
		print("🔍 Checking if scene exists:", next_scene_path)
		
		if ResourceLoader.exists(next_scene_path):
			print("✅ Scene found, loading:", next_scene_path)
			
			# 🎯 PERBAIKAN: Simpan game sebelum transisi
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("save_game"):
				main.save_game()
				print("💾 Game saved before transitioning")
			
			# Tunggu sebentar untuk memastikan save selesai
			await get_tree().create_timer(0.5).timeout
			
			get_tree().change_scene_to_file(next_scene_path)
		else:
			print("❌ Scene not found:", next_scene_path)
			# Fallback ke map
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				print("🔄 Falling back to map...")
				main.show_map()
			else:
				print("❌ Main node not found, loading MapScene directly")
				get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
	else:
		print("⚠️ Level not completed yet!")

func _on_restart_button_pressed():
	print("🔁 Restart button pressed")
	reset_level()

func reset_level():
	print("🔄 Restarting level...")
	
	# Stop audio jika sedang diputar
	if audio_player and audio_player.playing:
		audio_player.stop()
	
	# Reset semua variabel
	current_question_index = 0
	correct_answers = 0
	level_completed = false
	progress_saved = false
	attempts_count = 0
	is_playing = false
	
	# Reset UI dengan pengecekan null
	if result_container:
		result_container.visible = false
	
	if next_level_btn:
		next_level_btn.visible = false
	
	
	# Setup soal pertama
	setup_question()
	
	print("🔄 Level restarted successfully")

func _on_audio_stream_player_finished():
	print("🏁 Audio finished naturally")
	stop_audio()

# 🎯 FUNGSI BARU: Manual save jika main system gagal
func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Attempting manual save for Level 1...")
	
	var save_path = "user://game_save.dat"
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var saved_data = file.get_var()
		file.close()
		
		if saved_data:
			# Inisialisasi jika tidak ada
			if not saved_data.has("completed_levels"):
				saved_data["completed_levels"] = {}
			
			# Tandai level 1 selesai
			saved_data["completed_levels"]["papua_1"] = true
			
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
			
			# Tambahkan ke unlocked islands jika belum ada
			if not saved_data.has("unlocked_islands"):
				saved_data["unlocked_islands"] = ["sumatra", "jawa", "kalimantan", "sulawesi", "papua"]
			elif "papua" not in saved_data["unlocked_islands"]:
				saved_data["unlocked_islands"].append("papua")
			
			# Save back
			file = FileAccess.open(save_path, FileAccess.WRITE)
			if file:
				file.store_var(saved_data)
				file.close()
				print("✅ Manual save successful for Level 1!")
				progress_saved = true
			else:
				print("❌ Manual save failed - cannot write file")
		else:
			print("❌ No data found in save file")
	else:
		print("❌ Manual save failed - no save file found")

# 🎯 PERBAIKAN: Update show_already_completed_screen
func show_already_completed_screen():
	print("🔄 Showing already completed screen for Papua Level 1")
	
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
	
	# Update UI untuk menunjukkan status completed
	if header:
		header.text = "PULAU PAPUA - LEVEL 1\nSUDAH SELESAI! 🎉"
	
	# 🆕 GUNAKAN RESULT CONTAINER
	result_label.text = "Kamu sudah menyelesaikan level ini! 🎉\n\n"
	result_label.text += "📊 Progress Saat Ini:\n"
	result_label.text += "   ⭐ Total Bintang: " + str(stars) + "\n"
	result_label.text += "   📚 Total Poin: " + str(knowledge_points) + "\n\n"
	
	result_label.text += "🎵 Kamu telah belajar mengenal alat musik tradisional Papua:\n"
	result_label.text += "   • Tifa - Alat musik pukul untuk upacara adat\n"
	result_label.text += "   • Fuu - Suling tradisional dari bambu\n"
	
	result_label.modulate = Color(1, 0.85, 0.3)  # Warna emas
	
	if result_container:
		result_container.visible = true
	
	# Nonaktifkan gameplay elements
	if play_button:
		play_button.visible = false
	if progress_bar:
		progress_bar.visible = false
	if wave_animation:
		wave_animation.visible = false
	disable_answers(true)
	
	# Tampilkan tombol navigasi
	if next_level_btn:
		next_level_btn.text = "Lanjut ke Level 2 →"
		next_level_btn.visible = true
	
	
	# Set flag level completed
	level_completed = true
	progress_saved = true

# 🆕 INPUT HANDLER
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Kembali ke map
			print("⎋ ESC pressed - Returning to map")
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				main.show_map()
			else:
				print("❌ Main node not found, loading MapScene directly")
				get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _exit_tree():
	print("🏝️ Pulau Papua Level 1 exiting...")
	# Simpan progress sebelum exit jika belum disimpan
	if level_completed and not progress_saved:
		print("💾 Saving progress before exiting...")
		var stars = calculate_stars()
		var points = calculate_knowledge_points()
		manual_save_progress(stars, points) 
