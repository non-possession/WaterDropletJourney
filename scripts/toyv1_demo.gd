extends Node2D

@onready var player: WaterPlayer = $Player
@onready var camera: Camera2D = $Camera2D
@onready var bush: Node2D = $BushInteraction
@onready var objective_label: Label = %ObjectiveLabel

var _default_zoom := Vector2(0.96, 0.96)
var _approach_zoom := Vector2(0.9, 0.9)
var _nestle_zoom := Vector2(0.84, 0.84)


func _ready() -> void:
	player.set_control_enabled(true)
	player.look_east()
	objective_label.text = "靠近灌木并停驻，让它回应你。"
	bush.interaction_started.connect(_on_interaction_started)
	bush.interaction_settled.connect(_on_interaction_settled)
	bush.interaction_ended.connect(_on_interaction_ended)
	camera.zoom = _default_zoom


func _process(delta: float) -> void:
	var player_target: Vector2 = player.global_position + Vector2(80.0, -70.0)
	var bush_target: Vector2 = bush.global_position + Vector2(-24.0, -60.0)
	var target: Vector2 = player_target.lerp(bush_target, bush.get_focus_ratio())
	var follow_speed: float = lerp(3.8, 2.1, bush.get_focus_ratio())
	camera.global_position = camera.global_position.lerp(target, min(delta * follow_speed, 1.0))


func _on_interaction_started() -> void:
	_tween_zoom(_approach_zoom, 0.45)
	objective_label.text = "停一小会儿，感受灌木的回应。"


func _on_interaction_settled() -> void:
	_tween_zoom(_nestle_zoom, 0.6)
	objective_label.text = "它正在回应你。轻轻离开，再向前。"


func _on_interaction_ended() -> void:
	_tween_zoom(_default_zoom, 0.7)
	objective_label.text = "你已经和它相遇过了。"


func _tween_zoom(target_zoom: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", target_zoom, duration)
