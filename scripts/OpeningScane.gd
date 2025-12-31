extends Control

func _ready():
	print("🎬 OpeningScene _ready() STARTED")
	
	# Setup visual dan interactions saja
	setup_visual()
	setup_interactions()
	
	print("🎉 OpeningScene READY!")

func setup_visual():
	print("🎨 Setting up visual...")
	
	# Pastikan background visible
	if has_node("Background"):
		var bg = $Background
		if bg is TextureRect and not bg.texture:
			print("⚠️ Background texture missing - using color")
			bg.texture = null
			bg.color = Color("#1a2a6c")
	
	# POSITIONING FIX - hanya untuk node yang di pojok (0,0)
	reposition_nodes()
	
	# Fade in effect
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.5)
	tween.tween_callback(_on_fade_in_complete)

func reposition_nodes():
	print("📍 Checking node positions...")
	var screen_size = get_viewport().get_visible_rect().size
	print("📏 Screen size:", screen_size)
	
	# HANYA reposition jika node di pojok kiri atas (0,0)
	if has_node("Title"):
		var title = $Title
		if title.position.x == 0 and title.position.y == 0:
			title.position = Vector2(screen_size.x / 2 - 250, 150)
			title.size = Vector2(500, 80)
			print("📍 Title repositioned from (0,0) to:", title.position)
		else:
			print("📍 Title position already set:", title.position)
	
	if has_node("StartButton"):
		var button = $StartButton
		if button.position.x == 0 and button.position.y == 0:
			button.position = Vector2(screen_size.x / 2 - 100, 400)
			button.size = Vector2(200, 80)
			print("📍 Button repositioned from (0,0) to:", button.position)
		else:
			print("📍 Button position already set:", button.position)

func _on_fade_in_complete():
	print("✨ Fade in complete - scene fully visible")

func setup_interactions():
	print("🎮 Setting up interactions...")
	
	# Connect button signal
	if has_node("StartButton"):
		$StartButton.connect("pressed", _on_start_button_pressed)
		print("✅ Button connected")
	else:
		print("❌ StartButton node missing")

func _on_start_button_pressed():
	print("🚀 MULAI button clicked!")
	
	# Button press effect
	if has_node("StartButton"):
		var button = $StartButton
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_callback(_go_to_map)
	else:
		_go_to_map()

func _go_to_map():
	print("🗺️ Transitioning to MapScene...")
	get_node("/root/Main").show_map()

# Handle keyboard input
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			print("⌨️ Keyboard shortcut - starting game")
			_on_start_button_pressed()
