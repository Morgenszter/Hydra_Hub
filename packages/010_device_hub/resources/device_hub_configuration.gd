class_name DeviceHubConfiguration
extends Resource
## Stores Device Hub runtime configuration.


#region Discovery

@export_group("Discovery")
@export var automatic_discovery_enabled: bool = true
@export_range(1.0, 3600.0, 1.0) var discovery_interval_seconds: float = 60.0

#endregion


#region Refresh

@export_group("Refresh")
@export var automatic_refresh_enabled: bool = true
@export_range(0.25, 300.0, 0.25) var refresh_interval_seconds: float = 5.0
@export_range(1.0, 3600.0, 1.0) var offline_timeout_seconds: float = 30.0

#endregion


#region Presentation

@export_group("Presentation")
@export var show_offline_devices: bool = true
@export var show_disabled_devices: bool = true
@export_range(1, 6, 1) var card_columns: int = 3
@export var card_width: float = 310.0
@export var card_height: float = 164.0
@export var card_horizontal_gap: float = 22.0
@export var card_vertical_gap: float = 20.0

#endregion