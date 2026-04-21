extends Node2D

const FORM_LIQUID := 0
const FORM_ICE := 1
const FORM_MIST := 2

const FORM_VERSES := {
	FORM_LIQUID: "液态让你穿行、贴近、继续向前。",
	FORM_ICE: "冰态让你承受寒冷，也借此学会稳定。",
	FORM_MIST: "雾态让你暂时摆脱重量，却更容易被世界带走。",
}

const FORM_HINTS := {
	FORM_LIQUID: "液态适合穿行与基础移动，是旅程开始时最自然的样子。",
	FORM_ICE: "冰态更滑、更稳，适合借助平台延伸前行。",
	FORM_MIST: "雾态可以缓慢上升，像情绪一样漂浮与扩散。",
}

@onready var player := $Player
@onready var state_label: Label = %StateLabel
@onready var hint_label: Label = %HintLabel
@onready var verse_label: Label = %VerseLabel


func _ready() -> void:
	_refresh_ui()


func _process(_delta: float) -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	var form: int = player.current_form
	state_label.text = "状态：%s" % player.get_form_name()
	hint_label.text = "A/D 或 方向键移动，Space 跳跃，Tab 切换形态\n%s" % FORM_HINTS[form]
	verse_label.text = FORM_VERSES[form]
