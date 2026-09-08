extends Node3D
# Onam Ascent - Milestone 1: single-scene Level 1 loop.
# World forward is -Z. The player auto-runs toward -Z up the staircase;
# coconuts roll toward +Z (down, toward the camera side) and are freed once
# they pass behind the player. Lanes vary on X, jump on Y.

const LANE_X := [-2.2, 0.0, 2.2]
const START_Z := 6.0
const RUN_SPEED_BASE := 9.0
const RUN_SPEED_MAX := 15.0
const SPEED_RAMP := 0.012
const SWITCH_SPEED := 16.0
const GRAVITY := 22.0
const JUMP_SPEED := 9.4
const MAX_HEARTS := 3
const HEART_FULL := Color(0.95, 0.16, 0.16, 1.0)
const HEART_LOST := Color(0.32, 0.32, 0.34, 0.7)

const COCONUT_SPEED := 6.0
const COCONUT_SPAWN_OFFSET := -90.0
const COCONUT_DESPAWN_MARGIN := 16.0
const COCONUT_TOP_Y := 1.22
const COCONUT_X_HALF := 0.83
const COCONUT_Z_HALF := 0.9

const CLOSE_MARGIN := 1.5
const CLOSE_BONUS := 25
const CLOSE_COOLDOWN := 0.7
const MILESTONE_STEP := 100

const SWIPE_THRESHOLD := 35.0
const RESTART_DELAY := 0.5

const TRAIL_AMOUNT_MIN := 24
const TRAIL_AMOUNT_MAX := 60

const PICKUP_SPAWN_OFFSET := -80.0
const PICKUP_CHARGE := 0.25

const CHUNK_LEN := 25.0
const CHUNK_SLABS := 8
const CHUNK_COUNT := 10
const GROUND_FAR_START := -210.0

const GOLD_A := Color(0.93, 0.74, 0.30, 1.0)
const GOLD_B := Color(0.72, 0.53, 0.22, 1.0)
const GOLD_BODY := Color(0.5, 0.37, 0.16, 1.0)
const GOLD_STRIP := Color(1.0, 0.9, 0.55, 1.0)

@onready var player: CharacterBody3D = $Player
@onready var player_mesh: Node3D = $Player/Mesh
@onready var maveli_character: Node3D = $Player/Mesh/Maveli
@onready var camera_rig: Node3D = $CameraRig
@onready var ground_root: Node3D = $Ground
@onready var obstacle_root: Node3D = $Obstacles
@onready var pickup_root: Node3D = $Pickups
@onready var heart0: Label = $HUD/UI/Heart0
@onready var heart1: Label = $HUD/UI/Heart1
@onready var heart2: Label = $HUD/UI/Heart2
@onready var power_bar: ProgressBar = $HUD/UI/UmbrellaBar
@onready var distance_label: Label = $HUD/UI/DistanceLabel
@onready var game_over_panel: Control = $HUD/UI/GameOver
@onready var final_score_label: Label = $HUD/UI/GameOver/FinalScoreLabel
@onready var hit_flash: ColorRect = $HUD/UI/HitFlash
@onready var popup_root: Control = $HUD/UI/Popups
@onready var best_score_label: Label = $HUD/UI/GameOver/BestScoreLabel
@onready var camera3d: Camera3D = $CameraRig/CameraYaw/CameraPitch/Camera3D
@onready var trail: CPUParticles3D = $Player/Trail
@onready var chime_player: AudioStreamPlayer = $ChimePlayer

var heart_labels: Array = []
var hearts := MAX_HEARTS
var umbrella := 0.0
var distance_m := 0.0
var lane := 1
var grounded := true
var vy := 0.0
var invuln_timer := 0.0
var flash_alpha := 0.0
var shake_timer := 0.0
var game_over := false
var run_time := 0.0
var spawn_timer := 1.4
var pickup_timer := 5.0
var coconut_index := 0
var run_speed := RUN_SPEED_BASE
var best_distance := 0
var last_milestone := 0
var close_call_cooldown := 0.0
var death_time_ms := -1_000_000
var touch_id := -1
var touch_start := Vector2.ZERO
var touch_dragging := false
var swipe_consumed := false
var chime_stream: AudioStreamWAV

var coconut_nodes: Array = []
var pickup_nodes: Array = []
var chunk_infos: Array = []

var mat_tread_a: StandardMaterial3D
var mat_tread_b: StandardMaterial3D
var mat_body: StandardMaterial3D
var mat_strip: StandardMaterial3D
var mat_coconut: StandardMaterial3D
var mat_pickup: StandardMaterial3D
var mesh_tread: BoxMesh
var mesh_body: BoxMesh
var mesh_strip: BoxMesh
var mesh_coconut: CylinderMesh
var mesh_pickup: SphereMesh
var mat_ghost: StandardMaterial3D


func _ready() -> void:
	_make_assets()
	heart_labels = [heart0, heart1, heart2]
	chime_stream = _make_chime_stream()
	chime_player.stream = chime_stream
	_build_ground()
	_reset_run()
	camera_rig.position = Vector3(LANE_X[1], 1.2, START_Z)


func _make_assets() -> void:
	mat_tread_a = _solid_material(GOLD_A)
	mat_tread_b = _solid_material(GOLD_B)
	mat_body = _solid_material(GOLD_BODY)
	mat_strip = _solid_material(GOLD_STRIP)
	mat_coconut = _solid_material(Color(0.45, 0.24, 0.09, 1.0))
	mat_pickup = StandardMaterial3D.new()
	mat_pickup.albedo_color = Color(1.0, 0.88, 0.35, 1.0)
	mat_pickup.emission_enabled = true
	mat_pickup.emission = Color(1.0, 0.82, 0.25, 1.0)
	mat_pickup.emission_energy_multiplier = 2.2
	mat_pickup.roughness = 0.4

	mat_ghost = StandardMaterial3D.new()
	mat_ghost.albedo_color = Color(1.0, 0.95, 0.85, 0.35)
	mat_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mesh_tread = BoxMesh.new()
	mesh_tread.size = Vector3(11.0, 0.22, 3.08)
	mesh_body = BoxMesh.new()
	mesh_body.size = Vector3(11.0, 2.0, CHUNK_LEN)
	mesh_strip = BoxMesh.new()
	mesh_strip.size = Vector3(1.9, 0.03, CHUNK_LEN - 0.1)
	mesh_coconut = CylinderMesh.new()
	mesh_coconut.top_radius = 0.6
	mesh_coconut.bottom_radius = 0.6
	mesh_coconut.height = 1.15
	mesh_pickup = SphereMesh.new()
	mesh_pickup.radius = 0.4
	mesh_pickup.height = 0.8


func _solid_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m


func _build_ground() -> void:
	for i in CHUNK_COUNT:
		var far_z := GROUND_FAR_START + i * CHUNK_LEN
		var chunk := _make_chunk(far_z)
		ground_root.add_child(chunk)
		chunk_infos.append({"node": chunk, "far": far_z})


func _make_chunk(far_z: float) -> Node3D:
	var ch := Node3D.new()
	ch.name = "GroundChunk"
	ch.position = Vector3(0.0, 0.0, far_z + CHUNK_LEN * 0.5)

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = mesh_body
	body.material_override = mat_body
	body.position = Vector3(0.0, -1.2, 0.0)
	ch.add_child(body)

	var slab_w := CHUNK_LEN / CHUNK_SLABS
	for j in CHUNK_SLABS:
		var slab := MeshInstance3D.new()
		slab.name = "Tread%d" % j
		slab.mesh = mesh_tread
		slab.material_override = mat_tread_a if j % 2 == 0 else mat_tread_b
		slab.position = Vector3(0.0, -0.11, -CHUNK_LEN * 0.5 + (j + 0.5) * slab_w)
		ch.add_child(slab)

	for li in LANE_X.size():
		var strip := MeshInstance3D.new()
		strip.name = "LaneStrip%d" % li
		strip.mesh = mesh_strip
		strip.material_override = mat_strip
		strip.position = Vector3(LANE_X[li], 0.015, 0.0)
		ch.add_child(strip)

	return ch


func _recycle_ground() -> void:
	var min_far := INF
	for info in chunk_infos:
		min_far = minf(min_far, info.far)
	var done := false
	while not done:
		done = true
		for info in chunk_infos:
			if info.far > player.position.z + 10.0:
				info.far = min_far - CHUNK_LEN
				info.node.position.z = info.far + CHUNK_LEN * 0.5
				min_far = info.far
				done = false
				break


func _physics_process(delta: float) -> void:
	if game_over:
		close_call_cooldown = maxf(0.0, close_call_cooldown - delta)
		if Input.is_action_just_pressed("restart") and _can_restart():
			_reset_run()
		return

	if Input.is_action_just_pressed("restart"):
		_reset_run()
		return

	run_time += delta

	var dir := 0
	if Input.is_action_just_pressed("move_left"):
		dir -= 1
	if Input.is_action_just_pressed("move_right"):
		dir += 1
	if dir != 0:
		_switch_lane(dir)

	var x_now = player.position.x
	var x_target = LANE_X[lane]
	var x_step := SWITCH_SPEED * delta
	if absf(x_target - x_now) <= x_step:
		x_now = x_target
	else:
		x_now += signf(x_target - x_now) * x_step

	if Input.is_action_just_pressed("jump"):
		_try_jump()
	if not grounded:
		vy -= GRAVITY * delta

	var vx: float = (x_now - player.position.x) / delta
	player.velocity = Vector3(vx, vy, -run_speed)
	player.move_and_slide()

	if player.position.y <= 0.0:
		player.position.y = 0.0
		vy = 0.0
		grounded = true

	if maveli_character != null and maveli_character.has_method("update_animation"):
		maveli_character.update_animation(delta, grounded, run_speed, vy, vx)

	distance_m = maxf(0.0, START_Z - player.position.z)
	run_speed = minf(RUN_SPEED_MAX, RUN_SPEED_BASE + distance_m * SPEED_RAMP)
	_update_spawning(delta)
	_update_obstacles(delta)
	_update_pickups(delta)
	_check_coconut_hits()
	_update_camera(delta)
	_update_feedback(delta)
	_recycle_ground()
	distance_label.text = "Distance %d m" % int(distance_m)
	var mile := int(distance_m) / MILESTONE_STEP * MILESTONE_STEP
	if mile > last_milestone and mile > 0:
		last_milestone = mile
		_spawn_popup(player.position + Vector3(0.0, 2.6, 0.0), "%d m!" % mile, Color(1.0, 0.85, 0.4, 1.0))


func _update_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var hard := clampf(distance_m / 180.0, 0.0, 1.0)
		var pace := hard * 0.5 + clampf((run_speed - RUN_SPEED_BASE) / (RUN_SPEED_MAX - RUN_SPEED_BASE), 0.0, 1.0) * 0.5
		spawn_timer = maxf(0.5, randf_range(1.35 - pace * 0.7, 2.05 - pace * 0.95))
		_spawn_wave(hard)
	pickup_timer -= delta
	if pickup_timer <= 0.0:
		pickup_timer = randf_range(6.0, 11.0)
		_spawn_pickup()


func _spawn_wave(hard: float) -> void:
	var r := randf()
	if r < 0.42 - hard * 0.18:
		_pattern_single(hard)
	elif r < 0.74:
		_pattern_block()
	else:
		_pattern_wall()


func _pattern_single(hard: float) -> void:
	if hard > 0.25 and randf() < 0.4:
		# Staggered zigzag: two coconuts in adjacent lanes, offset in depth.
		var l0 := randi_range(0, 1)
		_spawn_coconut(l0, 0.0)
		_spawn_coconut(l0 + 1, -6.0)
	else:
		_spawn_coconut(randi_range(0, 2), randf_range(-0.4, 0.4))


func _pattern_block() -> void:
	# Two lanes blocked, one guaranteed open lane.
	var free_lane := randi_range(0, 2)
	for lane_i in range(3):
		if lane_i != free_lane:
			_spawn_coconut(lane_i, randf_range(-0.8, 0.8))


func _pattern_wall() -> void:
	# Full-width wall: every lane blocked at the same depth, must jump it.
	for lane_i in range(3):
		var c := _spawn_coconut(lane_i, randf_range(-0.5, 0.5))
		c.set_meta("wall", true)


func _spawn_coconut(lane_i: int, z_jitter: float) -> Node3D:
	var c := Node3D.new()
	c.name = "Coconut%d" % coconut_index
	coconut_index += 1
	c.position = Vector3(LANE_X[lane_i], 0.0, player.position.z + COCONUT_SPAWN_OFFSET + z_jitter)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh_coconut
	mi.material_override = mat_coconut
	mi.position = Vector3(0.0, 0.62, 0.0)
	mi.rotation.z = PI * 0.5
	c.add_child(mi)
	obstacle_root.add_child(c)
	coconut_nodes.append(c)
	return c


func _spawn_pickup() -> void:
	var spawn_z = player.position.z + PICKUP_SPAWN_OFFSET
	for attempt in 3:
		var lane_i := randi_range(0, 2)
		var lane_x = LANE_X[lane_i]
		var blocked := false
		for c in coconut_nodes:
			if absf(c.position.x - lane_x) < 0.7 and absf(c.position.z - spawn_z) < 9.0:
				blocked = true
				break
		if not blocked:
			var p := Node3D.new()
			p.name = "UmbrellaPickup"
			p.position = Vector3(lane_x, 0.62, spawn_z)
			var mi := MeshInstance3D.new()
			mi.name = "Mesh"
			mi.mesh = mesh_pickup
			mi.material_override = mat_pickup
			p.add_child(mi)
			p.set_meta("phase", randf() * TAU)
			pickup_root.add_child(p)
			pickup_nodes.append(p)
			return


func _update_obstacles(delta: float) -> void:
	var despawn_z = player.position.z + COCONUT_DESPAWN_MARGIN
	var c_speed := COCONUT_SPEED + (run_speed - RUN_SPEED_BASE) * 0.4
	for i in range(coconut_nodes.size() - 1, -1, -1):
		var c = coconut_nodes[i]
		c.position.z += c_speed * delta
		if not c.get_meta("passed", false) and c.position.z > player.position.z + COCONUT_Z_HALF:
			c.set_meta("passed", true)
			_maybe_close_call(c)
		if c.position.z > despawn_z:
			coconut_nodes.remove_at(i)
			c.queue_free()


func _maybe_close_call(c: Node3D) -> void:
	if game_over or close_call_cooldown > 0.0 or invuln_timer > 0.0:
		return
	if absf(c.position.x - player.position.x) >= CLOSE_MARGIN:
		return
	close_call_cooldown = CLOSE_COOLDOWN
	_spawn_popup(c.position + Vector3(0.0, 1.3, 0.0), "+%d CLOSE" % CLOSE_BONUS, Color(0.5, 0.95, 1.0, 1.0))
	chime_player.play()


func _update_pickups(delta: float) -> void:
	for i in range(pickup_nodes.size() - 1, -1, -1):
		var p = pickup_nodes[i]
		var phase: float = p.get_meta("phase")
		p.position.y = 0.62 + sin(run_time * 3.0 + phase) * 0.12
		if p.position.z > player.position.z + 2.0:
			pickup_nodes.remove_at(i)
			p.queue_free()
			continue
		if absf(p.position.x - player.position.x) < 0.95 and absf(p.position.z - player.position.z) < 1.0:
			umbrella = minf(1.0, umbrella + PICKUP_CHARGE)
			power_bar.value = umbrella * 100.0
			_spawn_popup(p.position + Vector3(0.0, 1.0, 0.0), "+25% UMBRELLA", Color(1.0, 0.88, 0.35, 1.0))
			pickup_nodes.remove_at(i)
			p.queue_free()


func _check_coconut_hits() -> void:
	if invuln_timer > 0.0:
		return
	var px = player.position.x
	var pz = player.position.z
	var py = player.position.y
	for c in coconut_nodes:
		var hit_x_half := COCONUT_X_HALF
		if c.get_meta("wall", false):
			hit_x_half = 1.4
		if py < COCONUT_TOP_Y and absf(c.position.x - px) < hit_x_half and absf(c.position.z - pz) < COCONUT_Z_HALF:
			_take_hit()
			break


func _take_hit() -> void:
	if invuln_timer > 0.0 or game_over:
		return
	hearts -= 1
	_update_hearts()
	invuln_timer = 1.5
	flash_alpha = 0.6
	shake_timer = 0.3
	if hearts <= 0:
		hearts = 0
		_update_hearts()
		_game_over()


func _game_over() -> void:
	game_over = true
	death_time_ms = Time.get_ticks_msec()
	var fin := int(distance_m)
	best_distance = maxi(best_distance, fin)
	trail.emitting = false
	game_over_panel.visible = true
	final_score_label.text = "Distance climbed: %d m" % fin
	best_score_label.text = "Best: %d m" % best_distance


func _update_camera(delta: float) -> void:
	var tx: float = player.position.x
	var ty: float = player.position.y + 1.2
	var p := camera_rig.position
	var nx := lerpf(p.x, tx, minf(1.0, 14.0 * delta))
	var ny := lerpf(p.y, ty, minf(1.0, 7.0 * delta))
	var nz: float = player.position.z
	if shake_timer > 0.0:
		var amp := 0.12 * (shake_timer / 0.3)
		nx += randf_range(-amp, amp)
		ny += randf_range(-amp, amp)
		nz += randf_range(-amp, amp)
	camera_rig.position = Vector3(nx, ny, nz)


func _update_feedback(delta: float) -> void:
	close_call_cooldown = maxf(0.0, close_call_cooldown - delta)
	if invuln_timer > 0.0:
		invuln_timer = maxf(0.0, invuln_timer - delta)
	player_mesh.visible = invuln_timer <= 0.0 or (int(invuln_timer * 12.0) % 2 == 0)
	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * 2.0)
		hit_flash.color.a = flash_alpha

	var speed_t := clampf((run_speed - RUN_SPEED_BASE) / (RUN_SPEED_MAX - RUN_SPEED_BASE), 0.0, 1.0)
	var want_amt := int(round(lerpf(TRAIL_AMOUNT_MIN, TRAIL_AMOUNT_MAX, speed_t) / 4.0)) * 4
	if want_amt != trail.amount:
		trail.amount = want_amt
	trail.scale_amount_min = lerpf(0.12, 0.2, speed_t)
	trail.scale_amount_max = lerpf(0.3, 0.55, speed_t)
	trail.initial_velocity_min = lerpf(0.4, 1.0, speed_t)
	trail.initial_velocity_max = lerpf(1.2, 2.4, speed_t)
	trail.lifetime = lerpf(0.5, 0.8, speed_t)


func _reset_run() -> void:
	hearts = MAX_HEARTS
	umbrella = 0.0
	distance_m = 0.0
	lane = 1
	grounded = true
	vy = 0.0
	invuln_timer = 0.0
	flash_alpha = 0.0
	shake_timer = 0.0
	game_over = false
	run_time = 0.0
	spawn_timer = 1.4
	pickup_timer = 5.0
	run_speed = RUN_SPEED_BASE
	last_milestone = 0
	close_call_cooldown = 0.0
	death_time_ms = -1_000_000
	touch_dragging = false
	swipe_consumed = false
	touch_id = -1
	trail.emitting = true
	for n in popup_root.get_children():
		n.queue_free()
	player.position = Vector3(LANE_X[lane], 0.0, START_Z)
	player.velocity = Vector3.ZERO
	player_mesh.visible = true
	hit_flash.color.a = 0.0
	for n in coconut_nodes:
		n.queue_free()
	coconut_nodes.clear()
	for n in pickup_nodes:
		n.queue_free()
	pickup_nodes.clear()
	game_over_panel.visible = false
	_update_hearts()
	power_bar.value = 0.0
	distance_label.text = "Distance 0 m"


func _update_hearts() -> void:
	for i in MAX_HEARTS:
		var col := HEART_FULL if i < hearts else HEART_LOST
		heart_labels[i].add_theme_color_override("font_color", col)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			touch_id = t.index
			touch_start = t.position
			touch_dragging = true
			swipe_consumed = false
		elif t.index == touch_id:
			if touch_dragging and not swipe_consumed:
				_handle_tap(t.position)
			touch_dragging = false
			touch_id = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != touch_id or not touch_dragging or swipe_consumed:
			return
		var vec := d.position - touch_start
		if vec.length() >= SWIPE_THRESHOLD:
			swipe_consumed = true
			if absf(vec.x) >= absf(vec.y):
				_switch_lane(1 if vec.x > 0.0 else -1)
			elif vec.y < 0.0:
				_try_jump()


func _handle_tap(_pos: Vector2) -> void:
	if game_over:
		if _can_restart():
			_reset_run()
	else:
		_try_jump()


func _try_jump() -> void:
	if grounded:
		vy = JUMP_SPEED
		grounded = false


func _switch_lane(dir: int) -> void:
	var new_lane := clampi(lane + dir, 0, LANE_X.size() - 1)
	if new_lane != lane:
		lane = new_lane
		_spawn_ghost()


func _spawn_ghost() -> void:
	var ghost := MeshInstance3D.new()
	ghost.name = "Ghost"
	var src_mesh: Mesh = _find_first_player_mesh()
	ghost.mesh = src_mesh if src_mesh != null else mesh_pickup
	var gm := mat_ghost.duplicate() as StandardMaterial3D
	ghost.material_override = gm
	ghost.position = player.position + Vector3(0.0, 0.88, 0.0)
	ghost.rotation = player_mesh.rotation
	obstacle_root.add_child(ghost)
	var tw := create_tween()
	tw.tween_property(gm, "albedo_color:a", 0.0, 0.28).set_ease(Tween.EASE_IN)
	tw.tween_callback(ghost.queue_free)


func _find_first_player_mesh() -> Mesh:
	return _find_mesh_recursive(player_mesh)


func _find_mesh_recursive(node: Node) -> Mesh:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var m := _find_mesh_recursive(child)
		if m != null:
			return m
	return null


func _can_restart() -> bool:
	return Time.get_ticks_msec() - death_time_ms >= int(RESTART_DELAY * 1000.0)


func _spawn_popup(world_pos: Vector3, text: String, color: Color) -> void:
	var sp: Vector2 = camera3d.unproject_position(world_pos)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 10
	popup_root.add_child(lbl)
	lbl.reset_size()
	lbl.position = sp - Vector2(lbl.size.x * 0.5, lbl.size.y * 0.5)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 64.0, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.1).set_delay(0.15)
	tw.tween_callback(lbl.queue_free)


func _make_chime_stream() -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * 0.26)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var env := exp(-t * 10.0)
		var freq := 920.0 + 260.0 * exp(-t * 18.0)
		var s := (sin(TAU * freq * t) + 0.45 * sin(TAU * freq * 2.0 * t) + 0.2 * sin(TAU * freq * 3.0 * t)) * env
		var v := int(clampf(s, -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.stereo = false
	wav.data = bytes
	return wav
