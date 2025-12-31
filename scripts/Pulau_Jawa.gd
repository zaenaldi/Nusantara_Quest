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

var current_song_data: Dictionary
var is_playing = false
var audio_length = 0.0
var audio_position = 0.0
var level_completed = false
var attempts_count = 0
var progress_saved = false
var connections_setup = false  # 🆕 FLAG UNTUK TRACK CONNECTIONS

# Hanya 1 lagu - Gundul-Gundul Pacul dengan durasi 30 detik
var jawa_songs = {
	"gundul_pacul": {
		"audio": "res://assets/audio/gundul_gundul_pacul.mp3",
		"correct_answer": "Jawa Tengah",
		"description": "Lagu dolanan anak tradisional Jawa Tengah yang menceritakan tentang seorang anak gundul yang membawa pacul (cangkul). Lagu ini sering dinyanyikan anak-anak saat bermain dan mengandung pesan moral tentang pentingnya pendidikan.",
		"duration": 30.0,
		"song_name": "Gundul-Gundul Pacul"
	}
}

func _ready():
	print("🎵 Pulau Jawa Level 1 - Tebak Lagu Daerah Loaded")
	
	# 🆕 RESET FLAG
	connections_setup = false
	
	# 🎯 PERBAIKAN: Gunakan metode yang kompatibel dengan Main system
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			# Cek jika pulau Jawa sudah selesai (level 2 selesai berarti level 1 juga selesai)
			if player_data.has("completed_islands") and "jawa" in player_data["completed_islands"]:
				print("🔄 Pulau Jawa sudah selesai, menunjukkan completion screen...")
				call_deferred("show_already_completed_screen")
				return
			# Cek hanya level 1 yang selesai
			elif player_data.has("completed_levels"):
				var level_key = "jawa_1"
				if player_data["completed_levels"].has(level_key) and player_data["completed_levels"][level_key]:
					print("🔄 Level 1 Jawa sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return
	
	# Debug info
	print("=== PULAU JAWA LEVEL 1 INITIALIZATION ===")
	print("AudioStreamPlayer: ", audio_player != null)
	print("PlayButton: ", play_button != null)
	print("ProgressBar: ", progress_bar != null)
	print("AnswerGrid: ", answer_grid != null)
	print("ResultContainer: ", result_container != null)
	print("ResultLabel: ", result_label != null)
	print("NextLevelBtn: ", next_level_btn != null)
	print("Header: ", header != null)
	
	if audio_player == null:
		push_error("❌ ERROR: AudioStreamPlayer not found!")
		return
	
	# 🆕 SETUP UI PROPERTIES
	call_deferred("setup_ui_properties")
	
	setup_level()
	disable_answers(true)
	next_level_btn.hide()
	
	# Setup panel style
	setup_audio_panel_style()
	
	# 🆕 TUNDA KONEKSI SIGNALS
	call_deferred("setup_connections")
	
	print("✅ Pulau Jawa Level 1 initialized successfully")

# 🆕 FUNGSI BARU: Setup connections dengan proteksi duplicate
func setup_connections():
	if connections_setup:
		print("⚠️ Connections already setup, skipping...")
		return
	
	print("🔗 Setting up connections...")
	
	# 🆕 DISCONNECT DULU SEMUA EXISTING CONNECTIONS
	if play_button:
		if play_button.pressed.is_connected(_on_play_button_pressed):
			play_button.pressed.disconnect(_on_play_button_pressed)
			print("ℹ️ Disconnected existing play_button connection")
		play_button.pressed.connect(_on_play_button_pressed)
		print("✅ PlayButton connected")
	
	if next_level_btn:
		if next_level_btn.pressed.is_connected(_on_next_level_button_pressed):
			next_level_btn.pressed.disconnect(_on_next_level_button_pressed)
			print("ℹ️ Disconnected existing next_level_btn connection")
		next_level_btn.pressed.connect(_on_next_level_button_pressed)
		print("✅ NextLevelBtn connected")
	
	if audio_player:
		if audio_player.finished.is_connected(_on_audio_stream_player_finished):
			audio_player.finished.disconnect(_on_audio_stream_player_finished)
			print("ℹ️ Disconnected existing audio_player connection")
		audio_player.finished.connect(_on_audio_stream_player_finished)
		print("✅ AudioPlayer connected")
	
	# Connect answer buttons dengan proteksi
	setup_answer_buttons_connections()
	
	connections_setup = true
	print("✅ All connections setup complete")

# 🆕 FUNGSI BARU: Setup answer buttons dengan proteksi
func setup_answer_buttons_connections():
	if not answer_grid:
		print("❌ AnswerGrid not found!")
		return
	
	var answer_buttons = answer_grid.get_children()
	print("🔍 Found answer buttons:", answer_buttons.size())
	
	for button in answer_buttons:
		if button is Button:
			print("🔗 Setting up connection for button:", button.name)
			
			# 🆕 DISCONNECT DULU SEMUA EXISTING CONNECTIONS
			if button.pressed.is_connected(_on_jawa_barat_btn_pressed):
				button.pressed.disconnect(_on_jawa_barat_btn_pressed)
			if button.pressed.is_connected(_on_jawa_tengah_btn_pressed):
				button.pressed.disconnect(_on_jawa_tengah_btn_pressed)
			if button.pressed.is_connected(_on_yogyakarta_btn_pressed):
				button.pressed.disconnect(_on_yogyakarta_btn_pressed)
			if button.pressed.is_connected(_on_jawa_timur_btn_pressed):
				button.pressed.disconnect(_on_jawa_timur_btn_pressed)
			
			# Connect berdasarkan nama button
			if button.name == "JawaBaratBtn":
				button.pressed.connect(_on_jawa_barat_btn_pressed)
				print("✅ Connected JawaBaratBtn")
			elif button.name == "JawaTengahBtn":
				button.pressed.connect(_on_jawa_tengah_btn_pressed)
				print("✅ Connected JawaTengahBtn")
			elif button.name == "YogyakartaBtn":
				button.pressed.connect(_on_yogyakarta_btn_pressed)
				print("✅ Connected YogyakartaBtn")
			elif button.name == "JawaTimurBtn":
				button.pressed.connect(_on_jawa_timur_btn_pressed)
				print("✅ Connected JawaTimurBtn")
			else:
				print("⚠️ Unknown button name:", button.name)

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
		panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
		panel_style.border_color = Color.GOLD
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
		button_style.bg_color = Color(0.2, 0.6, 0.2)
		button_style.corner_radius_top_left = 8
		button_style.corner_radius_top_right = 8
		button_style.corner_radius_bottom_right = 8
		button_style.corner_radius_bottom_left = 8
		next_level_btn.add_theme_stylebox_override("normal", button_style)
		print("✅ NextButton properties set")

func setup_audio_panel_style():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.3, 0.5, 0.8)
	$UI/AudioContainer.add_theme_stylebox_override("panel", panel_style)

func setup_level():
	# Reset attempts untuk soal baru
	attempts_count = 0
	
	# Gunakan lagu Gundul-Gundul Pacul saja
	current_song_data = jawa_songs["gundul_pacul"]
	
	# Load audio dengan pengecekan yang ketat
	print("🎵 Loading audio: ", current_song_data["audio"])
	
	var audio_stream = load(current_song_data["audio"])
	if audio_stream:
		print("✅ Audio stream loaded successfully")
		audio_player.stream = audio_stream
		audio_length = current_song_data["duration"]
		print("⏱️ Audio duration: ", audio_length, " seconds")
	else:
		push_error("❌ FAILED to load audio: " + current_song_data["audio"])
		audio_length = 30.0
	
	progress_bar.max_value = audio_length
	progress_bar.value = 0
	
	# RESET UI STATE
	result_label.text = ""
	result_label.modulate = Color.WHITE
	if result_container:
		result_container.visible = false
	play_button.disabled = false
	next_level_btn.hide()
	
	# Update header
	if header:
		header.text = "PULAU JAWA - LEVEL 1\n🎵 Tebak Asal Lagu Daerah Manakah Ini"
	
	print("📝 Question ready - Lagu: Gundul-Gundul Pacul")

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

# FUNGSI JAWABAN
func _on_jawa_barat_btn_pressed():
	print("🟡 Jawa Barat button pressed")
	check_answer("Jawa Barat")

func _on_jawa_tengah_btn_pressed():
	print("🟡 Jawa Tengah button pressed")
	check_answer("Jawa Tengah")

func _on_yogyakarta_btn_pressed():
	print("🟡 Yogyakarta button pressed")
	check_answer("DI Yogyakarta")

func _on_jawa_timur_btn_pressed():
	print("🟡 Jawa Timur button pressed")
	check_answer("Jawa Timur")

func check_answer(province: String):
	attempts_count += 1
	print("🔍 Checking answer: ", province, " vs correct: ", current_song_data["correct_answer"])
	
	disable_answers(true)
	play_button.disabled = true
	
	if province == current_song_data["correct_answer"]:
		handle_correct_answer()
	else:
		handle_wrong_answer(province)

func handle_correct_answer():
	print("✅ Correct answer! Attempts: ", attempts_count)
	
	# HITUNG REWARD
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	# SIMPAN PROGRESS
	save_progress(stars, knowledge_points)
	
	# TAMPILKAN HASIL
	result_label.text = "✅ BENAR!\n"
	result_label.text += "Lagu: " + current_song_data["song_name"] + "\n"
	result_label.text += "Asal: " + current_song_data["correct_answer"] + "\n"
	result_label.text += current_song_data["description"] + "\n"
	result_label.text += "⭐ Bintang: " + str(stars) + "/3\n"
	result_label.text += "📚 Poin: +" + str(knowledge_points) + "\n"
	result_label.modulate = Color(0.5, 1, 0.5)
	
	if progress_saved:
		result_label.text += "\n✅ Progress tersimpan!"
	else:
		result_label.text += "\n⚠️ Progress belum tersimpan!"
	
	if result_container:
		result_container.visible = true
	
	next_level_btn.text = "Lanjut ke Level 2 →"
	next_level_btn.show()

func handle_wrong_answer(wrong_answer: String):
	print("❌ Wrong answer: ", wrong_answer, " - Attempt: ", attempts_count)
	
	result_label.text = "❌ SALAH!\n"
	result_label.text += "Bukan dari " + wrong_answer + "\n"
	result_label.text += "Coba dengarkan lagi dengan seksama!\n"
	result_label.text += "💡 Hint: Lagu ini berasal dari " + current_song_data["correct_answer"]
	result_label.modulate = Color(1, 0.7, 0.7)
	
	if result_container:
		result_container.visible = true
	
	# Reset setelah 3 detik
	await get_tree().create_timer(3.0).timeout
	if not level_completed:
		if result_container:
			result_container.visible = false
		result_label.text = ""
		setup_level()

func disable_answers(disabled: bool):
	for button in answer_grid.get_children():
		if button is Button:
			button.disabled = disabled
	print("🔒 Answers disabled: ", disabled)

func calculate_stars() -> int:
	if attempts_count == 1:
		return 3
	elif attempts_count == 2:
		return 2
	else:
		return 1

func calculate_knowledge_points() -> int:
	var base_points = 50
	var efficiency_bonus = 0
	
	if attempts_count == 1:
		efficiency_bonus = 30
	elif attempts_count == 2:
		efficiency_bonus = 15
	elif attempts_count == 3:
		efficiency_bonus = 5
	
	return base_points + efficiency_bonus

# 🆕 FUNGSI SAVE PROGRESS YANG TERPUSAT
func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving Jawa Level 1 progress...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		print("✅ Using Main.complete_level()")
		var success = main.complete_level("jawa", 1, stars, knowledge_points)
		if success:
			progress_saved = true
			level_completed = true
			print("✅ Progress saved via Main system!")
		else:
			print("⚠️ Main system save failed, using manual save...")
			manual_save_progress(stars, knowledge_points)
	else:
		print("❌ Main.complete_level() not available")
		manual_save_progress(stars, knowledge_points)

func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Manual save for Jawa Level 1...")
	
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
	
	# Mark level 1 as completed
	saved_data["completed_levels"]["jawa_1"] = true
	
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
	
	# Save back
	file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(saved_data)
		file.close()
		progress_saved = true
		level_completed = true
		print("✅ Manual save successful!")
	else:
		print("❌ Manual save failed - cannot write file")
		progress_saved = false

# 🆕 PERBAIKAN: Fungsi next level dengan proteksi
func _on_next_level_button_pressed():
	print("➡️ Next level button pressed")
	
	# 🆕 CEGAH MULTIPLE CALLS
	next_level_btn.disabled = true
	
	if level_completed and progress_saved:
		# 🎯 Path ke Level 2 Jawa
		var next_scene_path = "res://scenes/Level2_Jawa.tscn"
		
		print("🔍 Loading next level:", next_scene_path)
		
		# 🆕 TUNGGU SEBENTAR SEBELUM TRANSISI
		await get_tree().create_timer(0.1).timeout
		
		if ResourceLoader.exists(next_scene_path):
			print("✅ Scene exists, transitioning...")
			
			# 🎯 PERBAIKAN: Gunakan Main untuk scene management jika ada
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("change_scene"):
				print("✅ Using Main.change_scene()")
				main.change_scene(next_scene_path)
			else:
				# Fallback langsung
				print("⚠️ Main.change_scene not available, using direct transition")
				get_tree().change_scene_to_file(next_scene_path)
		else:
			print("❌ Scene not found:", next_scene_path)
			
			# Kembali ke map
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				print("🔄 Falling back to map...")
				main.show_map()
			else:
				print("❌ Main not found, loading MapScene directly")
				get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
	else:
		print("⚠️ Level not completed or progress not saved!")
		next_level_btn.disabled = false

func _on_audio_stream_player_finished():
	print("🏁 Audio finished naturally")
	stop_audio()

func show_already_completed_screen():
	print("🔄 Showing already completed screen for Jawa Level 1")
	
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
	
	# Update UI
	if header:
		header.text = "PULAU JAWA - LEVEL 1\nSUDAH SELESAI! 🎉"
	
	result_label.text = "Kamu sudah menyelesaikan level ini! 🎉\n\n"
	result_label.text += "📊 Progress Saat Ini:\n"
	result_label.text += "   ⭐ Total Bintang: " + str(stars) + "\n"
	result_label.text += "   📚 Total Poin: " + str(knowledge_points) + "\n\n"
	
	if "kalimantan" in unlocked_islands:
		result_label.text += "🔓 Pulau Kalimantan sudah terbuka!\n"
	else:
		result_label.text += "🔒 Lanjutkan ke Level 2 untuk membuka pulau berikutnya!\n"
	
	result_label.modulate = Color.GOLD
	
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
	
	# Tampilkan tombol lanjut
	next_level_btn.text = "Lanjut ke Level 2 →"
	next_level_btn.show()
	
	# Set flag level completed
	level_completed = true
	progress_saved = true

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# 🆕 FUNGSI KEMBALI KE MAP DENGAN PROTEKSI
			print("⎋ ESC pressed - Returning to map")
			
			# Nonaktifkan input sementara
			set_process_input(false)
			
			await get_tree().create_timer(0.1).timeout
			
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				print("✅ Using Main.show_map()")
				await get_tree().process_frame  # Tunggu frame berikutnya
				main.show_map()
			else:
				print("❌ Main not found, loading MapScene directly")
				await get_tree().create_timer(0.2).timeout
				get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
			
			set_process_input(true)

func _exit_tree():
	print("🏝️ Pulau Jawa Level 1 exiting...")
	print("📊 Final State:")
	print("   Level completed:", level_completed)
	print("   Progress saved:", progress_saved)
	print("   Connections setup:", connections_setup)
	
	# 🆕 DISCONNECT SEMUA SIGNALS SAAT EXIT
	if connections_setup:
		print("🔌 Disconnecting all signals...")
		
		if play_button and play_button.pressed.is_connected(_on_play_button_pressed):
			play_button.pressed.disconnect(_on_play_button_pressed)
		
		if next_level_btn and next_level_btn.pressed.is_connected(_on_next_level_button_pressed):
			next_level_btn.pressed.disconnect(_on_next_level_button_pressed)
		
		if audio_player and audio_player.finished.is_connected(_on_audio_stream_player_finished):
			audio_player.finished.disconnect(_on_audio_stream_player_finished)
		
		# Disconnect answer buttons
		if answer_grid:
			var answer_buttons = answer_grid.get_children()
			for button in answer_buttons:
				if button is Button:
					if button.pressed.is_connected(_on_jawa_barat_btn_pressed):
						button.pressed.disconnect(_on_jawa_barat_btn_pressed)
					if button.pressed.is_connected(_on_jawa_tengah_btn_pressed):
						button.pressed.disconnect(_on_jawa_tengah_btn_pressed)
					if button.pressed.is_connected(_on_yogyakarta_btn_pressed):
						button.pressed.disconnect(_on_yogyakarta_btn_pressed)
					if button.pressed.is_connected(_on_jawa_timur_btn_pressed):
						button.pressed.disconnect(_on_jawa_timur_btn_pressed)
		
		connections_setup = false
		print("✅ All signals disconnected")
