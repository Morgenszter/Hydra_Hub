class_name AnimationDemo
extends Control
## Demonstrates AnimationManager operations.


#region Nodes

@onready var _target: Control = %Target

#endregion


#region Lifecycle

func _ready() -> void:
	var manager := HydraAnimationManager.new()
	add_child(manager)

	manager.slide_in(
		_target,
		&"animation_demo_slide",
		Vector2.LEFT
	)

#endregion