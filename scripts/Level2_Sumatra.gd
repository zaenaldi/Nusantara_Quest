extends Control

# ================= LEVEL 2 CONFIGURATION =================
var logic_puzzles = [
	{
		"instruction": "Susun huruf acak berikut hingga membentuk nama rumah adat khas Riau:",
		"scrambled_letters": "S R A J B H L E A U K A T M E O U K S R A H T",
		"correct_answer": "Rumah Selaso Jatuh Kembar",
		"hint_image": "res://assets/images/puzzles/sumatera_house_blur.jpg",
		"correct_image": "res://assets/images/puzzles/sumatera_house_clear.jpg",
		"fact": "Rumah Selaso Jatuh Kembar adalah rumah adat khas Riau yang memiliki dua selasar (teras) yang sejajar. Rumah ini mencerminkan nilai kebersamaan dan kerukunan dalam masyarakat Melayu Riau."
	}
]

# Game state variables
var current_puzzle_index = 0
var score = 0
var timer_value = 60
var timer_running = false
var total_timer_time = 60
var level_completed = false

# Node references
@onready var background = $Background as TextureRect
@onready var header = $UI/Header as Label
@onready var instruction_text = $UI/PuzzleContainer/InstructionText as Label
@onready var scrambled_letters = $UI/PuzzleContainer/ScrambledLetters as Label
@onready var hint_image = $UI/PuzzleContainer/HintImage as TextureRect
@onready var answer_input = $UI/AnswerInput as LineEdit
@onready var timer_bar = $UI/TimerBar as ProgressBar
@onready var timer_label = $UI/TimerLabel as Label
@onready var submit_button = $UI/SubmitButton as TextureButton
@onready var result_container = $UI/ResultContainer as Panel
@onready var result_text = $UI/ResultContainer/ResultText as Label
@onready var next_button = $UI/ResultContainer/NextButton as Button

func _ready():
	print("🏝️ Pulau Sumatera Level 2 Loaded")
	print("⏰ Timer set to:", total_timer_time, "seconds")
	
	# 🎯 PERBAIKAN: Cek jika level sudah completed untuk replay protection
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_island_progress"):
		var progress = main.get_island_progress("sumatra")
		if progress and progress.get("level2_completed", false):
			print("🔄 Level 2 already completed, showing completion screen...")
			call_deferred("show_already_completed_screen")
			return
	
	# 🎯 PERBAIKAN: Cari SubmitButton jika tidak ditemukan
	if submit_button == null:
		print("🔍 Searching for SubmitButton...")
		submit_button = find_submit_button()
	
	# Setup UI properties
	call_deferred("setup_ui_properties")
	
	# 🎯 PERBAIKAN: Debug node references untuk troubleshooting
	debug_node_references()
	
	# Tunggu sampai next frame untuk memastikan semua node ready
	call_deferred("initialize_level")

# 🎯 FUNCTION BARU: CARI SUBMITBUTTON DENGAN AMAN
func find_submit_button():
	var possible_paths = [
		"UI/SubmitButton",
		"SubmitButton",
		"../SubmitButton",
		"UILayer/SubmitButton"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TextureButton:
			print("✅ Found SubmitButton at:", path)
			return node
	
	print("❌ SubmitButton not found in any path, creating emergency button")
	return create_emergency_submit_button()

# 🎯 FUNCTION BARU: BUAT EMERGENCY BUTTON JIKA TIDAK DITEMUKAN
func create_emergency_submit_button():
	print("🔄 Creating emergency SubmitButton...")
	
	var button = Button.new()
	button.name = "SubmitButton"
	button.text = "CEK JAWABAN"
	
	# Position the button
	button.anchor_left = 0.35
	button.anchor_top = 0.78
	button.anchor_right = 0.65
	button.anchor_bottom = 0.85
	button.offset_left = 0
	button.offset_top = 0
	button.offset_right = 0
	button.offset_bottom = 0
	
	button.add_theme_font_size_override("font_size", 16)
	button.disabled = true
	
	# Style untuk button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8)
	button_style.border_color = Color.WHITE
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_right = 10
	button_style.corner_radius_bottom_left = 10
	button.add_theme_stylebox_override("normal", button_style)
	
	# Style untuk hover state
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.5, 0.9)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Style untuk disabled state
	var disabled_style = button_style.duplicate()
	disabled_style.bg_color = Color(0.5, 0.5, 0.5, 0.5)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Tambahkan ke scene
	if has_node("UI"):
		$UI.add_child(button)
	else:
		add_child(button)
		print("⚠️ UI node not found, adding to root")
	
	print("✅ Emergency SubmitButton created")
	return button

# 🎯 FUNCTION BARU: DEBUG NODE REFERENCES
func debug_node_references():
	print("=== NODE REFERENCES DEBUG ===")
	print("Background:", background != null)
	print("Header:", header != null)
	print("InstructionText:", instruction_text != null)
	print("ScrambledLetters:", scrambled_letters != null)
	print("HintImage:", hint_image != null)
	print("AnswerInput:", answer_input != null, " Type:", answer_input.get_class() if answer_input else "NULL")
	print("TimerBar:", timer_bar != null)
	print("TimerLabel:", timer_label != null)
	print("SubmitButton:", submit_button != null, " Type:", submit_button.get_class() if submit_button else "NULL")
	print("ResultContainer:", result_container != null)
	print("ResultText:", result_text != null)
	print("NextButton:", next_button != null)
	
	# 🎯 PERIKSA DETAIL ANSWER_INPUT
	if answer_input:
		print("🔍 AnswerInput Details:")
		print("   Type:", answer_input.get_class())
		print("   Is LineEdit:", answer_input is LineEdit)
		print("   Editable:", answer_input.editable)
		print("   Visible:", answer_input.visible)
	else:
		print("❌ AnswerInput is NULL - this will cause problems!")
		create_fallback_line_edit()
	
	# 🎯 PERIKSA DETAIL SUBMIT_BUTTON
	if submit_button:
		print("🔍 SubmitButton Details:")
		print("   Type:", submit_button.get_class())
		print("   Disabled:", submit_button.disabled)
		print("   Visible:", submit_button.visible)
		print("   Has pressed signal:", submit_button.pressed != null)
	else:
		print("❌ SubmitButton is NULL - this will cause problems!")

func setup_ui_properties():
	print("📝 Setting up UI properties...")
	
	# Setup Background
	if background:
		background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		print("✅ Background properties set")
	
	# Setup Header
	if header:
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 28)
		header.add_theme_color_override("font_color", Color.GOLD)
		header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		print("✅ Header properties set")
	
	# Setup PuzzleContainer
	var puzzle_container = $UI/PuzzleContainer as Panel
	if puzzle_container:
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
		puzzle_container.add_theme_stylebox_override("panel", panel_style)
		print("✅ PuzzleContainer properties set")
	
	# Setup InstructionText
	if instruction_text:
		instruction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_text.add_theme_font_size_override("font_size", 18)
		instruction_text.add_theme_color_override("font_color", Color.WHITE)
		print("✅ InstructionText properties set")
	
	# Setup ScrambledLetters
	if scrambled_letters:
		scrambled_letters.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scrambled_letters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scrambled_letters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		scrambled_letters.add_theme_font_size_override("font_size", 22)
		scrambled_letters.add_theme_color_override("font_color", Color.YELLOW)
		print("✅ ScrambledLetters properties set")
	
	# Setup HintImage
	if hint_image:
		hint_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		hint_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hint_image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var puzzle_data = logic_puzzles[0]
		var hint_texture = load(puzzle_data["hint_image"])
		if hint_texture:
			hint_image.texture = hint_texture
			hint_image.modulate = Color(1, 1, 1, 1)
			print("✅ Hint image loaded successfully:", puzzle_data["hint_image"])
		else:
			print("❌ Cannot load hint image:", puzzle_data["hint_image"])
			create_image_placeholder(hint_image, "Gambar Rumah Adat\n(Blur)")
		
		print("✅ HintImage properties set")
	
	# 🎯 PERBAIKAN KRITIS: SETUP ANSWER INPUT DENGAN BENAR
	setup_answer_input()
	
	# Setup TimerBar
	if timer_bar:
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color.GREEN
		fill_style.corner_radius_top_left = 5
		fill_style.corner_radius_top_right = 5
		fill_style.corner_radius_bottom_right = 5
		fill_style.corner_radius_bottom_left = 5
		timer_bar.add_theme_stylebox_override("fill", fill_style)
		print("✅ TimerBar properties set")
	
	# Setup TimerLabel
	if timer_label:
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timer_label.add_theme_font_size_override("font_size", 16)
		timer_label.add_theme_color_override("font_color", Color.WHITE)
		print("✅ TimerLabel properties set")
	
	# 🎯 PERBAIKAN: SETUP SUBMIT BUTTON DENGAN VISUAL FEEDBACK
	setup_submit_button()
	
	# Setup ResultContainer
	if result_container:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
		panel_style.border_color = Color.GOLD
		panel_style.border_width_left = 4
		panel_style.border_width_top = 4
		panel_style.border_width_right = 4
		panel_style.border_width_bottom = 4
		panel_style.corner_radius_top_left = 15
		panel_style.corner_radius_top_right = 15
		panel_style.corner_radius_bottom_right = 15
		panel_style.corner_radius_bottom_left = 15
		result_container.add_theme_stylebox_override("panel", panel_style)
		print("✅ ResultContainer properties set")
	
	# Setup ResultText
	if result_text:
		result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		result_text.add_theme_font_size_override("font_size", 16)
		result_text.add_theme_color_override("font_color", Color.WHITE)
		print("✅ ResultText properties set")
	
	# Setup NextButton
	if next_button:
		next_button.add_theme_font_size_override("font_size", 14)
		var next_button_style = StyleBoxFlat.new()
		next_button_style.bg_color = Color(0.2, 0.6, 0.2)
		next_button_style.border_color = Color.WHITE
		next_button_style.border_width_left = 2
		next_button_style.border_width_top = 2
		next_button_style.border_width_right = 2
		next_button_style.border_width_bottom = 2
		next_button_style.corner_radius_top_left = 8
		next_button_style.corner_radius_top_right = 8
		next_button_style.corner_radius_bottom_right = 8
		next_button_style.corner_radius_bottom_left = 8
		next_button.add_theme_stylebox_override("normal", next_button_style)
		print("✅ NextButton properties set")

# 🎯 FUNCTION BARU: SETUP ANSWER INPUT YANG ROBUST
func setup_answer_input():
	if answer_input:
		if answer_input is LineEdit:
			print("✅ AnswerInput is correctly a LineEdit")
			
			# Setup properties
			answer_input.placeholder_text = "Masukan Jawaban...."
			answer_input.add_theme_font_size_override("font_size", 18)
			answer_input.add_theme_color_override("font_color", Color.WHITE)
			answer_input.max_length = 50
			
			# 🎯 HUBUNGKAN SINYAL TEXT_CHANGED
			if not answer_input.text_changed.is_connected(_on_answer_changed):
				answer_input.text_changed.connect(_on_answer_changed)
				print("✅ AnswerInput text_changed signal connected")
			else:
				print("ℹ️ AnswerInput text_changed already connected")
			
			# Style untuk LineEdit
			var input_style = StyleBoxFlat.new()
			input_style.bg_color = Color(0.1, 0.1, 0.2)
			input_style.border_color = Color.WHITE
			input_style.border_width_left = 2
			input_style.border_width_top = 2
			input_style.border_width_right = 2
			input_style.border_width_bottom = 2
			input_style.corner_radius_top_left = 8
			input_style.corner_radius_top_right = 8
			input_style.corner_radius_bottom_right = 8
			input_style.corner_radius_bottom_left = 8
			answer_input.add_theme_stylebox_override("normal", input_style)
			
			print("✅ AnswerInput (LineEdit) properties set successfully")
		else:
			print("❌ AnswerInput is NOT a LineEdit! It's:", answer_input.get_class())
			create_fallback_line_edit()
	else:
		print("❌ AnswerInput is null, creating fallback...")
		create_fallback_line_edit()

# 🎯 FUNCTION BARU: SETUP SUBMIT BUTTON DENGAN FEEDBACK VISUAL
func setup_submit_button():
	if submit_button:
		print("✅ Setting up SubmitButton...")
		
		# Set initial state
		submit_button.disabled = true
		submit_button.focus_mode = Control.FOCUS_ALL
		
		# 🎯 VISUAL FEEDBACK UNTUK TextureButton
		if submit_button is TextureButton:
			print("✅ SubmitButton is TextureButton - setting up visual feedback")
			
			# Modulate untuk state berbeda
			submit_button.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent ketika disabled
			
			# StyleBox untuk berbagai state (jika supported)
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.2, 0.4, 0.8, 0.8)
			normal_style.border_color = Color.WHITE
			normal_style.border_width_left = 2
			normal_style.border_width_top = 2
			normal_style.border_width_right = 2
			normal_style.border_width_bottom = 2
			normal_style.corner_radius_top_left = 10
			normal_style.corner_radius_top_right = 10
			normal_style.corner_radius_bottom_right = 10
			normal_style.corner_radius_bottom_left = 10
			
			var hover_style = normal_style.duplicate()
			hover_style.bg_color = Color(0.3, 0.5, 0.9, 0.9)
			
			var pressed_style = normal_style.duplicate()
			pressed_style.bg_color = Color(0.1, 0.3, 0.7, 1.0)
			
			var disabled_style = normal_style.duplicate()
			disabled_style.bg_color = Color(0.5, 0.5, 0.5, 0.5)
			disabled_style.border_color = Color(0.7, 0.7, 0.7)
			
			# Apply styles
			submit_button.add_theme_stylebox_override("normal", normal_style)
			submit_button.add_theme_stylebox_override("hover", hover_style)
			submit_button.add_theme_stylebox_override("pressed", pressed_style)
			submit_button.add_theme_stylebox_override("disabled", disabled_style)
			
		else:
			# Fallback untuk Button biasa
			print("ℹ️ SubmitButton is regular Button")
			submit_button.text = "CEK JAWABAN"
			submit_button.add_theme_font_size_override("font_size", 16)
			
			var button_style = StyleBoxFlat.new()
			button_style.bg_color = Color(0.2, 0.4, 0.8)
			button_style.border_color = Color.WHITE
			button_style.border_width_left = 2
			button_style.border_width_top = 2
			button_style.border_width_right = 2
			button_style.border_width_bottom = 2
			button_style.corner_radius_top_left = 10
			button_style.corner_radius_top_right = 10
			button_style.corner_radius_bottom_right = 10
			button_style.corner_radius_bottom_left = 10
			submit_button.add_theme_stylebox_override("normal", button_style)
		
		print("✅ SubmitButton properties set")
	else:
		print("❌ SubmitButton is null in setup_submit_button")

# 🎯 FUNCTION BARU: BUAT FALLBACK LINEEDIT
func create_fallback_line_edit():
	print("🔄 Creating fallback LineEdit...")
	
	var new_line_edit = LineEdit.new()
	new_line_edit.name = "AnswerInput"
	
	# Position the LineEdit
	new_line_edit.anchor_left = 0.25
	new_line_edit.anchor_top = 0.7
	new_line_edit.anchor_right = 0.75
	new_line_edit.anchor_bottom = 0.75
	new_line_edit.offset_left = 0
	new_line_edit.offset_top = 0
	new_line_edit.offset_right = 0
	new_line_edit.offset_bottom = 0
	
	# Setup properties
	new_line_edit.placeholder_text = "Masukan Jawaban...."
	new_line_edit.add_theme_font_size_override("font_size", 18)
	new_line_edit.add_theme_color_override("font_color", Color.WHITE)
	new_line_edit.max_length = 50
	
	# 🎯 HUBUNGKAN SINYAL
	if not new_line_edit.text_changed.is_connected(_on_answer_changed):
		new_line_edit.text_changed.connect(_on_answer_changed)
	
	# Style
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.1, 0.1, 0.2)
	input_style.border_color = Color.WHITE
	input_style.border_width_left = 2
	input_style.border_width_top = 2
	input_style.border_width_right = 2
	input_style.border_width_bottom = 2
	input_style.corner_radius_top_left = 8
	input_style.corner_radius_top_right = 8
	input_style.corner_radius_bottom_right = 8
	input_style.corner_radius_bottom_left = 8
	new_line_edit.add_theme_stylebox_override("normal", input_style)
	
	# Add to UI
	if has_node("UI"):
		$UI.add_child(new_line_edit)
		answer_input = new_line_edit
		print("✅ Fallback LineEdit created and added to UI")
	else:
		add_child(new_line_edit)
		answer_input = new_line_edit
		print("✅ Fallback LineEdit created and added to root")

func create_image_placeholder(texture_rect: TextureRect, text: String):
	for child in texture_rect.get_children():
		child.queue_free()
	
	texture_rect.texture = null
	texture_rect.modulate = Color(0.2, 0.2, 0.3)
	
	var container = ColorRect.new()
	container.color = Color(0.1, 0.1, 0.2, 0.8)
	container.anchor_left = 0.1
	container.anchor_top = 0.1
	container.anchor_right = 0.9
	container.anchor_bottom = 0.9
	texture_rect.add_child(container)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = 1
	label.anchor_bottom = 1
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(label)

func initialize_level():
	print("🔄 Initializing Level 2...")
	
	# Setup interactions
	setup_buttons()
	
	# Pastikan ResultContainer hidden di awal
	if result_container:
		result_container.visible = false
	if next_button:
		next_button.visible = false
	
	# Mulai dengan puzzle
	start_puzzle(0)
	
	print("✅ Level 2 initialized")

func setup_buttons():
	print("🔗 Setting up buttons...")
	
	# 🎯 PERBAIKAN KRITIS: HUBUNGKAN SUBMIT BUTTON DENGAN ERROR HANDLING
	if submit_button:
		# Hapus existing connections untuk menghindari duplicate
		if submit_button.pressed.is_connected(_on_submit_pressed):
			submit_button.pressed.disconnect(_on_submit_pressed)
			print("ℹ️ Disconnected existing submit_button connection")
		
		# Connect signal dengan error handling
		var connect_result = submit_button.pressed.connect(_on_submit_pressed)
		if connect_result == OK:
			print("✅ SubmitButton pressed signal connected successfully")
		else:
			print("❌ Failed to connect SubmitButton pressed signal, error:", connect_result)
		
		# 🎯 DEBUG: Cek status button
		print("🔍 SubmitButton status after setup:")
		print("   Disabled:", submit_button.disabled)
		print("   Visible:", submit_button.visible)
		print("   Has pressed signal:", submit_button.pressed != null)
	else:
		print("❌ SubmitButton is null in setup_buttons - this is critical!")
		
	if next_button:
		if next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.disconnect(_on_next_pressed)
		next_button.pressed.connect(_on_next_pressed)
		print("✅ NextButton connected")
	else:
		print("❌ NextButton is null")
	
	print("✅ Buttons setup completed")

func start_puzzle(puzzle_index):
	print("🔍 Starting puzzle ", puzzle_index)
	
	if puzzle_index < logic_puzzles.size():
		current_puzzle_index = puzzle_index
		var puzzle_data = logic_puzzles[puzzle_index]
		
		if instruction_text:
			instruction_text.text = puzzle_data["instruction"]
			print("✅ Instruction text set")
		
		if scrambled_letters:
			var letters_text = puzzle_data["scrambled_letters"]
			if letters_text.length() > 50:
				var chunks = []
				var words = letters_text.split(" ")
				var current_line = ""
				for word in words:
					if (current_line + " " + word).length() > 25:
						chunks.append(current_line.strip_edges())
						current_line = word
					else:
						current_line += " " + word
				chunks.append(current_line.strip_edges())
				letters_text = "\n".join(chunks)
			
			scrambled_letters.text = "Huruf Acak:\n" + letters_text
			print("✅ Scrambled letters set")
		
		# 🎯 PERBAIKAN: RESET ANSWER INPUT DENGAN FOCUS
		if answer_input:
			answer_input.text = ""
			answer_input.placeholder_text = "Masukan Jawaban...."
			answer_input.editable = true
			answer_input.grab_focus()  # 🎯 OTOMATIS FOKUS KE INPUT
			print("✅ Answer input cleared and focused")
		else:
			print("❌ AnswerInput is null in start_puzzle!")
		
		if hint_image:
			var hint_texture = load(puzzle_data["hint_image"])
			if hint_texture:
				hint_image.texture = hint_texture
				hint_image.visible = true
				hint_image.modulate = Color(1, 1, 1, 1)
				print("✅ Hint image loaded")
			else:
				print("❌ Cannot load hint image, using placeholder")
				create_image_placeholder(hint_image, "Gambar Rumah Adat\n(Blur)")
				hint_image.visible = true
		
		if header:
			header.text = "PULAU SUMATERA - LEVEL 2\nTEKA-TEKI LOGIKA"
			print("✅ Header text set")
		
		# Reset timer
		timer_value = total_timer_time
		if timer_bar:
			timer_bar.value = 100
			var fill_style = timer_bar.get_theme_stylebox("fill").duplicate()
			fill_style.bg_color = Color.GREEN
			timer_bar.add_theme_stylebox_override("fill", fill_style)
		if timer_label:
			timer_label.text = "Waktu: " + str(timer_value) + "s"
		
		# 🎯 PERBAIKAN: RESET SUBMIT BUTTON STATE DENGAN DEBUG
		if submit_button:
			submit_button.disabled = true
			submit_button.visible = true
			if submit_button is TextureButton:
				submit_button.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent ketika disabled
			print("🔍 SubmitButton reset - Disabled:", submit_button.disabled)
		else:
			print("❌ SubmitButton is null in start_puzzle!")
		
		if result_container:
			result_container.visible = false
		if next_button:
			next_button.visible = false
		
		# Reset completion flag
		level_completed = false
		
		# Start timer
		timer_running = true
		
		print("🎯 Puzzle started - Timer:", timer_value, "s")
		print("💡 Correct answer should be:", puzzle_data["correct_answer"])
	else:
		finish_level()

func _process(delta):
	if timer_running:
		timer_value -= delta
		if timer_bar:
			timer_bar.value = (timer_value / total_timer_time) * 100
			
			if timer_value < (total_timer_time * 0.2):
				var fill_style = timer_bar.get_theme_stylebox("fill").duplicate()
				fill_style.bg_color = Color.RED
				timer_bar.add_theme_stylebox_override("fill", fill_style)
			elif timer_value < (total_timer_time * 0.4):
				var fill_style = timer_bar.get_theme_stylebox("fill").duplicate()
				fill_style.bg_color = Color.YELLOW
				timer_bar.add_theme_stylebox_override("fill", fill_style)
		
		if timer_label:
			timer_label.text = "Waktu: " + str(ceil(timer_value)) + "s"
		
		if timer_value <= 0:
			timer_running = false
			on_timeout()

func on_timeout():
	print("⏰ Timeout!")
	
	if answer_input:
		answer_input.editable = false
	if submit_button:
		submit_button.disabled = true
		if submit_button is TextureButton:
			submit_button.modulate = Color(1, 1, 1, 0.5)
	
	var puzzle_data = logic_puzzles[current_puzzle_index]
	if result_text:
		var timeout_text = "WAKTU HABIS! ⏰\nJawaban yang benar:\n" + puzzle_data["correct_answer"]
		result_text.text = timeout_text
		result_text.modulate = Color(1, 0.5, 0.5)
	if result_container:
		result_container.visible = true
	if next_button:
		next_button.text = "Kembali ke Peta"
		next_button.visible = true

# 🎯 PERBAIKAN KRITIS: FUNCTION INI HARUS DIPANGGIL KETIKA TEXT BERUBAH
func _on_answer_changed(new_text):
	print("🔍 Answer changed:'", new_text, "'")
	print("🔍 Text length:", new_text.length())
	print("🔍 Text stripped:'", new_text.strip_edges(), "'")
	print("🔍 Is empty:", new_text.strip_edges().is_empty())
	
	if submit_button:
		var has_text = not new_text.strip_edges().is_empty()
		submit_button.disabled = not has_text
		
		# 🎯 UPDATE VISUAL UNTUK TextureButton
		if submit_button is TextureButton:
			if submit_button.disabled:
				submit_button.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent ketika disabled
			else:
				submit_button.modulate = Color(1, 1, 1, 1)    # Full opaque ketika enabled
		
		print("🔍 SubmitButton updated - Disabled:", submit_button.disabled, " HasText:", has_text)
	else:
		print("❌ SubmitButton is null in _on_answer_changed!")

func _on_submit_pressed():
	print("🎯 Submit button pressed!")
	print("🔍 Current state - Timer running:", timer_running, " Level completed:", level_completed)
	
	if not timer_running:
		print("⏰ Timer not running, ignoring submit")
		return
	
	if level_completed:
		print("✅ Level already completed, ignoring submit")
		return
	
	timer_running = false
	
	var user_answer = ""
	if answer_input:
		user_answer = answer_input.text.strip_edges()
	else:
		print("❌ AnswerInput is null!")
		return
	
	var puzzle_data = logic_puzzles[current_puzzle_index]
	
	print("🔍 Checking answer:")
	print("   User answer:'", user_answer, "'")
	print("   Correct answer:'", puzzle_data["correct_answer"], "'")
	
	var normalized_user_answer = user_answer.to_lower().replace("  ", " ").strip_edges()
	var normalized_correct_answer = puzzle_data["correct_answer"].to_lower().replace("  ", " ").strip_edges()
	
	var is_correct = (normalized_user_answer == normalized_correct_answer)
	
	print("🔍 Comparison result:")
	print("   Normalized user:'", normalized_user_answer, "'")
	print("   Normalized correct:'", normalized_correct_answer, "'")
	print("   Is correct:", is_correct)
	
	if is_correct:
		score = 1
		print("✅ Correct answer! Score:", score)
		reveal_clear_image()
		level_completed = true
		update_main_progress()
	else:
		score = 0
		print("❌ Wrong answer! Score:", score)
	
	show_result(is_correct, puzzle_data, user_answer)

# 🎯 FUNCTION BARU: UPDATE PROGRESS KE MAIN SYSTEM
func update_main_progress():
	print("🔄 Updating progress to Main system...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		# Hitung stars berdasarkan performance
		var stars_earned = calculate_stars()
		var knowledge_points = calculate_knowledge_points()
		
		print("⭐ Calculating rewards:")
		print("   Score:", score)
		print("   Time remaining:", timer_value)
		print("   Stars earned:", stars_earned)
		print("   Knowledge points:", knowledge_points)
		
		# 🎯 PERBAIKAN: HILANGKAN AUTO-EXIT, biarkan player tekan tombol sendiri
		# Panggil complete_level di Main system TANPA auto return to map
		main.complete_level("sumatra", 2, stars_earned, knowledge_points)
		print("✅ Progress updated to Main system")
	else:
		print("❌ Cannot find Main node or complete_level method")

# 🎯 FUNCTION BARU: HITUNG STAR REWARD
func calculate_stars() -> int:
	# Sistem bintang berdasarkan waktu tersisa dan correctness
	if score == 0:
		return 0  # Tidak dapat bintang jika salah
	
	var time_ratio = timer_value / total_timer_time
	
	if time_ratio > 0.7:  # Selesai dalam 30% waktu pertama
		return 3
	elif time_ratio > 0.4:  # Selesai dalam 30-60% waktu
		return 2
	else:  # Selesai dalam sisa waktu
		return 1

# 🎯 FUNCTION BARU: HITUNG KNOWLEDGE POINTS
func calculate_knowledge_points() -> int:
	# Knowledge points berdasarkan performance
	var base_points = 50
	var time_bonus = int((timer_value / total_timer_time) * 30)  # Bonus hingga 30 points
	return base_points + time_bonus

func reveal_clear_image():
	print("🎨 Revealing clear image...")
	
	if hint_image:
		var puzzle_data = logic_puzzles[current_puzzle_index]
		var clear_texture = load(puzzle_data["correct_image"])
		
		if clear_texture:
			hint_image.texture = clear_texture
			print("✅ Image changed to clear version")
		else:
			print("❌ Cannot load clear image")
			create_image_placeholder(hint_image, "Gambar Rumah Adat\n(Jelas)")

func show_result(is_correct, puzzle_data, user_answer):
	print("📊 Showing result...")
	
	if answer_input:
		answer_input.editable = false
	if submit_button:
		submit_button.disabled = true
		if submit_button is TextureButton:
			submit_button.modulate = Color(1, 1, 1, 0.5)
	
	var result_message = ""
	if is_correct:
		result_message = "SELAMAT! 🎉\nJAWABAN ANDA BENAR!\n"
		
		var stars = calculate_stars()
		var knowledge_points = calculate_knowledge_points()
		result_message += "⭐ Bintang: " + str(stars) + "/3\n"
		result_message += "📚 Poin: +" + str(knowledge_points) + "\n"
		
		# 🎯 TAMBAHKAN INFO PULAU BARU
		result_message += "🔓 KUNCI DIPEROLEH!\n"
		result_message += "Pulau Jawa sekarang terbuka!\n"
		
		if result_text:
			result_text.modulate = Color(0.5, 1, 0.5)
	else:
		result_message = "JAWABAN MASIH SALAH! ❌\n"
		result_message += "Jawaban Anda: " + user_answer + "\n"
		result_message += "Jawaban yang benar: " + puzzle_data["correct_answer"] + "\n"
		if result_text:
			result_text.modulate = Color(1, 0.5, 0.5)
	
	result_message += puzzle_data["fact"]
	
	if result_text:
		result_text.text = result_message
	if result_container:
		result_container.visible = true
	if next_button:
		next_button.text = "Kembali ke Peta"
		next_button.visible = true

func _on_next_pressed():
	print("🗺️ Returning to Map...")
	
	if level_completed:
		print("✅ Level completed, progress should be saved")
	else:
		print("⚠️ Level not completed, no progress to save")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("show_map"):
		main.show_map()
	else:
		print("❌ Cannot find Main node or show_map method")
		# Fallback: langsung ke MapScene
		get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func finish_level():
	print("🎯 Level 2 completed! Final score:", score, "/", logic_puzzles.size())
	show_completion_screen()

func show_completion_screen():
	print("🏆 Showing completion screen")
	
	if header:
		header.text = "LEVEL 2 SELESAI!"
	
	if instruction_text:
		var completion_text = "Skor Akhir: " + str(score) + "/" + str(logic_puzzles.size()) + "\n"
		if score == 1:
			completion_text += "⭐️⭐️⭐️ SEMPURNA! ⭐️⭐️⭐️\n"
			completion_text += "Selamat! Anda berhasil memecahkan teka-teki!\n"
			completion_text += "Sekarang Anda telah mengenal Rumah Selaso Jatuh Kembar.\n"
			
			completion_text += "🔓 PULAU BARU TELAH TERBUKA!\n"
			completion_text += "Sekarang Anda dapat menjelajahi Pulau Jawa!"
		else:
			completion_text += "Tetap semangat! Pelajari lagi budaya Sumatera.\n"
			completion_text += "Jawaban yang benar: Rumah Selaso Jatuh Kembar"
		
		instruction_text.text = completion_text
		instruction_text.add_theme_font_size_override("font_size", 18)
	
	if scrambled_letters:
		scrambled_letters.visible = false
	if answer_input:
		answer_input.visible = false
	if timer_bar:
		timer_bar.visible = false
	if timer_label:
		timer_label.visible = false
	if submit_button:
		submit_button.visible = false
	
	if hint_image:
		hint_image.visible = true
	
	if next_button:
		next_button.text = "Kembali ke Peta"
		next_button.visible = true
	if result_container:
		result_container.visible = true

# 🎯 FUNCTION BARU: TAMPILAN UNTUK LEVEL YANG SUDAH COMPLETED
func show_already_completed_screen():
	print("🔄 Showing already completed screen")
	
	var main = get_node_or_null("/root/Main")
	var stars = 0
	var knowledge_points = 0
	var unlocked_islands = []
	
	if main and main.has_method("get_island_progress"):
		var progress = main.get_island_progress("sumatra")
		if progress:
			stars = progress.get("stars_earned", 0)
			knowledge_points = 100  # Estimate
	
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data and player_data.has("unlocked_islands"):
			unlocked_islands = player_data["unlocked_islands"]
	
	if header:
		header.text = "PULAU SUMATERA - LEVEL 2\nSUDAH SELESAI!"
	if instruction_text:
		instruction_text.text = "Kamu sudah menyelesaikan level ini!\n"
		instruction_text.text += "⭐ Bintang: " + str(stars) + "/3\n"
		instruction_text.text += "📚 Poin: " + str(knowledge_points) + "\n"
		
		if "jawa" in unlocked_islands:
			instruction_text.text += "🔓 Pulau Jawa sudah terbuka!\n"
		else:
			instruction_text.text += "🔒 Selesaikan level untuk membuka pulau berikutnya!\n"
			
		instruction_text.text += "Tekan tombol untuk kembali ke peta"
		instruction_text.add_theme_font_size_override("font_size", 20)
	
	if scrambled_letters:
		scrambled_letters.visible = false
	if answer_input:
		answer_input.visible = false
	if timer_bar:
		timer_bar.visible = false
	if timer_label:
		timer_label.visible = false
	if submit_button:
		submit_button.visible = false
	
	if next_button:
		next_button.text = "Kembali ke Peta"
		next_button.visible = true
	if result_container:
		result_container.visible = true
	
	if next_button:
		if next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.disconnect(_on_next_pressed)
		next_button.pressed.connect(_on_next_pressed)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			print("🔑 ENTER key pressed")
			if submit_button and not submit_button.disabled and timer_running:
				print("🎯 Submitting via ENTER key")
				_on_submit_pressed()
			elif next_button and next_button.visible:
				print("➡️ Continuing via ENTER key")
				_on_next_pressed()
		elif event.keycode == KEY_ESCAPE:
			print("🔙 ESC key pressed - returning to map")
			var main = get_node_or_null("/root/Main")
			if main and main.has_method("show_map"):
				main.show_map()
			else:
				get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _exit_tree():
	print("🏝️ Pulau Sumatera Level 2 exiting...")
	print("📊 FINAL STATE:")
	print("   Level completed:", level_completed)
	print("   Score:", score)
	print("   Time remaining:", timer_value)
	print("   Timer running:", timer_running)
