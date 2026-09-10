class_name Menu extends Control

signal started

@onready var play_button: Button = $Play


func _ready() -> void:
	@warning_ignore("return_value_discarded")
	play_button.pressed.connect(func() -> void:
		started.emit()
	)
