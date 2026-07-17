class_name AndroidPlatformService
extends Node
## Coordinates Android platform capabilities.


#region Signals

signal platform_initialized(info: AndroidPlatformInfo)
signal keep_screen_awake_changed(enabled: bool)
signal platform_operation_failed(error: DomainError)

#endregion


#region State

var _configuration: AndroidConfiguration
var _adapter: AndroidPlatformPort
var _platform_info: AndroidPlatformInfo

#endregion


#region Public API

## Configures the Android platform service.
func configure(
	configuration: AndroidConfiguration,
	adapter: AndroidPlatformPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Android configuration cannot be null."
			)
		)

	if adapter == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Android platform adapter cannot be null."
			)
		)

	_configuration = configuration
	_adapter = adapter

	return Result.success()


## Initializes platform information and configured behavior.
func initialize_platform() -> Result:
	if _configuration == null or _adapter == null:
		return _not_configured()

	var info_result := _adapter.get_platform_info()

	if info_result.is_failure():
		platform_operation_failed.emit(info_result.get_error())
		return info_result

	_platform_info = info_result.get_value()

	if (
		_configuration.keep_screen_awake
		and _adapter.is_android_runtime()
	):
		var wake_result := _adapter.set_keep_screen_awake(true)

		if wake_result.is_failure():
			platform_operation_failed.emit(
				wake_result.get_error()
			)

	platform_initialized.emit(_platform_info)

	return Result.success(_platform_info)


## Requests vibration when available.
func vibrate(
	duration_milliseconds: int = 100
) -> Result:
	if _adapter == null:
		return _not_configured()

	var result := _adapter.vibrate(duration_milliseconds)

	if result.is_failure():
		platform_operation_failed.emit(result.get_error())

	return result


## Changes screen wake-lock state.
func set_keep_screen_awake(enabled: bool) -> Result:
	if _adapter == null:
		return _not_configured()

	var result := _adapter.set_keep_screen_awake(enabled)

	if result.is_failure():
		platform_operation_failed.emit(result.get_error())
		return result

	keep_screen_awake_changed.emit(enabled)

	return Result.success()


## Opens native notification settings.
func open_notification_settings() -> Result:
	if _adapter == null:
		return _not_configured()

	var result := _adapter.open_notification_settings()

	if result.is_failure():
		platform_operation_failed.emit(result.get_error())

	return result


## Returns current platform information.
func get_platform_info() -> AndroidPlatformInfo:
	return _platform_info

#endregion


#region Private methods

func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Android platform service is not configured."
		)
	)

#endregion