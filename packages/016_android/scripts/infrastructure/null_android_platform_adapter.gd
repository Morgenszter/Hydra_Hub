class_name NullAndroidPlatformAdapter
extends AndroidPlatformPort
## Desktop-safe Android adapter used outside Android exports.


#region AndroidPlatformPort

func get_platform_info() -> Result:
	var capabilities: Dictionary[StringName, bool] = {}

	for capability in AndroidCapability.get_all():
		capabilities[capability] = false

	return Result.success(
		AndroidPlatformInfo.new(
			false,
			OS.get_name(),
			"DESKTOP",
			0,
			capabilities
		)
	)


func vibrate(_duration_milliseconds: int) -> Result:
	return _unsupported("Vibration")


func set_keep_screen_awake(_enabled: bool) -> Result:
	return _unsupported("Screen wake lock")


func open_notification_settings() -> Result:
	return _unsupported("Notification settings")


func is_android_runtime() -> bool:
	return false

#endregion


#region Private methods

func _unsupported(operation_name: String) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"%s is unavailable outside Android." % operation_name
		)
	)

#endregion