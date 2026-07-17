@abstract
class_name AndroidPlatformPort
extends RefCounted
## Defines the Android platform integration boundary.


#region Public API

## Returns normalized platform information.
@abstract
func get_platform_info() -> Result


## Requests a short vibration.
@abstract
func vibrate(duration_milliseconds: int) -> Result


## Enables or disables screen wake locking.
@abstract
func set_keep_screen_awake(enabled: bool) -> Result


## Opens the application notification settings when supported.
@abstract
func open_notification_settings() -> Result


## Returns whether this adapter represents an Android runtime.
@abstract
func is_android_runtime() -> bool

#endregion