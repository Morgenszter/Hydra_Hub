class_name DebugToolsConfiguration
extends Resource
## Stores Debug Tools runtime configuration.


#region Runtime

@export_group("Runtime")
@export var enabled: bool = OS.is_debug_build()
@export var console_enabled: bool = true
@export var performance_overlay_enabled: bool = true
@export var event_trace_enabled: bool = false

#endregion


#region Retention

@export_group("Retention")
@export_range(10, 100000, 10) var maximum_log_entries: int = 2000
@export_range(10, 100000, 10) var maximum_event_entries: int = 1000

#endregion


#region Performance

@export_group("Performance")
@export_range(0.05, 10.0, 0.05) var performance_refresh_seconds: float = 0.25
@export var show_fps: bool = true
@export var show_memory: bool = true
@export var show_object_count: bool = true
@export var show_draw_calls: bool = true

#endregion