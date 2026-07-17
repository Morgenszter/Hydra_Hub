class_name AndroidRuntimeAdapter
extends AndroidPlatformPort
## Android runtime adapter using Godot platform singletons.
##
## Android-only calls are guarded by OS platform detection.


#region AndroidPlatformPort

func get_platform_info() -> Result:
	if not is_android_runtime():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Android runtime is unavailable."
			)
		)

	var capabilities: Dictionary[StringName, bool] = {
		AndroidCapability.PLATFORM_RUNTIME: true,
		AndroidCapability.JAVA_API:
			Engine.has_singleton("JavaClassWrapper"),
		AndroidCapability.VIBRATION: true,
		AndroidCapability.NOTIFICATIONS: true,
		AndroidCapability.BACKGROUND_EXECUTION: false,
		AndroidCapability.KEEP_SCREEN_AWAKE: true,
		AndroidCapability.BATTERY_INFORMATION: false,
		AndroidCapability.NETWORK_INFORMATION: false,
	}

	return Result.success(
		AndroidPlatformInfo.new(
			true,
			OS.get_name(),
			"ANDROID DEVICE",
			0,
			capabilities
		)
	)


func vibrate(duration_milliseconds: int) -> Result:
	if not is_android_runtime():
		return _runtime_unavailable()

	if duration_milliseconds <= 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Vibration duration must be positive."
			)
		)

	Input.vibrate_handheld(duration_milliseconds)

	return Result.success()


func set_keep_screen_awake(enabled: bool) -> Result:
	if not is_android_runtime():
		return _runtime_unavailable()

	DisplayServer.screen_set_keep_on(enabled)

	return Result.success()


func open_notification_settings() -> Result:
	if not is_android_runtime():
		return _runtime_unavailable()

	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Notification settings integration requires an Android plugin."
		)
	)


func is_android_runtime() -> bool:
	return OS.get_name() == "Android"

#endregion


#region Private methods

func _runtime_unavailable() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Android runtime is unavailable."
		)
	)

#endregion