extends Control

@onready var header = $UI/Header
@onready var game_container = $UI/GameContainer
@onready var result_container = $UI/ResultContainer
@onready var result_label = $UI/ResultContainer/ResultLabel
@onready var next_island_btn = $UI/NextIslandBtn
@onready var restart_btn = $UI/RestartBtn
@onready var timer_label = $UI/TimerLabel
@onready var moves_label = $UI/MovesLabel

var papua_animals = [
	{
		"name": "Burung Cendrawasih",
		"image": "res://assets/images/puzzles/cendrawasih.png",
		"fact": "Terdapat lebih dari 40 spesies Cendrawasih di Papua!"
	},
	{
		"name": "Kasuari",
		"image": "res://assets/images/puzzles/kasuari.png",
		"fact": "Kasuari dianggap sebagai burung paling berbahaya di dunia!"
	},
	{
		"name": "Kangguru Pohon",
		"image": "res://assets/images/puzzles/kangguru_pohon.png",
		"fact": "Bisa melompat dari ketinggian 18 meter tanpa cedera!"
	},
	{
		"name": "Mambruk",
		"image": "res://assets/images/puzzles/mambruk.png",
		"fact": "Merpati mahkota yang sangat langka."
	},
	{
		"name": "Ikan Pelangi",
		"image": "res://assets/images/puzzles/ikan_pelangi.png",
		"fact": "Hanya hidup di perairan jernih Papua."
	}
]

var cards = []
var flipped_cards = []
var matched_pairs = 0
var total_pairs = 0
var moves_count = 0
var game_time = 0.0
var timer_running = false
var level_completed = false
var progress_saved = false
var can_flip = true

func _ready():
	print("🌴 Pulau Papua Level 2 - Keanekaragaman Hayati Loaded")
	
	# 🎯 PERBAIKAN: Gunakan metode yang konsisten seperti pulau lain
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("get_island_progress"):
		var progress = main.get_island_progress("papua")
		if progress and progress.get("level2_completed", false):
			print("🔄 Level 2 sudah selesai, menunjukkan completion screen...")
			call_deferred("show_already_completed_screen")
			return
	else:
		# Fallback untuk metode lama
		if main and main.has_method("get_player_data"):
			var player_data = main.get_player_data()
			if player_data:
				var level_key = "papua_2"
				if player_data.has("completed_levels") and level_key in player_data["completed_levels"]:
					print("🔄 Level 2 Papua sudah selesai, menunjukkan completion screen...")
					call_deferred("show_already_completed_screen")
					return
	
	initialize_game()

func initialize_game():
	# Reset game state
	cards.clear()
	flipped_cards.clear()
	matched_pairs = 0
	moves_count = 0
	game_time = 0
	timer_running = true
	level_completed = false
	progress_saved = false
	can_flip = true
	
	# Setup UI
	header.text = "PULAU PAPUA - LEVEL 2"
	
	# Clear game container
	for child in game_container.get_children():
		child.queue_free()
	
	# Create card pairs (gunakan 5 hewan = 10 kartu)
	create_card_pairs()
	
	# Setup UI labels
	update_ui_labels()
	
	# Reset UI state
	result_container.visible = false
	next_island_btn.hide()
	restart_btn.hide()
	
	print("🃏 Game initialized - Total pairs: ", total_pairs)

func create_card_pairs():
	var animals = papua_animals.duplicate()
	animals.shuffle()
	
	# Ambil 5 hewan (untuk 10 kartu)
	var selected = animals.slice(0, 5)
	total_pairs = selected.size()
	
	var card_data = []
	for animal in selected:
		card_data.append({"type": "image", "animal": animal})
		card_data.append({"type": "name", "animal": animal})
	
	card_data.shuffle()
	
	# Gunakan CenterContainer untuk memusatkan grid
	var center = CenterContainer.new()
	game_container.add_child(center)
	
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	center.add_child(grid)
	
	for i in card_data.size():
		var card = create_card(card_data[i], i)
		grid.add_child(card)
		cards.append(card)
	
	print("🎴 Created ", len(cards), " cards with ", total_pairs, " pairs")

func create_card(info, card_id):
	var panel = Panel.new()
	panel.name = "Card_" + str(card_id)
	panel.custom_minimum_size = Vector2(100, 130)
	panel.size = Vector2(100, 130)
	panel.set_meta("card_id", card_id)
	panel.set_meta("info", info)
	panel.set_meta("flipped", false)
	panel.set_meta("matched", false)
	panel.set_meta("animal_name", info["animal"]["name"])
	panel.set_meta("card_type", info["type"])
	
	# Card back style
	var back = StyleBoxFlat.new()
	back.bg_color = Color(0.2, 0.35, 0.2)
	back.border_color = Color(0.4, 0.6, 0.4)
	back.border_width_left = 2
	back.border_width_top = 2
	back.border_width_right = 2
	back.border_width_bottom = 2
	back.corner_radius_top_left = 10
	back.corner_radius_top_right = 10
	back.corner_radius_bottom_left = 10
	back.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", back)
	
	# Front content
	var front = VBoxContainer.new()
	front.name = "FrontContent"
	front.visible = false
	front.alignment = BoxContainer.ALIGNMENT_CENTER
	front.size = panel.size
	front.add_theme_constant_override("separation", 0)
	panel.add_child(front)
	
	if info["type"] == "image":
		# Container untuk gambar agar bisa di-center
		var image_container = CenterContainer.new()
		image_container.custom_minimum_size = Vector2(90, 90)
		front.add_child(image_container)
		
		var tex = TextureRect.new()
		
		# Coba load texture
		var texture_path = info["animal"]["image"]
		var texture = load(texture_path)
		
		if texture == null:
			# Coba path alternatif
			print("⚠️ Gambar tidak ditemukan di path: ", texture_path)
			var alt_paths = [
				"res://assets/images/puzzles/" + info["animal"]["name"].to_lower().replace(" ", "_") + ".png",
				"res://assets/images/papua/" + info["animal"]["name"].to_lower().replace(" ", "_") + ".png",
				"res://assets/images/" + info["animal"]["name"].to_lower().replace(" ", "_") + ".png"
			]
			
			for alt_path in alt_paths:
				print("Mencoba path alternatif: ", alt_path)
				texture = load(alt_path)
				if texture != null:
					print("✅ Gambar ditemukan di: ", alt_path)
					break
		
		if texture != null:
			tex.texture = texture
			tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = Vector2(80, 80)
			tex.size = Vector2(80, 80)
		else:
			print("❌ Gagal memuat gambar untuk: ", info["animal"]["name"])
			# Buat placeholder warna dengan teks
			var placeholder_color = Color(0.5, 0.3, 0.1)
			var placeholder_image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
			placeholder_image.fill(placeholder_color)
			var placeholder_texture = ImageTexture.create_from_image(placeholder_image)
			tex.texture = placeholder_texture
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = Vector2(80, 80)
			tex.size = Vector2(80, 80)
		
		image_container.add_child(tex)
		
		# Label untuk teks "Gambar"
		var label_container = CenterContainer.new()
		front.add_child(label_container)
		
		var label = Label.new()
		label.text = "Gambar"
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color.WHITE)
		label_container.add_child(label)
		
	else:
		# Kartu nama - isi penuh dengan teks
		var name_container = CenterContainer.new()
		name_container.size = panel.size
		front.add_child(name_container)
		
		var lbl = Label.new()
		lbl.text = info["animal"]["name"]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(90, 120)
		name_container.add_child(lbl)
	
	# Connect signal untuk klik
	panel.gui_input.connect(_on_card_gui_input.bind(panel))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	return panel

func _on_card_gui_input(event, card_panel):
	if not can_flip:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if level_completed:
			return
		
		if card_panel.get_meta("flipped") or card_panel.get_meta("matched"):
			return
		
		flip_card(card_panel)

func flip_card(card):
	if not can_flip:
		return
	
	card.set_meta("flipped", true)
	card.get_child(0).visible = true
	flipped_cards.append(card)
	
	# Ganti style kartu menjadi front style
	var front_style = StyleBoxFlat.new()
	front_style.bg_color = Color(0.3, 0.4, 0.3, 1.0)
	front_style.border_color = Color(0.6, 0.8, 0.6)
	front_style.border_width_left = 2
	front_style.border_width_top = 2
	front_style.border_width_right = 2
	front_style.border_width_bottom = 2
	front_style.corner_radius_top_left = 10
	front_style.corner_radius_top_right = 10
	front_style.corner_radius_bottom_left = 10
	front_style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", front_style)
	
	print("🃏 Card flipped: ", card.get_meta("animal_name"), " (", card.get_meta("card_type"), ")")
	
	# Cek jika sudah ada 2 kartu terbuka
	if flipped_cards.size() == 2:
		moves_count += 1
		update_ui_labels()
		check_match()

func check_match():
	can_flip = false
	
	if flipped_cards.size() != 2:
		can_flip = true
		return
	
	var card1 = flipped_cards[0]
	var card2 = flipped_cards[1]
	
	var name1 = card1.get_meta("animal_name")
	var name2 = card2.get_meta("animal_name")
	var type1 = card1.get_meta("card_type")
	var type2 = card2.get_meta("card_type")
	
	print("🔍 Checking match:")
	print("  Card 1: ", name1, " (", type1, ")")
	print("  Card 2: ", name2, " (", type2, ")")
	
	# Cek jika kedua kartu adalah pasangan (satu gambar, satu nama, untuk hewan yang sama)
	if name1 == name2 and type1 != type2:
		# Match found!
		card1.set_meta("matched", true)
		card2.set_meta("matched", true)
		matched_pairs += 1
		
		print("✅ Match found! ", name1, " - Pairs matched: ", matched_pairs, "/", total_pairs)
		
		# Highlight kartu yang cocok
		highlight_card(card1, true)
		highlight_card(card2, true)
		
		# Tunggu sebentar sebelum membersihkan
		await get_tree().create_timer(0.5).timeout
		
		# Cek jika game selesai
		if matched_pairs == total_pairs:
			timer_running = false
			level_completed = true
			handle_game_complete()
			can_flip = true
			return
		
		# Kosongkan flipped cards
		flipped_cards.clear()
		can_flip = true
		
	else:
		# No match
		print("❌ No match - ", name1, " vs ", name2)
		
		# Highlight kartu salah
		highlight_card(card1, false)
		highlight_card(card2, false)
		
		# Tunggu sebentar lalu balik kembali
		await get_tree().create_timer(1.0).timeout
		
		# Balik kartu kembali
		unflip_card(card1)
		unflip_card(card2)
		
		# Kosongkan flipped cards
		flipped_cards.clear()
		can_flip = true

func highlight_card(card_panel, is_correct):
	var highlight_style = StyleBoxFlat.new()
	
	if is_correct:
		highlight_style.bg_color = Color(0.1, 0.5, 0.1, 1.0)  # Hijau
		highlight_style.border_color = Color(0.4, 0.9, 0.4)
	else:
		highlight_style.bg_color = Color(0.5, 0.1, 0.1, 1.0)  # Merah
		highlight_style.border_color = Color(0.9, 0.4, 0.4)
	
	highlight_style.border_width_left = 3
	highlight_style.border_width_top = 3
	highlight_style.border_width_right = 3
	highlight_style.border_width_bottom = 3
	highlight_style.corner_radius_top_left = 10
	highlight_style.corner_radius_top_right = 10
	highlight_style.corner_radius_bottom_right = 10
	highlight_style.corner_radius_bottom_left = 10
	
	card_panel.add_theme_stylebox_override("panel", highlight_style)

func unflip_card(card):
	card.set_meta("flipped", false)
	card.get_child(0).visible = false
	
	# Kembalikan ke card back style
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.2, 0.35, 0.2)
	back_style.border_color = Color(0.4, 0.6, 0.4)
	back_style.border_width_left = 2
	back_style.border_width_top = 2
	back_style.border_width_right = 2
	back_style.border_width_bottom = 2
	back_style.corner_radius_top_left = 10
	back_style.corner_radius_top_right = 10
	back_style.corner_radius_bottom_left = 10
	back_style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", back_style)

func handle_game_complete():
	print("🎉 Game Complete!")
	print("⏱️ Time: ", game_time, "s")
	print("📊 Moves: ", moves_count)
	
	var stars = calculate_stars()
	var knowledge_points = calculate_knowledge_points()
	
	save_progress(stars, knowledge_points)
	
	await get_tree().create_timer(1.0).timeout
	show_result_screen(stars, knowledge_points)

func calculate_stars() -> int:
	# Berdasarkan waktu dan jumlah gerakan
	var time_score = 0
	var moves_score = 0
	
	# Skor waktu (dalam detik)
	if game_time <= 45:  # ≤ 45 detik
		time_score = 3
	elif game_time <= 90:  # ≤ 1.5 menit
		time_score = 2
	else:
		time_score = 1
	
	# Skor gerakan (minimal 10 gerakan untuk 5 pasang)
	var min_moves = total_pairs * 2  # Teoritis minimal = 10
	if moves_count <= min_moves + 4:  # ≤ 14 gerakan
		moves_score = 3
	elif moves_count <= min_moves + 8:  # ≤ 18 gerakan
		moves_score = 2
	else:
		moves_score = 1
	
	# Rata-rata skor
	var avg_score = (time_score + moves_score) / 2
	return int(avg_score)

func calculate_knowledge_points() -> int:
	var base_points = 100  # Base points untuk level 2
	
	# Bonus berdasarkan performa
	var time_bonus = max(0, 60 - game_time) * 2  # Bonus untuk waktu cepat
	var moves_bonus = max(0, 20 - moves_count) * 3  # Bonus untuk gerakan sedikit
	var stars_bonus = calculate_stars() * 20  # Bonus berdasarkan bintang
	
	return base_points + time_bonus + moves_bonus + stars_bonus

# 🎯 PERBAIKAN: Fungsi save_progress yang konsisten dengan pulau lain
func save_progress(stars: int, knowledge_points: int):
	print("💾 Saving Papua Level 2 progress...")
	
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("complete_level"):
		print("✅ Using Main.complete_level()")
		var success = main.complete_level("papua", 2, stars, knowledge_points)
		if success:
			progress_saved = true
			print("✅ Progress saved successfully via Main system!")
			print("   Island: papua, Level: 2")
			print("   Stars:", stars, ", Knowledge Points:", knowledge_points)
		else:
			print("⚠️ Main system save failed, using manual save...")
			manual_save_progress(stars, knowledge_points)
	else:
		print("❌ Main.complete_level() not available")
		manual_save_progress(stars, knowledge_points)

# 🎯 PERBAIKAN: Manual save yang konsisten
func manual_save_progress(stars: int, knowledge_points: int):
	print("🔧 Manual save for Papua Level 2...")
	
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
		saved_data["unlocked_islands"] = ["sumatra", "jawa", "kalimantan", "sulawesi", "papua"]
	if not saved_data.has("completed_islands"):
		saved_data["completed_islands"] = []
	
	# Mark level 2 as completed
	saved_data["completed_levels"]["papua_2"] = true
	
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
	var level1_completed = saved_data["completed_levels"].get("papua_1", false)
	var level2_completed = saved_data["completed_levels"].get("papua_2", false)
	
	if level1_completed and level2_completed and "papua" not in saved_data["completed_islands"]:
		saved_data["completed_islands"].append("papua")
		print("✅ Pulau Papua marked as completed")
		print("🏆 Selamat! Semua pulau telah diselesaikan!")
	
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

func show_result_screen(stars: int, points: int):
	result_container.visible = true
	
	# 🎯 PERBAIKAN: Teks hasil yang lebih ringkas
	var result_text = "🎉 SELAMAT! 🎉\n"
	result_text += "Kamu berhasil mencocokkan semua hewan endemik Papua!\n\n"
	result_text += "📊 HASIL:\n"
	result_text += "• Waktu: " + format_time(game_time) + "\n"
	result_text += "• Gerakan: " + str(moves_count) + "\n"
	result_text += "• ⭐ Bintang: " + str(stars) + "/3\n"
	result_text += "• 📚 Poin: +" + str(points) + "\n\n"
	result_text += "💡 FAKTA: Kamu telah mempelajari 5 hewan endemik Papua!\n\n"
	
	# 🎯 PERBAIKAN: Ambil data dari Main system untuk informasi completion
	var main = get_node_or_null("/root/Main")
	var all_islands_completed = false
	
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data and player_data.has("completed_islands"):
			all_islands_completed = player_data["completed_islands"].size() >= 5  # Semua 5 pulau
	
	if progress_saved:
		result_text += "✅ Progress tersimpan!\n"
		if all_islands_completed:
			result_text += "🏆 SELAMAT! Semua pulau telah diselesaikan!\n"
			result_text += "Kamu adalah penjelajah budaya sejati Indonesia!"
		else:
			result_text += "🔓 Semua pulau telah terbuka!\n"
			result_text += "Kunjungi pulau lain untuk petualangan berikutnya!"
	else:
		result_text += "⚠️ Progress belum tersimpan!\n"
	
	result_label.text = result_text
	result_label.add_theme_font_size_override("font_size", 14)
	result_label.modulate = Color(0.7, 1, 0.7)
	
	# 🎯 PERBAIKAN: Ganti tombol dengan "Kembali ke Peta"
	next_island_btn.text = "Kembali ke Peta"
	next_island_btn.show()
	
	restart_btn.text = "Main Lagi"
	restart_btn.show()

func format_time(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]

func update_ui_labels():
	timer_label.text = "⏱️ Waktu: " + format_time(game_time)
	moves_label.text = "🃏 Gerakan: " + str(moves_count)

func _process(delta):
	if timer_running and not level_completed:
		game_time += delta
		update_ui_labels()

func _on_next_island_btn_pressed():
	# 🎯 PERBAIKAN: Kembali ke peta dengan metode yang sama seperti pulau lain
	print("🗺️ Returning to Map from Papua Level 2...")
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
	print("🔄 Restarting game...")
	initialize_game()

# 🎯 PERBAIKAN: Fungsi untuk menunjukkan screen "sudah selesai"
func show_already_completed_screen():
	print("🔄 Showing already completed screen for Papua Level 2")
	
	var main = get_node_or_null("/root/Main")
	var stars = 0
	var knowledge_points = 0
	var completed_islands = []
	var all_islands_completed = false
	
	# Ambil data dari Main system
	if main and main.has_method("get_player_data"):
		var player_data = main.get_player_data()
		if player_data:
			stars = player_data.get("total_stars", 0)
			knowledge_points = player_data.get("knowledge_points", 0)
			completed_islands = player_data.get("completed_islands", [])
			all_islands_completed = completed_islands.size() >= 5
	
	header.text = "PULAU PAPUA - LEVEL 2\nSUDAH SELESAI! 🎉"
	
	# Nonaktifkan gameplay
	for child in game_container.get_children():
		child.queue_free()
	
	# Show result dengan teks yang lebih ringkas
	result_container.visible = true
	var result_text = "Level ini sudah selesai! 🎉\n\n"
	result_text += "📊 PROGRESS SAAT INI:\n"
	result_text += "⭐ Total Bintang: " + str(stars) + "\n"
	result_text += "📚 Total Poin: " + str(knowledge_points) + "\n\n"
	
	if all_islands_completed:
		result_text += "🏆 SELAMAT! Semua pulau telah diselesaikan!\n"
		result_text += "Kamu adalah penjelajah budaya sejati Indonesia!"
	else:
		result_text += "🔓 Semua pulau telah terbuka!\n"
		result_text += "Kunjungi pulau mana saja untuk petualangan!"
	
	result_text += "\n\nTekan tombol untuk kembali ke peta"
	
	result_label.text = result_text
	result_label.modulate = Color(1, 0.85, 0.3)
	
	next_island_btn.text = "Kembali ke Peta"
	next_island_btn.show()
	
	restart_btn.text = "Main Lagi Level 2"
	restart_btn.show()
	
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
	print("🌴 Pulau Papua Level 2 exiting...")
	print("📊 Final State:")
	print("   Level completed:", level_completed)
	print("   Matched pairs:", matched_pairs, "/", total_pairs)
	print("   Moves:", moves_count)
	print("   Time:", game_time, "s")
	print("   Progress saved:", progress_saved)
