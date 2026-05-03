extends CharacterBody2D

class_name WaterPlayer

const STATE_TEXTURES := {
	"calm": preload("res://assets/sprites/water_player_spirit/overlay_calm.png"),
	"cold": preload("res://assets/sprites/water_player_spirit/overlay_cold.png"),
	"tense": preload("res://assets/sprites/water_player_spirit/overlay_tense.png"),
}
const LAYER_CORE_TEXTURES := {
	"idle": preload("res://assets/sprites/water_player_layers/core_idle.png"),
	"move": preload("res://assets/sprites/water_player_layers/core_start.png"),
	"pause": preload("res://assets/sprites/water_player_layers/core_nestle.png"),
	"approach": preload("res://assets/sprites/water_player_layers/core_start.png"),
	"nestle": preload("res://assets/sprites/water_player_layers/core_nestle.png"),
	"leave": preload("res://assets/sprites/water_player_layers/core_leave.png"),
}
const LAYER_HIGHLIGHT_TEXTURES := {
	"idle": preload("res://assets/sprites/water_player_layers/highlight_idle.png"),
	"move": preload("res://assets/sprites/water_player_layers/highlight_start.png"),
	"pause": preload("res://assets/sprites/water_player_layers/highlight_nestle.png"),
	"approach": preload("res://assets/sprites/water_player_layers/highlight_start.png"),
	"nestle": preload("res://assets/sprites/water_player_layers/highlight_nestle.png"),
	"leave": preload("res://assets/sprites/water_player_layers/highlight_leave.png"),
}
const TRAIL_TEXTURES := {
	"motion": preload("res://assets/sprites/water_player_layers/trail_motion.png"),
	"leave": preload("res://assets/sprites/water_player_layers/trail_leave.png"),
	"soft": preload("res://assets/sprites/water_player_layers/highlight_nestle.png"),
}
const POSE_TEXTURES := {
	"move": preload("res://assets/sprites/water_player_layers/pose_start.png"),
	"approach": preload("res://assets/sprites/water_player_layers/pose_start.png"),
	"pause": preload("res://assets/sprites/water_player_layers/pose_stop.png"),
	"nestle": preload("res://assets/sprites/water_player_layers/pose_nestle.png"),
	"leave": preload("res://assets/sprites/water_player_layers/pose_leave.png"),
}
const IDLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/water_player_spirit/idle_00.png"),
	preload("res://assets/sprites/water_player_spirit/idle_01.png"),
	preload("res://assets/sprites/water_player_spirit/idle_02.png"),
	preload("res://assets/sprites/water_player_spirit/idle_03.png"),
	preload("res://assets/sprites/water_player_spirit/idle_04.png"),
	preload("res://assets/sprites/water_player_spirit/idle_05.png"),
]
const MOVE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/water_player_spirit/move_00.png"),
	preload("res://assets/sprites/water_player_spirit/move_01.png"),
	preload("res://assets/sprites/water_player_spirit/move_02.png"),
	preload("res://assets/sprites/water_player_spirit/move_03.png"),
	preload("res://assets/sprites/water_player_spirit/move_04.png"),
	preload("res://assets/sprites/water_player_spirit/move_05.png"),
	preload("res://assets/sprites/water_player_spirit/move_06.png"),
	preload("res://assets/sprites/water_player_spirit/move_07.png"),
]
const IDLE_WATER_SOUND := preload("res://assets/audio/ch1/protagonist_idle_subtle_water.wav")
const MOVE_WATER_SOUND := preload("res://assets/audio/ch1/protagonist_light_movement_water.wav")

@export var move_speed := 125.0
@export var accel := 420.0
@export var damping := 520.0
@export var drift_gravity := 380.0
@export var gentle_lift := -45.0
@export_group("Water Feel")
@export var intent_response := 7.0
@export var body_stretch_strength := 0.13
@export var core_lag_strength := 9.0
@export var highlight_drift_strength := 6.0
@export var trail_strength := 0.12
@export var contact_glow_strength := 0.12
@export var stop_settle_time := 0.22

@onready var idle_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var soft_shadow: Polygon2D = $SoftShadow
@onready var wet_trace: Polygon2D = $WetTrace
@onready var motion_trail: Sprite2D = $MotionTrail
@onready var expression_pose: Sprite2D = $ExpressionPose
@onready var state_overlay: Sprite2D = $StateOverlay
@onready var inner_glow: Sprite2D = $InnerGlow
@onready var surface_highlight: Sprite2D = $SurfaceHighlight
@onready var contact_glow: Polygon2D = $ContactGlow
@onready var idle_audio: AudioStreamPlayer = $IdleWaterAudio
@onready var move_audio: AudioStreamPlayer = $MoveWaterAudio

var _control_enabled := false
var _base_scale := Vector2.ONE
var _trail_base_scale := Vector2.ONE
var _sprite_base_position := Vector2.ZERO
var _overlay_base_position := Vector2.ZERO
var _glow_base_position := Vector2.ZERO
var _highlight_base_position := Vector2.ZERO
var _highlight_base_scale := Vector2.ONE
var _trail_base_position := Vector2.ZERO
var _shadow_base_position := Vector2.ZERO
var _wet_trace_base_position := Vector2.ZERO
var _contact_base_position := Vector2.ZERO
var _expression_state_override := ""
var _visual_state := "idle"
var _state_age := 0.0
var _last_move_direction := 1.0
var _smoothed_input := 0.0
var _was_input_active := false
var _start_pulse := 0.0
var _stop_settle := 0.0
var _contact_intensity := 0.0
var _target_contact_intensity := 0.0
var _pose_alpha := 0.0
var _target_pose_alpha := 0.0


func _ready() -> void:
	_assign_runtime_frames()
	_setup_audio()
	inner_glow.texture = LAYER_CORE_TEXTURES["idle"]
	surface_highlight.texture = LAYER_HIGHLIGHT_TEXTURES["idle"]
	motion_trail.texture = TRAIL_TEXTURES["motion"]
	idle_sprite.play("idle")
	_base_scale = idle_sprite.scale
	_trail_base_scale = motion_trail.scale
	_sprite_base_position = idle_sprite.position
	_overlay_base_position = state_overlay.position
	_glow_base_position = inner_glow.position
	_highlight_base_position = surface_highlight.position
	_highlight_base_scale = surface_highlight.scale
	_trail_base_position = motion_trail.position
	_shadow_base_position = soft_shadow.position
	_wet_trace_base_position = wet_trace.position
	_contact_base_position = contact_glow.position
	expression_pose.modulate.a = 0.0
	set_state_visual("calm")


func _physics_process(delta: float) -> void:
	if not _control_enabled:
		velocity.x = move_toward(velocity.x, 0.0, damping * delta)
		velocity.y = move_toward(velocity.y, gentle_lift, 260.0 * delta)
		move_and_slide()
		_apply_breathing()
		_apply_feedback_layers(0.0, delta)
		_update_audio(0.0)
		return

	var raw_input_x := Input.get_axis("move_left", "move_right")
	_update_movement_phase(raw_input_x, delta)
	_smoothed_input = lerp(_smoothed_input, raw_input_x, 1.0 - exp(-delta * intent_response))
	var input_x := _smoothed_input
	if absf(raw_input_x) > 0.01:
		_last_move_direction = signf(raw_input_x)
		if idle_sprite.animation != &"move":
			idle_sprite.play("move")
		velocity.x = move_toward(velocity.x, input_x * move_speed, accel * delta)
		look_direction(signf(raw_input_x))
	else:
		if idle_sprite.animation != &"idle":
			idle_sprite.play("idle")
		velocity.x = move_toward(velocity.x, 0.0, damping * delta)

	if not is_on_floor():
		velocity.y += drift_gravity * delta
	else:
		velocity.y = move_toward(velocity.y, gentle_lift, 180.0 * delta)

	move_and_slide()
	_apply_breathing()
	_apply_motion_feel(input_x)
	_apply_expression_state(input_x, delta)
	_apply_feedback_layers(input_x, delta)
	_update_audio(input_x)


func set_control_enabled(value: bool) -> void:
	_control_enabled = value
	idle_sprite.play("idle")
	if value:
		set_state_visual("tense")
	else:
		set_state_visual("calm")


func look_east() -> void:
	look_direction(1.0)


func look_direction(direction: float) -> void:
	if direction == 0.0:
		return
	idle_sprite.flip_h = direction < 0.0
	motion_trail.flip_h = direction < 0.0
	expression_pose.flip_h = direction < 0.0
	state_overlay.flip_h = direction < 0.0
	inner_glow.flip_h = direction < 0.0
	surface_highlight.flip_h = direction < 0.0


func set_state_visual(state_name: String) -> void:
	match state_name:
		"cold":
			state_overlay.texture = STATE_TEXTURES["cold"]
			state_overlay.modulate = Color(0.88, 0.96, 0.98, 0.2)
		"tense":
			state_overlay.texture = STATE_TEXTURES["tense"]
			state_overlay.modulate = Color(0.86, 0.95, 0.94, 0.14)
		_:
			state_overlay.texture = STATE_TEXTURES["calm"]
			state_overlay.modulate = Color(0.82, 0.95, 0.94, 0.11)


func set_expression_state(state_name: String) -> void:
	if _expression_state_override == state_name:
		return
	_expression_state_override = state_name
	_state_age = 0.0


func clear_expression_state() -> void:
	if _expression_state_override == "":
		return
	_expression_state_override = ""
	_target_contact_intensity = 0.0
	_state_age = 0.0


func set_environment_contact_intensity(value: float) -> void:
	_target_contact_intensity = clamp(value, 0.0, 1.0)


func _apply_breathing() -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var breathe := 1.0 + sin(time * 2.1) * 0.02
	idle_sprite.scale = _base_scale * Vector2(1.0 - (breathe - 1.0) * 0.35, breathe)
	idle_sprite.position = _sprite_base_position
	state_overlay.position = _overlay_base_position
	inner_glow.position = _glow_base_position
	inner_glow.modulate = Color(0.72, 0.94, 0.92, 0.31 + sin(time * 1.8) * 0.025)
	surface_highlight.position = _highlight_base_position
	surface_highlight.modulate = Color(0.9, 1.0, 0.96, 0.05 + sin(time * 1.25 + 0.6) * 0.014)


func _apply_motion_feel(input_x: float) -> void:
	var stretch: float = clamp(absf(velocity.x) / move_speed, 0.0, 1.0)
	var direction := _last_move_direction if absf(input_x) <= 0.01 else signf(input_x)
	var start_kick := _start_pulse * 0.05
	var stop_weight: float = _stop_settle / max(stop_settle_time, 0.01)
	var target_body := _base_scale * Vector2(
		1.0 + stretch * body_stretch_strength + start_kick - stop_weight * 0.035,
		1.0 - stretch * body_stretch_strength * 0.64 + stop_weight * 0.05
	)
	idle_sprite.scale = idle_sprite.scale.lerp(target_body, 0.16)
	inner_glow.position.x = move_toward(inner_glow.position.x, _glow_base_position.x + direction * stretch * core_lag_strength, 0.85)
	surface_highlight.position.x = move_toward(
		surface_highlight.position.x,
		_highlight_base_position.x - direction * stretch * highlight_drift_strength,
		0.55
	)
	surface_highlight.scale = surface_highlight.scale.lerp(
		_highlight_base_scale * Vector2(1.0 + stretch * 0.18, 1.0 - stretch * 0.1),
		0.12
	)


func _apply_expression_state(input_x: float, delta: float) -> void:
	var visual_state := _resolve_visual_state(input_x)
	if visual_state != _visual_state:
		_visual_state = visual_state
		_state_age = 0.0
		_update_layer_textures(visual_state)
		_update_pose_texture(visual_state)
	else:
		_state_age += delta

	var target_sprite_scale := idle_sprite.scale
	var target_sprite_position := idle_sprite.position
	var target_pose_position := expression_pose.position
	var target_overlay_position := state_overlay.position
	var target_glow_position := inner_glow.position
	var target_highlight_position := surface_highlight.position
	var target_glow_alpha := inner_glow.modulate.a
	var target_highlight_alpha := surface_highlight.modulate.a
	var target_pose_alpha := 0.0
	var target_overlay_alpha := state_overlay.modulate.a
	var ease_in: float = 1.0 - exp(-_state_age * 7.0)
	var should_use_move_animation := visual_state in ["move", "approach", "leave"] and absf(velocity.x) > 2.0

	if should_use_move_animation and idle_sprite.animation != &"move":
		idle_sprite.play("move")
	elif not should_use_move_animation and idle_sprite.animation != &"idle":
		idle_sprite.play("idle")

	match visual_state:
		"pause":
			target_sprite_scale = _base_scale * Vector2(0.95, 1.07)
			target_sprite_position += Vector2(0.0, 6.0)
			target_pose_position = target_sprite_position
			target_overlay_position += Vector2(0.0, 4.0)
			target_glow_position += Vector2(0.0, 3.0)
			target_highlight_position += Vector2(0.0, 2.0)
			target_glow_alpha = 0.34 + ease_in * 0.08
			target_highlight_alpha = 0.045
			target_pose_alpha = 0.11
			target_overlay_alpha = 0.14
		"approach":
			var direction := signf(velocity.x) if absf(velocity.x) > 0.1 else _last_move_direction
			target_sprite_scale = _base_scale * Vector2(1.04, 0.975)
			target_sprite_position += Vector2(direction * 5.0, 2.0)
			target_pose_position = target_sprite_position
			target_glow_position += Vector2(direction * 8.0, 1.0)
			target_highlight_position += Vector2(-direction * 5.0, 1.0)
			target_glow_alpha = 0.36 + ease_in * 0.05
			target_highlight_alpha = 0.06
			target_pose_alpha = 0.1
			target_overlay_alpha = 0.13
		"nestle":
			target_sprite_scale = _base_scale * Vector2(0.925, 1.11)
			target_sprite_position += Vector2(-4.0, 10.0)
			target_pose_position = target_sprite_position
			target_overlay_position += Vector2(-3.0, 8.0)
			target_glow_position += Vector2(-7.0, 7.0)
			target_highlight_position += Vector2(-7.0, 5.0)
			target_glow_alpha = 0.42 + sin(Time.get_ticks_msec() / 1000.0 * 1.35) * 0.018
			target_highlight_alpha = 0.045
			target_pose_alpha = 0.12
			target_overlay_alpha = 0.15
		"leave":
			var direction := signf(velocity.x) if absf(velocity.x) > 0.1 else _last_move_direction
			target_sprite_scale = _base_scale * Vector2(1.11, 0.945)
			target_sprite_position += Vector2(direction * 9.0, 1.0)
			target_pose_position = target_sprite_position
			target_glow_position += Vector2(direction * 8.0, -1.0)
			target_highlight_position += Vector2(-direction * 7.0, -1.0)
			target_glow_alpha = 0.34
			target_highlight_alpha = 0.06
			target_pose_alpha = 0.13
			target_overlay_alpha = 0.1

	var sprite_lerp: float = 1.0 - exp(-delta * 13.0)
	var detail_lerp: float = 1.0 - exp(-delta * 10.0)
	idle_sprite.scale = idle_sprite.scale.lerp(target_sprite_scale, sprite_lerp)
	idle_sprite.position = idle_sprite.position.lerp(target_sprite_position, sprite_lerp)
	expression_pose.scale = expression_pose.scale.lerp(target_sprite_scale, sprite_lerp)
	expression_pose.position = expression_pose.position.lerp(target_pose_position, sprite_lerp)
	state_overlay.position = state_overlay.position.lerp(target_overlay_position, detail_lerp)
	inner_glow.position = inner_glow.position.lerp(target_glow_position, detail_lerp)
	surface_highlight.position = surface_highlight.position.lerp(target_highlight_position, detail_lerp)
	inner_glow.modulate.a = lerp(inner_glow.modulate.a, target_glow_alpha, detail_lerp)
	surface_highlight.modulate.a = lerp(surface_highlight.modulate.a, target_highlight_alpha, detail_lerp)
	_target_pose_alpha = target_pose_alpha
	_pose_alpha = lerp(_pose_alpha, _target_pose_alpha, detail_lerp)
	expression_pose.modulate.a = _pose_alpha
	state_overlay.modulate.a = lerp(state_overlay.modulate.a, target_overlay_alpha, detail_lerp)


func _apply_feedback_layers(input_x: float, delta: float) -> void:
	var speed_mix: float = clamp(absf(velocity.x) / move_speed, 0.0, 1.0)
	var direction := signf(velocity.x) if absf(velocity.x) > 0.1 else _last_move_direction
	var visual_state := _resolve_visual_state(input_x)
	var target_contact := _target_contact_intensity
	if visual_state == "nestle":
		target_contact = max(target_contact, 0.86)
	elif visual_state == "pause":
		target_contact = max(target_contact, 0.36)
	elif visual_state == "leave":
		target_contact = max(target_contact, 0.18)

	_contact_intensity = lerp(_contact_intensity, target_contact, 1.0 - exp(-delta * 4.8))
	var trail_alpha := speed_mix * trail_strength
	if visual_state == "approach":
		trail_alpha += 0.025
	elif visual_state == "leave":
		trail_alpha += 0.045
		motion_trail.texture = TRAIL_TEXTURES["leave"]
	elif visual_state == "nestle":
		trail_alpha = 0.018
		motion_trail.texture = TRAIL_TEXTURES["soft"]
	else:
		motion_trail.texture = TRAIL_TEXTURES["motion"]

	motion_trail.flip_h = idle_sprite.flip_h
	motion_trail.position = motion_trail.position.lerp(
		_trail_base_position + Vector2(-direction * (18.0 + speed_mix * 16.0), 6.0 + speed_mix * 4.0),
		1.0 - exp(-delta * 8.0)
	)
	motion_trail.scale = motion_trail.scale.lerp(
		_trail_base_scale * Vector2(1.0 + speed_mix * 0.26, 0.86 - speed_mix * 0.18),
		1.0 - exp(-delta * 8.0)
	)
	motion_trail.modulate = Color(0.54, 0.86, 0.9, clamp(trail_alpha, 0.0, 0.13))

	var time := Time.get_ticks_msec() / 1000.0
	var contact_sway := sin(time * 1.6) * 2.5 * _contact_intensity
	soft_shadow.position = _shadow_base_position + Vector2(contact_sway * 0.35, 0.0)
	soft_shadow.color = Color(0.04, 0.08, 0.07, 0.11 + speed_mix * 0.025 + _contact_intensity * 0.055)
	wet_trace.position = _wet_trace_base_position + Vector2(contact_sway, 0.0)
	wet_trace.color = Color(0.52, 0.78, 0.68, 0.025 + _contact_intensity * 0.095)
	contact_glow.position = _contact_base_position + Vector2(sin(time * 1.6) * 2.5 * _contact_intensity, 0.0)
	contact_glow.color = Color(0.58, 0.88, 0.76, contact_glow_strength * _contact_intensity)


func _update_movement_phase(raw_input_x: float, delta: float) -> void:
	var input_active := absf(raw_input_x) > 0.01
	if input_active and not _was_input_active:
		_start_pulse = 1.0
		_stop_settle = 0.0
	if not input_active and _was_input_active:
		_stop_settle = stop_settle_time
	_start_pulse = move_toward(_start_pulse, 0.0, delta * 4.8)
	_stop_settle = move_toward(_stop_settle, 0.0, delta)
	_was_input_active = input_active


func _update_layer_textures(visual_state: String) -> void:
	var texture_key := visual_state
	if not LAYER_CORE_TEXTURES.has(texture_key):
		texture_key = "idle"
	inner_glow.texture = LAYER_CORE_TEXTURES[texture_key]
	surface_highlight.texture = LAYER_HIGHLIGHT_TEXTURES[texture_key]


func _update_pose_texture(visual_state: String) -> void:
	if POSE_TEXTURES.has(visual_state):
		expression_pose.texture = POSE_TEXTURES[visual_state]


func _resolve_visual_state(input_x: float) -> String:
	if _expression_state_override != "":
		return _expression_state_override
	if absf(input_x) > 0.01:
		return "move"
	return "idle"


func _assign_runtime_frames() -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_loop("idle", true)
	sprite_frames.set_animation_speed("idle", 6.0)
	for frame in IDLE_FRAMES:
		sprite_frames.add_frame("idle", frame)

	sprite_frames.add_animation("move")
	sprite_frames.set_animation_loop("move", true)
	sprite_frames.set_animation_speed("move", 10.0)
	for frame in MOVE_FRAMES:
		sprite_frames.add_frame("move", frame)

	idle_sprite.sprite_frames = sprite_frames


func _setup_audio() -> void:
	idle_audio.stream = _prepare_looping_stream(IDLE_WATER_SOUND)
	move_audio.stream = _prepare_looping_stream(MOVE_WATER_SOUND)
	idle_audio.volume_db = -20.0
	move_audio.volume_db = -18.5
	idle_audio.play()


func _update_audio(input_x: float) -> void:
	var is_moving := _control_enabled and absf(input_x) > 0.01
	if is_moving:
		if idle_audio.playing:
			idle_audio.stop()
		if not move_audio.playing:
			move_audio.play()
	else:
		if move_audio.playing:
			move_audio.stop()
		if not idle_audio.playing:
			idle_audio.play()

	var speed_mix: float = clamp(absf(velocity.x) / move_speed, 0.0, 1.0)
	idle_audio.volume_db = -22.0 + (1.0 - speed_mix) * 2.0
	move_audio.volume_db = -21.0 + speed_mix * 4.0


func _prepare_looping_stream(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		var looped_stream := stream.duplicate() as AudioStreamWAV
		looped_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return looped_stream
	return stream
