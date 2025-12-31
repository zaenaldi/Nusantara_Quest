extends Control

# Hapus atau komentari node references yang tidak ada
# @onready var background = $Background as TextureRect
@onready var header = $UI/Header as Label
@onready var question_container = $UI/QuestionContainer as Panel
@onready var question_text = $UI/QuestionContainer/QuestionText as Label
@onready var hint_container = $UI/HintContainer as Panel
@onready var hint_label = $UI/HintContainer/HintLabel as Label
@onready var answer_input = $UI/AnswerInput as LineEdit
@onready var submit_button = $UI/SubmitButton as TextureButton
@onready var timer_label = $UI/TimerLabel as Label
@onready var result_container = $UI/ResultContainer as Panel
@onready var result_text = $UI/ResultContainer/ResultText as Label
@onready var next_button = $UI/NextButton as Button

# Game variables
var current_question_index = 0
var timer_value = 120  # 2 menit = 120 detik
var timer_running = false
var total_timer_time = 120  # 2 menit
var level_completed = false
var questions = []
var correct_answer_count = 0
var current_attempts = 0
var max_attempts_per_question = 2
var time_up_count = 0  # Menghitung berapa kali waktu habis

# Questions database for Kalimantan - HANYA 4 SOAL
var kalimantan_questions = [
	{
		"question": "Suku asli Kalimantan yang terkenal dengan tato tradisional dan rumah panjangnya adalah suku...",
		"answer": "Dayak",
		"keywords": ["dayak", "suku dayak"],
		"hint": "Suku ini memiliki budaya tato yang khas dan tinggal di rumah panjang",
		"explanation": "Suku Dayak adalah suku asli Kalimantan yang terkenal dengan rumah panjang (betang) dan seni tato tradisional sebagai simbol status dan keberanian.",
		"fact": "Tato pada suku Dayak bukan sekadar hiasan, melainkan menceritakan perjalanan hidup, status sosial, dan prestasi seseorang."
	},
	{
		"question": "Upacara adat Kalimantan untuk menyambut panen padi disebut...",
		"answer": "Gawai",
		"keywords": ["gawai", "gawai dayak"],
		"hint": "Upacara syukur atas hasil panen",
		"explanation": "Gawai adalah upacara adat suku Dayak untuk mengucapkan syukur atas hasil panen, biasanya dirayakan dengan tarian dan musik tradisional.",
		"fact": "Gawai Dayak bisa berlangsung selama berhari-hari dengan berbagai ritual, tarian, dan makan bersama seluruh warga desa."
	},
	{
		"question": "Tarian perang tradisional Kalimantan yang melambangkan keberanian disebut tari...",
		"answer": "Mandau",
		"keywords": ["mandau", "tari mandau", "perang"],
		"hint": "Tarian yang menggunakan senjata tradisional",
		"explanation": "Tari Mandau adalah tarian perang tradisional Kalimantan yang menggunakan senjata mandau (parang tradisional) sebagai properti utamanya.",
		"fact": "Mandau adalah senjata tradisional Dayak yang dianggap sakral, hanya digunakan dalam situasi khusus seperti perang atau upacara."
	},
	{
		"question": "Makanan khas Kalimantan yang terbuat dari beras ketan dan dimasak dalam bambu disebut...",
		"answer": "Lemang",
		"keywords": ["lemang", "ketan", "bambu"],
		"hint": "Makanan dari beras ketan yang dimasak dalam bambu",
		"explanation": "Lemang adalah makanan tradisional Kalimantan terbuat dari beras ketan dan santan yang dimasak dalam batang bambu, biasanya disajikan saat hari raya.",
		"fact": "Lemang dimasak dengan cara dipanggang di atas api selama beberapa jam, memberikan aroma khas bambu yang harum."
	}
]

func _ready():
	print("🌴 Pulau Kalimantan Level 1 Loaded")
	
	# Cek apakah ada masalah dengan node references
	print("🔍 Checking node references...")
	
	# Update nama-nama node yang sebenarnya ada di scene Anda
	# Sesuaikan path dengan struktur scene aktual Anda
	
	# Cek jika level sudah completed
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			# Check if Kalimantan is completed
			if player_data.has("completed_islands") and "kalimantan" in player_data["completed_islands"]:
				print("🔄 Pulau Kalimantan sudah selesai, menunjukkan completion screen...")
				call_deferred("show_already_completed_screen")
				return
			# Check only level 1 completed
			elif player_data.has("completed_levels"):
				var level_key = "kalimantan_1"
				if player_data["completed_levels"].has(level_key) and player_data["completed_levels"][level_key]:
					print("🔄 Level 1 Kalimantan sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return
	
	# Setup UI properties
	call_deferred("setup_ui_properties")
	
	# Initialize level
	call_deferred("initialize_level")

func fix_node_references():
	"""Fungsi untuk memperbaiki node references yang salah path"""
	print("🔧 Fixing node references...")
	
	# Tidak perlu mencari Background jika tidak ada
	
	# Cek dan perbaiki SubmitButton
	if not submit_button:
		submit_button = get_node_or_null("UI/SubmitButton")
		if submit_button:
			print("✅ SubmitButton ditemukan")
		else:
			print("❌ SubmitButton tidak ditemukan!")
	
	# Cek dan perbaiki NextButton
	if not next_button:
		next_button = get_node_or_null("UI/NextButton")
		if next_button:
			print("✅ NextButton ditemukan")
		else:
			print("❌ NextButton tidak ditemukan!")

func setup_ui_properties():
	print("🎨 Setting up UI properties...")
	
	# Setup Header
	if header:
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 28)
		header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		print("✅ Header properties set")
	
	# Setup QuestionText
	if question_text:
		question_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		question_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		print("✅ QuestionText properties set")
	
	# Setup AnswerInput
	if answer_input:
		answer_input.placeholder_text = "Masukkan jawaban Anda di sini..."
		print("✅ AnswerInput properties set")
	
	# Setup SubmitButton
	if submit_button:
		submit_button.disabled = true
		print("✅ SubmitButton properties set")
	
	# Setup TimerLabel
	if timer_label:
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		print("✅ TimerLabel properties set")
	
	# Setup ResultContainer
	if result_container:
		result_container.visible = false
		print("✅ ResultContainer properties set")
	
	# Setup NextButton
	if next_button:
		next_button.visible = false
		next_button.disabled = true
		print("✅ NextButton properties set")

func initialize_level():
	print("🎮 Initializing Kalimantan Level 1...")
	
	# Setup Header
	if header:
		header.text = "PULAU KALIMANTAN - LEVEL 1"
	
	# Initialize questions (shuffle for variety)
	questions = kalimantan_questions.duplicate()
	questions.shuffle()
	
	# Reset game variables
	current_question_index = 0
	current_attempts = 0
	correct_answer_count = 0
	level_completed = false
	timer_value = total_timer_time
	timer_running = false
	time_up_count = 0
	
	# Update Timer Label
	update_timer_display()
	
	# Connect signals
	connect_signals()
	
	# Start with first question
	update_question()
	
	print("✅ Level initialized - Total questions:", questions.size())

func connect_signals():
	print("🔗 Connecting signals...")
	
	# Connect SubmitButton
	if submit_button:
		if submit_button.pressed.is_connected(_on_submit_pressed):
			submit_button.pressed.disconnect(_on_submit_pressed)
		submit_button.pressed.connect(_on_submit_pressed)
		print("✅ SubmitButton signal connected")
	
	# Connect NextButton
	if next_button:
		if next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.disconnect(_on_next_pressed)
		next_button.pressed.connect(_on_next_pressed)
		print("✅ NextButton signal connected")
	
	# Connect AnswerInput
	if answer_input:
		if answer_input.text_submitted.is_connected(_on_answer_text_submitted):
			answer_input.text_submitted.disconnect(_on_answer_text_submitted)
		answer_input.text_submitted.connect(_on_answer_text_submitted)
		print("✅ AnswerInput text_submitted signal connected")
		
		if answer_input.text_changed.is_connected(_on_answer_changed):
			answer_input.text_changed.disconnect(_on_answer_changed)
		answer_input.text_changed.connect(_on_answer_changed)
		print("✅ AnswerInput text_changed signal connected")

func update_timer_display():
	if timer_label:
		var minutes = int(timer_value) / 60
		var seconds = int(timer_value) % 60
		timer_label.text = "⏰ Waktu: %02d:%02d" % [minutes, seconds]

func update_question():
	if current_question_index < questions.size():
		var question = questions[current_question_index]
		
		# Update question text
		if question_text:
			question_text.text = "Pertanyaan %d/%d:\n\n%s" % [
				current_question_index + 1,
				questions.size(),
				question["question"]
			]
		
		# Update hint
		if hint_label:
			hint_label.text = "💡 Hint: " + question["hint"]
		
		# Clear answer input
		if answer_input:
			answer_input.text = ""
			answer_input.editable = true
			answer_input.grab_focus()
		
		# Reset attempts for this question
		current_attempts = 0
		
		# Disable submit button until text is entered
		if submit_button:
			submit_button.disabled = true
			submit_button.visible = true
		
		# Start timer if not already running
		if not timer_running:
			timer_running = true
	else:
		complete_level()

func _on_answer_changed(new_text):
	# Enable submit button only if there's text
	if submit_button:
		submit_button.disabled = new_text.strip_edges().is_empty()

func _on_answer_text_submitted(_text):
	# Submit when Enter is pressed (if button is enabled)
	if submit_button and not submit_button.disabled:
		_on_submit_pressed()

func _on_submit_pressed():
	print("🎯 Submit button pressed!")
	
	if not answer_input or answer_input.text.strip_edges().is_empty():
		return
	
	# Stop timer saat menjawab
	timer_running = false
	
	# Disable button during processing
	if submit_button:
		submit_button.disabled = true
	
	# Check answer
	var user_answer = answer_input.text.strip_edges().to_lower()
	var current_question = questions[current_question_index]
	
	current_attempts += 1
	
	# Check against keywords
	var is_correct = false
	for keyword in current_question["keywords"]:
		if user_answer.find(keyword) != -1:
			is_correct = true
			break
	
	if is_correct:
		handle_correct_answer()
	else:
		handle_wrong_answer()

func handle_correct_answer():
	print("✅ Correct answer!")
	correct_answer_count += 1
	
	# Show correct feedback
	if result_text:
		result_text.text = "✅ BENAR!\n\n"
		result_text.text += "Jawaban: " + questions[current_question_index]["answer"] + "\n\n"
		result_text.text += questions[current_question_index]["explanation"] + "\n\n"
		result_text.text += "💡 Fakta: " + questions[current_question_index]["fact"]
	
	if result_container:
		result_container.visible = true
	
	# Move to next question after delay
	await get_tree().create_timer(2.0).timeout
	
	if result_container:
		result_container.visible = false
	
	# Move to next question
	current_question_index += 1
	update_question()

func handle_wrong_answer():
	print("❌ Wrong answer")
	
	# Check if max attempts reached
	if current_attempts >= max_attempts_per_question:
		# Show correct answer
		if result_text:
			result_text.text = "❌ Maksimal percobaan tercapai!\n\n"
			result_text.text += "Jawaban yang benar: " + questions[current_question_index]["answer"] + "\n\n"
			result_text.text += questions[current_question_index]["explanation"]
		
		if result_container:
			result_container.visible = true
		
		# Move to next question after delay
		await get_tree().create_timer(3.0).timeout
		
		if result_container:
			result_container.visible = false
		
		# Move to next question
		current_question_index += 1
		update_question()
	else:
		# Show hint for wrong answer
		if result_text:
			result_text.text = "❌ Belum tepat!\n\n"
			result_text.text += "Coba lagi...\n"
			result_text.text += "💡 Hint: " + questions[current_question_index]["hint"]
		
		if result_container:
			result_container.visible = true
		
		# Hide hint after delay
		await get_tree().create_timer(1.5).timeout
		
		if result_container:
			result_container.visible = false
		
		# Enable submit button for retry
		if submit_button:
			submit_button.disabled = false
		
		# Focus back to input
		if answer_input:
			answer_input.grab_focus()

func complete_level():
	print("🎉 Level completed!")
	timer_running = false
	level_completed = true
	
	# Calculate rewards hanya jika semua soal terjawab
	if correct_answer_count == questions.size():
		var stars = calculate_stars()
		var knowledge_points = calculate_knowledge_points()
		
		# Save progress
		save_progress(stars, knowledge_points)
		
		# Show final result
		show_final_result(stars, knowledge_points)
	else:
		# Jika tidak semua soal terjawab, kembali ke peta
		show_timeout_result("Level tidak selesai!", "Kamu hanya berhasil menjawab %d dari %d soal.\n\nKembali ke peta dan coba lagi!" % [correct_answer_count, questions.size()])

func calculate_stars() -> int:
	var percentage = float(correct_answer_count) / float(questions.size()) * 100
	
	if percentage >= 90:
		return 3
	elif percentage >= 70:
		return 2
	else:
		return 1

func calculate_knowledge_points() -> int:
	var base_points = 50
	var correct_bonus = correct_answer_count * 15
	var efficiency_bonus = int((float(timer_value) / float(total_timer_time)) * 20)
	
	return base_points + correct_bonus + efficiency_bonus

func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving progress...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		var success = main.complete_level("kalimantan", 1, stars, knowledge_points)
		if success:
			print("✅ Progress saved successfully!")
		else:
			print("⚠️ Main system save failed")
	else:
		print("❌ Main node not found")

func show_final_result(stars: int, points: int):
	print("🏆 Showing final result...")
	
	if result_text:
		result_text.text = "🎉 LEVEL SELESAI! 🎉\n\n"
		result_text.text += "📊 Hasil Akhir:\n"
		result_text.text += "   • Pertanyaan dijawab: %d/%d\n" % [correct_answer_count, questions.size()]
		result_text.text += "   • ⭐ Bintang: %d/3\n" % stars
		result_text.text += "   • 📚 Poin Budaya: +%d\n\n" % points
		result_text.text += "🏆 Badge Budaya Kalimantan Terkunci!"
	
	if result_container:
		result_container.visible = true
	
	# Aktifkan tombol kembali ke peta
	if next_button:
		next_button.text = "🗺️ KEMBALI KE PETA"
		next_button.visible = true
		next_button.disabled = false
	
	# Disable gameplay elements
	if submit_button:
		submit_button.visible = false
	
	if answer_input:
		answer_input.visible = false
	
	if hint_container:
		hint_container.visible = false

func show_timeout_result(title: String, message: String):
	if result_text:
		result_text.text = title + "\n\n" + message
	
	if result_container:
		result_container.visible = true
	
	if next_button:
		next_button.text = "🗺️ KEMBALI KE PETA"
		next_button.visible = true
		next_button.disabled = false

func _on_next_pressed():
	print("🗺️ Kembali ke peta...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("show_map"):
		main.show_map()
	else:
		get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func show_already_completed_screen():
	print("🔄 Showing already completed screen")
	
	if header:
		header.text = "PULAU KALIMANTAN - LEVEL 1 SUDAH SELESAI! 🎉"
	
	if result_text:
		result_text.text = "Kamu sudah menyelesaikan level ini! 🎉\n\nTekan tombol untuk kembali ke peta"
	
	if result_container:
		result_container.visible = true
	
	# Disable gameplay elements
	if question_text:
		question_text.visible = false
	
	if answer_input:
		answer_input.visible = false
	
	if submit_button:
		submit_button.visible = false
	
	if hint_container:
		hint_container.visible = false
	
	if timer_label:
		timer_label.visible = false
	
	if next_button:
		next_button.text = "🗺️ KEMBALI KE PETA"
		next_button.visible = true
		next_button.disabled = false

func _process(delta):
	if timer_running and not level_completed:
		timer_value -= delta
		
		if timer_value <= 0:
			timer_value = 0
			timer_running = false
			handle_timeout()
		
		update_timer_display()

func handle_timeout():
	print("⏰ Time's up!")
	time_up_count += 1
	
	if time_up_count >= 2:
		show_timeout_result("⏰ GAGAL! 🚫", "Waktu telah habis 2 kali!\n\nKembali ke peta dan coba lagi!")
	else:
		show_timeout_result("⏰ WAKTU HABIS!", "Waktu untuk pertanyaan ini telah habis!\n\nPertanyaan akan diulang.")
		
		await get_tree().create_timer(3.0).timeout
		
		if result_container:
			result_container.visible = false
		
		# Reset timer dan ulangi pertanyaan yang sama
		timer_value = total_timer_time
		timer_running = true
		update_question()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("🗺️ ESC pressed - returning to map")
			_on_next_pressed()
