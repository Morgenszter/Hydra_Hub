class_name EnvironmentHubConfiguration
extends Resource
## Stores Environment Hub runtime configuration.


#region Refresh

@export_group("Refresh")
@export_range(0.25, 120.0, 0.25) var refresh_interval_seconds: float = 3.0
@export var automatic_refresh_enabled: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var temperature_decimals: int = 1
@export var humidity_decimals: int = 0
@export var air_quality_decimals: int = 0
@export var show_inactive_zones: bool = true

#endregion


#region Thresholds

@export_group("Thresholds")
@export var thresholds: EnvironmentThresholds

#endregion