class_name Player extends CharacterBody2D

enum Direction { left = -1, right = 1 }

const SPEED: float = 120.0

@export_category("Nodes")
@export var health: Health

var c_direction: Direction = Direction.right

signal picked_up(item: String)


func _ready() -> void:
	assert(health, "player.gd - @export health is not set in the editor on: " + self.name)


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis(&"dpad_left", &"dpad_right")
	velocity.x = axis * SPEED
	if !is_zero_approx(axis):
		c_direction = Direction.right if axis > 0.0 else Direction.left
	if !is_on_floor():
		velocity.y += 800.0 * delta
	var _collided: bool = move_and_slide()


func pick_up(item: String) -> void:
	picked_up.emit(item)
