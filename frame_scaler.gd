@tool
extends Control

@export var enabled: bool = true
@export var apply_on_ready: bool = true
@export var target_size: Vector2 = Vector2.ZERO
@export var preserve_position: bool = true

var _original_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_original_position = position

	if apply_on_ready:
		apply_frame_scale()


func apply_frame_scale() -> void:
	if not enabled:
		return

	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return

	if preserve_position:
		position = _original_position

	size = target_size
