class_name Player extends CharacterBody2D

const SPEED: float = 120.0

@export_category("Nodes")
@export var health: Health

var c_facing: int = 1

signal picked_up(item: String)


func _ready() -> void:
	assert(health, "player.gd - @export health is not set in the editor on: " + self.name)


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = axis * SPEED
	if !is_zero_approx(axis):
		# signi() takes an int, so int(axis) would flatten any analog value
		# below 1.0 to c_facing 0. The axis is already non-zero here.
		c_facing = 1 if axis > 0.0 else -1
	if !is_on_floor():
		velocity.y += 800.0 * delta
	var _collided: bool = move_and_slide()


func pick_up(item: String) -> void:
	picked_up.emit(item)
