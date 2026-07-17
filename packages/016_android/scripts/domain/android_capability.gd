class_name AndroidCapability
extends RefCounted
## Defines normalized Android platform capabilities.


#region Constants

const PLATFORM_RUNTIME: StringName = &"platform_runtime"
const JAVA_API: StringName = &"java_api"
const VIBRATION: StringName = &"vibration"
const NOTIFICATIONS: StringName = &"notifications"
const BACKGROUND_EXECUTION: StringName = &"background_execution"
const KEEP_SCREEN_AWAKE: StringName = &"keep_screen_awake"
const BATTERY_INFORMATION: StringName = &"battery_information"
const NETWORK_INFORMATION: StringName = &"network_information"

#endregion


#region Public API

## Returns all supported capability identifiers.
static func get_all() -> Array[StringName]:
	return [
		PLATFORM_RUNTIME,
		JAVA_API,
		VIBRATION,
		NOTIFICATIONS,
		BACKGROUND_EXECUTION,
		KEEP_SCREEN_AWAKE,
		BATTERY_INFORMATION,
		NETWORK_INFORMATION,
	]

#endregion