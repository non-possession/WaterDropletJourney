extends Node2D

class_name BushInteraction

signal interaction_started
signal interaction_settled
signal interaction_ended

const RESPONSE_SOUND := preload("res://assets/audio/ch1/control_handoff_subtle_cue.wav")

@export var detection_radius := 110.0
@export var settle_time := 0.85
@export var glow_strength := 0.65
@export var sway_amount := 8.0
@export var auto_reset_delay := 0.45
@export var settle_speed_threshold := 14.0

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var bush_pivot: Node2D = $BushPivot
@onready var bush_glow: Polygon2D = $BushPivot/BushGlow
@onready var foliage_back: Sprite2D = $BushPivot/FoliageBack
@onready var foliage_front: Sprite2D = $BushPivot/FoliageFront
@onready var ground_grass: Sprite2D = $BushPivot/GroundGrass
@onready var sparkle_a: Polygon2D = $BushPivot/Sparkles/SparkleA
@onready var sparkle_b: Polygon2D = $BushPivot/Sparkles/SparkleB
@onready var sparkle_c: Polygon2D = $BushPivot/Sparkles/SparkleC
@onready var response_audio: AudioStreamPlayer = $ResponseAudio

var _player: WaterPlayer
var _departing_player: WaterPlayer
var _dwell_time := 0.0
var _is_settled := false
var _leave_timer := 0.0
var _focus_ratio := 0.0
var _presence := 0.0
var _residual_presence := 0.0


func _ready() -> void:
	var shape: Shape2D = detection_shape.shape
	if shape is CircleShape2D:
		(shape as CircleShape2D).radius = detection_radius

	response_audio.stream = RESPONSE_SOUND
	response_audio.volume_db = -24.0
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	_update_visuals(0.0)


func _process(delta: float) -> void:
	var time: float = Time.get_ticks_msec() / 1000.0
	var sway_wave: float = sin(time * 1.8) * 0.01
	var sparkle_wave: float = sin(time * 2.2)
	var target_presence: float = 0.0

	if _player and is_instance_valid(_player):
		target_presence = 0.45
		var player_distance: float = global_position.distance_to(_player.global_position)
		var close_ratio: float = clamp(1.0 - (player_distance / max(detection_radius, 1.0)), 0.0, 1.0)
		_focus_ratio = lerp(_focus_ratio, 0.25 + close_ratio * 0.4, min(delta * 4.0, 1.0))

		if _is_settled:
			target_presence = 1.0
			_player.set_environment_contact_intensity(1.0)
			_player.set_expression_state("nestle")
		else:
			var is_slow: bool = _player.velocity.length() <= settle_speed_threshold
			var is_close: bool = player_distance <= detection_radius * 0.7
			if is_close and is_slow:
				_dwell_time += delta
				target_presence = max(target_presence, 0.58 + (_dwell_time / max(settle_time, 0.01)) * 0.3)
				_player.set_environment_contact_intensity(0.28 + clamp(_dwell_time / max(settle_time, 0.01), 0.0, 1.0) * 0.42)
				_player.set_expression_state("pause")
			else:
				_dwell_time = max(_dwell_time - delta * 1.8, 0.0)
				_player.set_environment_contact_intensity(close_ratio * 0.22)
				_player.set_expression_state("approach")

			if _dwell_time >= settle_time:
				_is_settled = true
				target_presence = 1.0
				_residual_presence = 1.0
				_player.set_environment_contact_intensity(1.0)
				_player.set_expression_state("nestle")
				response_audio.play()
				interaction_settled.emit()
	else:
		_focus_ratio = lerp(_focus_ratio, 0.0, min(delta * 3.0, 1.0))
		_residual_presence = move_toward(_residual_presence, 0.0, delta * 0.34)
		if _leave_timer > 0.0:
			_leave_timer -= delta
			target_presence = max(0.18, _residual_presence)
			if _departing_player and is_instance_valid(_departing_player):
				_departing_player.set_environment_contact_intensity(max(_residual_presence * 0.34, 0.1))
				_departing_player.set_expression_state("leave")
			if _leave_timer <= 0.0 and _departing_player and is_instance_valid(_departing_player):
				_departing_player.set_environment_contact_intensity(0.0)
				_departing_player.clear_expression_state()
				_departing_player = null
		else:
			target_presence = _residual_presence

	_presence = lerp(_presence, target_presence, min(delta * 3.8, 1.0))
	bush_pivot.rotation = sway_wave * (0.5 + _presence * 1.2) * sway_amount / 10.0
	foliage_front.position.y = -8.0 + sin(time * 2.1 + 0.7) * (1.0 + _presence * 2.0)
	foliage_front.position.x = -4.0 + sin(time * 1.15) * _presence * 1.2
	ground_grass.position.y = 26.0 + sin(time * 1.6) * _presence * 0.8

	var sparkle_alpha: float = 0.08 + max(_presence, 0.0) * 0.34
	sparkle_a.modulate.a = sparkle_alpha + max(sparkle_wave, 0.0) * 0.12
	sparkle_b.modulate.a = sparkle_alpha * 0.85 + max(sin(time * 2.7 + 0.9), 0.0) * 0.1
	sparkle_c.modulate.a = sparkle_alpha * 0.7 + max(sin(time * 1.9 + 1.8), 0.0) * 0.08

	_update_visuals(_presence)


func get_focus_ratio() -> float:
	return _focus_ratio


func _update_visuals(presence: float) -> void:
	bush_glow.modulate = Color(0.74, 1.0, 0.78, 0.06 + presence * glow_strength * 0.34)
	foliage_back.modulate = Color(0.86 + presence * 0.09, 0.93 + presence * 0.06, 0.88 + presence * 0.02, 1.0)
	foliage_front.modulate = Color(0.92 + presence * 0.08, 0.99, 0.9 + presence * 0.04, 0.92 + presence * 0.08)
	ground_grass.modulate = Color(0.9 + presence * 0.08, 0.98, 0.9 + presence * 0.06, 1.0)


func _on_body_entered(body: Node) -> void:
	if not body is WaterPlayer:
		return
	_player = body as WaterPlayer
	_departing_player = null
	_dwell_time = 0.0
	_leave_timer = 0.0
	_is_settled = false
	interaction_started.emit()


func _on_body_exited(body: Node) -> void:
	if body != _player:
		return
	_departing_player = _player
	_player = null
	_dwell_time = 0.0
	_leave_timer = auto_reset_delay
	if _is_settled:
		_residual_presence = 1.0
		interaction_ended.emit()
	_is_settled = false
