extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var platforms = []
var platform_speeds = []
var score_label: Label
var game_over_label: Label
var score = 0
var is_game_over = false

var current_platform_index = 0
var last_x_direction = 1

const SPEED = 6.5
const JUMP_FORCE = 8.5
var gravity = 22.0

# الألوان الدقيقة للخطوط الخارجية (بنفسجي هادئ، سماوي، أصفر خافت)
var exact_colors = [
	Color(0.9, 0.2, 0.8),
	Color(0.0, 0.8, 1.0),
	Color(1.0, 0.85, 0.2)
]

func _ready():
	setup_glow_environment()
	setup_lighting()
	create_camera()
	create_background_glow_effect()
	create_glowing_floor()
	create_player()
	create_ui()
	
	reset_game()

func setup_glow_environment():
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.001, 0.001, 0.003)
	
	env.glow_enabled = true
	env.glow_intensity = 1.6
	env.glow_strength = 1.0
	env.glow_bloom = 0.5
	
	world_env.environment = env
	add_child(world_env)

func create_background_glow_effect():
	var bg_light_1 = OmniLight3D.new()
	bg_light_1.position = Vector3(-4, 5, -5)
	bg_light_1.light_color = Color(0.0, 0.3, 0.9)
	bg_light_1.light_energy = 5.0
	bg_light_1.omni_range = 15.0
	add_child(bg_light_1)
	
	var bg_light_2 = OmniLight3D.new()
	bg_light_2.position = Vector3(4, 12, -5)
	bg_light_2.light_color = Color(0.8, 0.1, 0.6)
	bg_light_2.light_energy = 5.0
	bg_light_2.omni_range = 15.0
	add_child(bg_light_2)

func create_glowing_floor():
	var floor_body = StaticBody3D.new()
	floor_body.position = Vector3(0, -3.0, 0)
	
	var floor_lines = create_neon_box_node(Vector3(14.0, 0.15, 2.0), Color(1.0, 1.0, 1.0))
	floor_body.add_child(floor_lines)
	
	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(14.0, 0.3, 2.0)
	col.shape = col_shape
	floor_body.add_child(col)
	
	add_child(floor_body)

func reset_game():
	for p in platforms:
		p.queue_free()
	platforms.clear()
	platform_speeds.clear()
	
	score = 0
	current_platform_index = 0
	last_x_direction = 1
	score_label.text = "SCORE: 0"
	game_over_label.visible = false
	is_game_over = false
	
	if player:
		player.position = Vector3(0, -2.5, 0)
		player.velocity = Vector3(0, JUMP_FORCE * 1.9, 0)
		
	if camera:
		camera.position = Vector3(0, 3, 10)
	
	for i in range(12):
		spawn_initial_platform(i)

func setup_lighting():
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 15, 10)
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.light_energy = 1.2
	add_child(light)

func create_neon_box_node(size: Vector3, neon_color: Color) -> Node3D:
	var container = Node3D.new()
	
	var core_mesh = MeshInstance3D.new()
	var core_box = BoxMesh.new()
	core_box.size = size - Vector3(0.04, 0.04, 0.04)
	core_mesh.mesh = core_box
	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.03)
	core_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	core_mat.roughness = 0.2
	core_mesh.material_override = core_mat
	container.add_child(core_mesh)
	
	var edge_mat = StandardMaterial3D.new()
	edge_mat.albedo_color = neon_color
	edge_mat.roughness = 0.1
	edge_mat.emission_enabled = true
	edge_mat.emission = neon_color
	edge_mat.emission_energy_multiplier = 2.0
	
	var t = 0.035
	var w = size.x
	var h = size.y
	var d = size.z
	
	for i in range(4):
		var bar = MeshInstance3D.new()
		var box = BoxMesh.new()
		if i == 0: box.size = Vector3(w, t, t); bar.position = Vector3(0, h/2, d/2)
		elif i == 1: box.size = Vector3(w, t, t); bar.position = Vector3(0, h/2, -d/2)
		elif i == 2: box.size = Vector3(t, t, d); bar.position = Vector3(-w/2, h/2, 0)
		elif i == 3: box.size = Vector3(t, t, d); bar.position = Vector3(w/2, h/2, 0)
		bar.mesh = box; bar.material_override = edge_mat; container.add_child(bar)
		
	for i in range(4):
		var bar = MeshInstance3D.new()
		var box = BoxMesh.new()
		if i == 0: box.size = Vector3(w, t, t); bar.position = Vector3(0, -h/2, d/2)
		elif i == 1: box.size = Vector3(w, t, t); bar.position = Vector3(0, -h/2, -d/2)
		elif i == 2: box.size = Vector3(t, t, d); bar.position = Vector3(-w/2, -h/2, 0)
		elif i == 3: box.size = Vector3(t, t, d); bar.position = Vector3(w/2, -h/2, 0)
		bar.mesh = box; bar.material_override = edge_mat; container.add_child(bar)
		
	for i in range(4):
		var bar = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(t, h, t)
		var px = -w/2 if (i < 2) else w/2
		var pz = -d/2 if (i % 2 == 0) else d/2
		bar.position = Vector3(px, 0, pz)
		bar.mesh = box; bar.material_override = edge_mat; container.add_child(bar)
		
	return container

func create_player():
	player = CharacterBody3D.new()
	player.position = Vector3(0, -2.5, 0)
	
	var col = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3
	col.shape = sphere_shape
	player.add_child(col)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.9, 1.0)
	mat.roughness = 0.1
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.9, 1.0)
	mat.emission_energy_multiplier = 2.5

	var ring1 = MeshInstance3D.new()
	var torus1 = TorusMesh.new()
	torus1.inner_radius = 0.27
	torus1.outer_radius = 0.3
	ring1.mesh = torus1
	ring1.material_override = mat
	player.add_child(ring1)

	var ring2 = MeshInstance3D.new()
	var torus2 = TorusMesh.new()
	torus2.inner_radius = 0.27
	torus2.outer_radius = 0.3
	ring2.mesh = torus2
	ring2.rotation_degrees = Vector3(90, 0, 0)
	ring2.material_override = mat
	player.add_child(ring2)
	
	add_child(player)

func create_camera():
	camera = Camera3D.new()
	camera.position = Vector3(0, 3, 10)
	camera.rotation_degrees = Vector3(-10, 0, 0)
	add_child(camera)

func create_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.position = Vector2(40, 40)
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	canvas.add_child(score_label)
	
	game_over_label = Label.new()
	game_over_label.text = "GAME OVER\nPress 'Space' or 'Up' to Restart"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.position = Vector2(260, 250)
	game_over_label.add_theme_font_size_override("font_size", 36)
	game_over_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.3))
	game_over_label.visible = false
	canvas.add_child(game_over_label)

func spawn_initial_platform(i: int):
	var x_pos = 0.0
	var y_pos = i * 2.0 + 0.5
	if i > 0:
		last_x_direction *= -1
		var is_far = (i % 2 == 0)
		var x_dist = randf_range(2.2, 3.2) if is_far else randf_range(1.0, 1.8)
		x_pos = last_x_direction * x_dist
	
	var pos = Vector3(x_pos, y_pos, 0)
	spawn_platform_at(pos)

func spawn_next_platform():
	var top_platform = platforms[platforms.size() - 1]
	
	last_x_direction *= -1
	var is_far = randf() > 0.4
	var x_dist = randf_range(2.2, 3.3) if is_far else randf_range(1.0, 1.8)
	var y_dist = randf_range(1.9, 2.4)
	
	var new_x = last_x_direction * x_dist
	var new_y = top_platform.position.y + y_dist
	
	spawn_platform_at(Vector3(new_x, new_y, 0))

func spawn_platform_at(pos: Vector3):
	var body = StaticBody3D.new()
	body.position = pos
	
	var selected_color = exact_colors[randi() % exact_colors.size()]
	var neon_box = create_neon_box_node(Vector3(2.0, 0.3, 1.2), selected_color)
	body.add_child(neon_box)
	
	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(2.0, 0.3, 1.2)
	col.shape = col_shape
	body.add_child(col)
	
	add_child(body)
	platforms.append(body)
	platform_speeds.append(randf_range(1.0, 1.6))

func _physics_process(delta):
	if not player:
		return

	if is_game_over:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"):
			reset_game()
		return

	if score >= 80:
		var speed_multiplier = 1.0
		if score >= 300:
			speed_multiplier = 2.4
		elif score >= 250:
			speed_multiplier = 1.9
		elif score >= 200:
			speed_multiplier = 1.5
		elif score >= 150:
			speed_multiplier = 1.25

		for i in range(platforms.size()):
			var p = platforms[i]
			var base_speed = platform_speeds[i]
			p.position.x += sin(Time.get_ticks_msec() * 0.0025 * base_speed * speed_multiplier) * delta * 2.0

	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up"):
			player.velocity.y = JUMP_FORCE * 1.45
		else:
			player.velocity.y = JUMP_FORCE

		for i in range(platforms.size()):
			var p = platforms[i]
			if abs(player.global_position.x - p.position.x) < 1.1 and abs(player.global_position.y - (p.position.y + 0.3)) < 0.4:
				if i > current_platform_index:
					var diff = i - current_platform_index
					score += diff * 5
					current_platform_index = i
					score_label.text = "SCORE: " + str(score)
				break

	var input_dir = Input.get_axis("ui_left", "ui_right")
	player.velocity.x = input_dir * SPEED

	player.move_and_slide()

	if player.global_position.y > camera.position.y - 1:
		camera.position.y = player.global_position.y + 1

	if platforms.size() > 0:
		var top_platform_y = platforms[platforms.size() - 1].position.y
		if player.global_position.y > top_platform_y - 16:
			spawn_next_platform()
			
			if platforms.size() > 30:
				var old_platform = platforms.pop_front()
				old_platform.queue_free()
				platform_speeds.pop_front()
				current_platform_index = max(0, current_platform_index - 1)

	if player.global_position.y < camera.position.y - 6.5:
		is_game_over = true
		game_over_label.visible = true
		player.velocity = Vector3.ZERO
