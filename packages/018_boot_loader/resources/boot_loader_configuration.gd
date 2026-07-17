class_name BootLoaderConfiguration
extends Resource
## Stores Boot Loader runtime configuration.


#region Scene transition

@export_group("Scene Transition")
@export_file("*.tscn") var target_scene_path: String = \
	"res://hud_scene.tscn"
@export_range(0.0, 10.0, 0.05) var completion_delay_seconds: float = 0.35

#endregion


#region Behavior

@export_group("Behavior")
@export var start_automatically: bool = true
@export var stop_on_critical_failure: bool = true
@export var allow_retry: bool = true
@export var change_scene_after_completion: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var minimum_step_display_seconds: float = 0.05
@export var show_completed_steps: bool = true

#endregion