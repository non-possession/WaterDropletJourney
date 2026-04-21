extends CharacterBody2D

class_name WaterPlayer

const STATE_TEXTURES := {
	"calm": preload("res://assets/sprites/water_states/water_calm.png"),
	"cold": preload("res://assets/sprites/water_states/water_cold.png"),
	"tense": preload("res://assets/sprites/water_states/water_tense.png"),
}
const IDLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/water_player/idle_00.png"),
	preload("res://assets/sprites/water_player/idle_01.png"),
	preload("res://assets/sprites/water_player/idle_02.png"),
	preload("res://assets/sprites/water_player/idle_03.png"),
	preload("res://assets/sprites/water_player/idle_04.png"),
	preload("res://assets/sprites/water_player/idle_05.png"),
]
const MOVE_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/water_player_sheet/move_sheet_00.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_01.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_02.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_03.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_04.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_05.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_06.png"),
	preload("res://assets/sprites/water_player_sheet/move_sheet_07.png"),
]
const IDLE_WATER_SOUND := preload("res://assets/audio/ch1/protagonist_idle_subtle_water.wav")
const MOVE_WATER_SOUND := preload("res://assets/audio/ch1/protagonist_light_movement_water.wav")

@export var move_speed := 125.0
@export var accel := 420.0
@export var damping := 520.0
@export var drift_gravity := 380.0
@export var gentle_lift := -45.0

@onready var idle_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_overlay: Sprite2D = $StateOverlay
@onready var inner_glow: Sprite2D = $InnerGlow
@onready var idle_audio: AudioStreamPlayer = $IdleWaterAudio
@onready var move_audio: AudioStreamPlayer = $MoveWaterAudio

var _control_enabled := false
var _base_scale := Vector2.ONE


func _ready() -> void:
	_assign_runtime_frames()
	_setup_audio()
	idle_sprite.play("idle")
	_base_scale = idle_sprite.scale
	set_state_visual("calm")


func _physics_process(delta: float) -> void:
	if not _control_enabled:
		velocity.x = move_toward(velocity.x, 0.0, damping * delta)
		velocity.y = move_toward(velocity.y, gentle_lift, 260.0 * delta)
		move_and_slide()
		_apply_breathing()
		_update_audio(0.0)
		return

	var input_x := Input.get_axis("move_left", "move_right")
	if absf(input_x) > 0.01:
		if idle_sprite.animation != &"move":
			idle_sprite.play("move")
		velocity.x = move_toward(velocity.x, input_x * move_speed, accel * delta)
		look_direction(signf(input_x))
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
	state_overlay.flip_h = direction < 0.0
	inner_glow.flip_h = direction < 0.0


func set_state_visual(state_name: String) -> void:
	match state_name:
		"cold":
			state_overlay.texture = STATE_TEXTURES["cold"]
			state_overlay.modulate = Color(1, 1, 1, 0.34)
		"tense":
			state_overlay.texture = STATE_TEXTURES["tense"]
			state_overlay.modulate = Color(1, 1, 1, 0.22)
		_:
			state_overlay.texture = STATE_TEXTURES["calm"]
			state_overlay.modulate = Color(1, 1, 1, 0.18)


func _apply_breathing() -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var breathe := 1.0 + sin(time * 2.1) * 0.02
	idle_sprite.scale = _base_scale * Vector2(1.0 - (breathe - 1.0) * 0.35, breathe)
	inner_glow.modulate.a = 0.72 + sin(time * 1.8) * 0.06


func _apply_motion_feel(input_x: float) -> void:
	var stretch: float = clamp(absf(velocity.x) / move_speed, 0.0, 1.0)
	idle_sprite.scale = idle_sprite.scale.lerp(_base_scale * Vector2(1.0 + stretch * 0.08, 1.0 - stretch * 0.05), 0.16)
	inner_glow.position.x = move_toward(inner_glow.position.x, input_x * 4.0, 0.6)


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
