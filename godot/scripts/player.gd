class_name Player extends CharacterBody2D

signal picked_up(item: String)

const SPEED: float = 120.0

@onready var health: Health = $Health

var facing: int = 1


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	velocity.x = axis * SPEED
	if not is_zero_approx(axis):
		# signi() takes an int, so int(axis) would flatten any analog value
		# below 1.0 to facing 0. The axis is already non-zero here.
		facing = 1 if axis > 0.0 else -1
	if not is_on_floor():
		velocity.y += 800.0 * delta
	@warning_ignore("return_value_discarded")
	move_and_slide()


func pick_up(item: String) -> void:
	picked_up.emit(item)
