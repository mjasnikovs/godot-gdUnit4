class_name Menu extends Control

signal started

@onready var play_button: Button = $Play


func _ready() -> void:
	# started.emit is already a Callable, so no closure is needed. connect()
	# still returns an Error, hence the one-line ignore.
	@warning_ignore("return_value_discarded")
	play_button.pressed.connect(started.emit)
