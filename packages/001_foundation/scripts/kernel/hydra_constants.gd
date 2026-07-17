class_name HydraConstants
extends RefCounted
## Defines stable platform-wide constants.


#region Application

const APPLICATION_ID: StringName = &"hydra_ai_home_os"
const APPLICATION_NAME: String = "HYDRA AI HOME OS"
const APPLICATION_VERSION: String = "0.1.0"

#endregion


#region Resolution

const REFERENCE_WIDTH: int = 1920
const REFERENCE_HEIGHT: int = 1080
const REFERENCE_SIZE: Vector2 = Vector2(
	REFERENCE_WIDTH,
	REFERENCE_HEIGHT
)

#endregion


#region Services

const SERVICE_EVENT_BUS: StringName = &"event_bus"
const SERVICE_THEME_MANAGER: StringName = &"theme_manager"
const SERVICE_ANIMATION_MANAGER: StringName = &"animation_manager"

#endregion