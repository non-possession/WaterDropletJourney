extends Node2D

const SHOT_CAPTIONS := [
	{
		"title": "镜头 1 / 高山与来风",
		"body": "东边的大海送来水汽，越过长途，在高山之上化作雪、冰与流动之水。",
		"duration": 3.8,
	},
	{
		"title": "镜头 2 / 群体分化",
		"body": "同样来自水，有些停留，有些随风，有些开始望向远方。",
		"duration": 3.2,
	},
	{
		"title": "镜头 3 / 被看见",
		"body": "在群体之中，ta 比周围更稳定一些，像有微弱而不熄的内光。",
		"duration": 3.4,
	},
	{
		"title": "镜头 4 / 短暂连接",
		"body": "几滴同样想离开的水灵轻轻靠近，像无言地交换了方向。",
		"duration": 3.0,
	},
	{
		"title": "镜头 5 / 决意",
		"body": "一部分留下，一部分离开。ta 稍稍停住，然后面向东方。",
		"duration": 3.6,
	},
	{
		"title": "镜头 6 / 交出控制",
		"body": "从这里开始，第一步由你亲自带 ta 走出去。",
		"duration": 1.2,
	},
]

const SHOT_PATHS := [
	NodePath("ShotMarkers/Shot1"),
	NodePath("ShotMarkers/Shot2"),
	NodePath("ShotMarkers/Shot3"),
	NodePath("ShotMarkers/Shot4"),
	NodePath("ShotMarkers/Shot5"),
	NodePath("ShotMarkers/Shot6"),
]
const MOUNTAIN_BACKDROP := preload("res://assets/originals/雪山远景背景.png")
const SNOW_PLATFORM := preload("res://assets/tiles/ch1_snow_mid/snow_platform_long_01.png")
const ICE_PLATFORM := preload("res://assets/tiles/ch1_snow_mid/ice_platform_long_01.png")
const SNOW_SLOPE := preload("res://assets/tiles/ch1_snow_mid/snow_platform_slope_01.png")
const EXIT_CLIFF := preload("res://assets/tiles/ch1_snow_mid/cliff_block_02.png")
const MIST_PATCH := preload("res://assets/tiles/ch1_snow_mid/mist_patch_02.png")
const WIND_AMBIENCE := preload("res://assets/audio/ch1/high_mountain_wind_ambience_30s.wav")
const WIND_DETAIL := preload("res://assets/audio/ch1/light_icy_snow_wind_cut.wav")
const CONTROL_CUE := preload("res://assets/audio/ch1/control_handoff_subtle_cue.wav")

@onready var player: WaterPlayer = $Player
@onready var camera: Camera2D = $Camera2D
@onready var shot_title: Label = %ShotTitle
@onready var shot_body: Label = %ShotBody
@onready var control_hint: Label = %ControlHint
@onready var objective_label: Label = %ObjectiveLabel
@onready var east_glow: ColorRect = $BackgroundCanvas/EastGlow
@onready var far_mist: ColorRect = $BackgroundCanvas/FarMist
@onready var sibling_group: Node2D = $WaterSiblings
@onready var drift_group: Node2D = $SnowAndMist
@onready var mountain_backdrop: Sprite2D = $World/MountainBackdrop
@onready var ground_snow_a: Sprite2D = $World/PlayableGround/GroundSnowA
@onready var ground_snow_b: Sprite2D = $World/PlayableGround/GroundSnowB
@onready var ground_ice: Sprite2D = $World/PlayableGround/GroundIce
@onready var slope_sprite: Sprite2D = $World/Slope/SlopeSprite
@onready var ice_shelf_sprite: Sprite2D = $World/IceShelf/IceShelfSprite
@onready var exit_cliff: Sprite2D = $World/ExitRise/ExitCliff
@onready var mist_patch: Sprite2D = $World/MistPatchNearGround
@onready var wind_ambience_player: AudioStreamPlayer = $Audio/WindAmbience
@onready var wind_detail_player: AudioStreamPlayer = $Audio/WindDetail
@onready var control_cue_player: AudioStreamPlayer = $Audio/ControlCue

var _intro_complete := false


func _ready() -> void:
	_assign_runtime_environment_art()
	_setup_audio()
	player.set_control_enabled(false)
	player.look_east()
	control_hint.visible = false
	objective_label.visible = false
	_start_intro()


func _process(delta: float) -> void:
	_animate_ambient_layers(delta)
	_animate_siblings(delta)
	_refresh_audio_layers()

	if _intro_complete:
		_update_follow_camera(delta)


func _start_intro() -> void:
	await get_tree().process_frame
	for index in range(SHOT_CAPTIONS.size()):
		var shot: Dictionary = SHOT_CAPTIONS[index]
		var marker: Camera2D = get_node(SHOT_PATHS[index])
		_set_caption(String(shot["title"]), String(shot["body"]))
		await _tween_camera(marker.global_position, marker.zoom, float(shot["duration"]))

	_finish_intro()


func _finish_intro() -> void:
	_intro_complete = true
	player.set_control_enabled(true)
	control_cue_player.play()
	control_hint.visible = true
	objective_label.visible = true
	shot_title.text = "第一章 / 离开的开始"
	shot_body.text = "沿着雪坡与冰面向前，让 ta 亲手踏上回归大海的旅程。"


func _set_caption(title: String, body: String) -> void:
	shot_title.text = title
	shot_body.text = body


func _tween_camera(target_position: Vector2, target_zoom: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", target_position, duration)
	tween.tween_property(camera, "zoom", target_zoom, duration)
	await tween.finished


func _update_follow_camera(delta: float) -> void:
	var target := player.global_position + Vector2(180.0, -80.0)
	camera.global_position = camera.global_position.lerp(target, min(delta * 1.8, 1.0))
	camera.zoom = camera.zoom.lerp(Vector2(0.86, 0.86), min(delta * 1.6, 1.0))


func _animate_ambient_layers(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	east_glow.modulate.a = 0.16 + sin(time * 0.35) * 0.03
	far_mist.modulate.a = 0.22 + sin(time * 0.22) * 0.02
	far_mist.position.x = sin(time * 0.12) * 18.0

	for child in drift_group.get_children():
		if child is Node2D:
			var base_y: float = float(child.get_meta("base_y", child.position.y))
			child.position.y = float(base_y) + sin(time * 0.7 + child.position.x * 0.01) * 5.0


func _animate_siblings(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for child in sibling_group.get_children():
		if not child is Node2D:
			continue
		var node := child as Node2D
		var base: Vector2 = node.get_meta("base_position", node.position) as Vector2
		var role := String(node.get_meta("role", "still"))
		match role:
			"intent":
				node.position = base + Vector2(sin(time * 0.8 + base.x * 0.01) * 6.0, cos(time * 1.2 + base.y * 0.01) * 4.0)
				node.rotation = sin(time * 0.6 + base.x * 0.01) * 0.04
			"snow":
				node.position = base + Vector2(sin(time * 0.9 + base.y * 0.02) * 10.0, cos(time * 0.6 + base.x * 0.01) * 8.0)
			_:
				node.position = base + Vector2(0.0, sin(time * 0.4 + base.x * 0.01) * 2.0)
		node.set_meta("base_position", base)


func _assign_runtime_environment_art() -> void:
	mountain_backdrop.texture = MOUNTAIN_BACKDROP
	ground_snow_a.texture = SNOW_PLATFORM
	ground_snow_b.texture = SNOW_PLATFORM
	ground_ice.texture = ICE_PLATFORM
	slope_sprite.texture = SNOW_SLOPE
	ice_shelf_sprite.texture = ICE_PLATFORM
	exit_cliff.texture = EXIT_CLIFF
	mist_patch.texture = MIST_PATCH


func _setup_audio() -> void:
	wind_ambience_player.stream = _prepare_looping_stream(WIND_AMBIENCE)
	wind_detail_player.stream = _prepare_looping_stream(WIND_DETAIL)
	control_cue_player.stream = CONTROL_CUE
	wind_ambience_player.volume_db = -16.0
	wind_detail_player.volume_db = -24.0
	control_cue_player.volume_db = -15.0
	wind_ambience_player.play()
	wind_detail_player.play()


func _refresh_audio_layers() -> void:
	if not wind_ambience_player.playing:
		wind_ambience_player.play()
	if not wind_detail_player.playing:
		wind_detail_player.play()

	var time := Time.get_ticks_msec() / 1000.0
	wind_ambience_player.volume_db = -16.5 + sin(time * 0.11) * 0.8
	wind_detail_player.volume_db = -24.5 + sin(time * 0.19 + 1.4) * 1.2


func _prepare_looping_stream(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		var looped_stream := stream.duplicate() as AudioStreamWAV
		looped_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return looped_stream
	return stream
