extends Node2D

@onready var player: WaterPlayer = $Player
@onready var camera: Camera2D = $Camera2D
@onready var bush: Node2D = $BushInteraction
@onready var objective_label: Label = %ObjectiveLabel

@export var default_zoom := Vector2(0.96, 0.96)
@export var approach_zoom := Vector2(0.9, 0.9)
@export var nestle_zoom := Vector2(0.84, 0.84)
@export var camera_follow_near := 3.8
@export var camera_follow_intimate := 2.1
@export var camera_zoom_response := 4.5


func _ready() -> void:
	player.set_control_enabled(true)
	player.look_east()
	objective_label.text = "靠近灌木并停驻，让它回应你。"
	bush.interaction_started.connect(_on_interaction_started)
	bush.interaction_settled.connect(_on_interaction_settled)
	bush.interaction_ended.connect(_on_interaction_ended)
	camera.zoom = default_zoom


func _process(delta: float) -> void:
	var player_target: Vector2 = player.global_position + Vector2(80.0, -70.0)
	var bush_target: Vector2 = bush.global_position + Vector2(-24.0, -60.0)
	var focus_ratio: float = bush.get_focus_ratio()
	var presence_ratio: float = bush.get_presence_ratio()
	var target: Vector2 = player_target.lerp(bush_target, focus_ratio)
	var follow_speed: float = lerp(camera_follow_near, camera_follow_intimate, focus_ratio)
	var target_zoom: Vector2 = default_zoom.lerp(approach_zoom, focus_ratio).lerp(nestle_zoom, presence_ratio)
	camera.global_position = camera.global_position.lerp(target, min(delta * follow_speed, 1.0))
	camera.zoom = camera.zoom.lerp(target_zoom, min(delta * camera_zoom_response, 1.0))


func _on_interaction_started() -> void:
	objective_label.text = "停一小会儿，感受灌木的回应。"


func _on_interaction_settled() -> void:
	objective_label.text = "它正在回应你。轻轻离开，再向前。"


func _on_interaction_ended() -> void:
	objective_label.text = "你已经和它相遇过了。"
