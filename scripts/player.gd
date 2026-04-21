extends CharacterBody2D

class_name WaterPlayer

enum Form {
	LIQUID,
	ICE,
	MIST,
}

const FORM_NAMES := {
	Form.LIQUID: "液态",
	Form.ICE: "冰态",
	Form.MIST: "雾态",
}

const FORM_COLORS := {
	Form.LIQUID: Color(0.53, 0.83, 1.0, 0.95),
	Form.ICE: Color(0.84, 0.95, 1.0, 1.0),
	Form.MIST: Color(0.92, 0.97, 1.0, 0.72),
}

@export var current_form: Form = Form.LIQUID

@onready var body: Polygon2D = $Body

var _gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float


func _ready() -> void:
	_apply_form_visuals()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_state"):
		_cycle_form()

	var input_x := Input.get_axis("move_left", "move_right")
	var input_y := Input.get_axis("move_up", "move_down")

	match current_form:
		Form.LIQUID:
			_update_liquid(input_x, delta)
		Form.ICE:
			_update_ice(input_x, delta)
		Form.MIST:
			_update_mist(input_x, input_y, delta)

	move_and_slide()


func _update_liquid(input_x: float, delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = -310.0

	velocity.x = move_toward(velocity.x, input_x * 210.0, 880.0 * delta)


func _update_ice(input_x: float, delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * 1.1 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = -250.0

	var target := input_x * 285.0
	var accel := 420.0 if absf(target) > 0.01 else 120.0
	velocity.x = move_toward(velocity.x, target, accel * delta)


func _update_mist(input_x: float, input_y: float, delta: float) -> void:
	var target_x := input_x * 170.0
	var target_y := input_y * 150.0 - 60.0
	velocity.x = move_toward(velocity.x, target_x, 540.0 * delta)
	velocity.y = move_toward(velocity.y, target_y, 360.0 * delta)


func _cycle_form() -> void:
	current_form = (current_form + 1) % Form.size()
	_apply_form_visuals()


func _apply_form_visuals() -> void:
	body.color = FORM_COLORS[current_form]
	match current_form:
		Form.LIQUID:
			body.scale = Vector2(1.0, 1.0)
		Form.ICE:
			body.scale = Vector2(0.95, 1.18)
		Form.MIST:
			body.scale = Vector2(1.18, 0.8)


func get_form_name() -> String:
	return FORM_NAMES[current_form]
