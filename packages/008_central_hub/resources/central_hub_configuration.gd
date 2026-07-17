class_name CentralHubConfiguration
extends Resource
## Stores Central Hub runtime configuration.


#region Startup

@export_group("Startup")
@export var default_route_id: StringName = &"home"
@export var restore_last_route: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var show_disabled_routes: bool = true
@export var launcher_columns: int = 3
@export var launcher_width: float = 320.0
@export var launcher_height: float = 130.0
@export var launcher_horizontal_gap: float = 24.0
@export var launcher_vertical_gap: float = 20.0

#endregion