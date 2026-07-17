class_name AndroidConfiguration
extends Resource
## Stores Android integration configuration.


#region Behavior

@export_group("Behavior")
@export var enabled: bool = true
@export var allow_runtime_permission_requests: bool = false
@export var allow_background_operation: bool = false
@export var keep_screen_awake: bool = false

#endregion


#region Notifications

@export_group("Notifications")
@export var notification_channel_id: StringName = &"hydra_system"
@export var notification_channel_name: String = "HYDRA System"
@export var notification_channel_description: String = \
	"HYDRA AI HOME OS operational notifications."

#endregion


#region Diagnostics

@export_group("Diagnostics")
@export var collect_platform_information: bool = true
@export var expose_device_model: bool = true

#endregion