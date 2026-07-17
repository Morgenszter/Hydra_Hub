class_name HomeHubConfiguration
extends Resource
## Stores runtime configuration for Home Hub.


#region Identity

@export_group("Identity")
@export var home_id: StringName = &"primary_home"
@export var display_name: String = "HYDRA RESIDENCE"

#endregion


#region Refresh

@export_group("Refresh")
@export_range(0.25, 60.0, 0.25) var refresh_interval_seconds: float = 2.0
@export var refresh_while_hidden: bool = false

#endregion


#region Presentation

@export_group("Presentation")
@export var show_occupancy: bool = true
@export var show_security: bool = true
@export var show_energy: bool = true
@export var show_room_status: bool = true

#endregion