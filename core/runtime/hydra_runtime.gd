class_name HydraRuntime
extends Node
## Production composition root for HYDRA AI HOME OS.
##
## HydraRuntime configures application services, adapters and cross-module
## integrations. Feature modules remain isolated from infrastructure details.


#region Signals

signal runtime_initialization_started()
signal runtime_initialization_completed()
signal runtime_initialization_failed(error: DomainError)

#endregion


#region State

var _initialized: bool = false
var _initialization_error: DomainError

#endregion


#region Lifecycle

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var result := initialize_runtime()

	if result.is_failure():
		push_error(result.get_error().get_message())


#endregion


#region Public API

## Initializes all configured HYDRA services.
func initialize_runtime() -> Result:
	if _initialized:
		return Result.success()

	runtime_initialization_started.emit()

	var steps: Array[Callable] = [
		_configure_theme,
		_configure_diagnostics,
		_configure_notifications,
		_configure_device_hub,
		_configure_ai_system,
		_configure_automation,
		_configure_debug_tools,
		_configure_android_platform,
	]

	for step in steps:
		var result: Result = step.call()

		if result.is_failure():
			_initialization_error = result.get_error()
			runtime_initialization_failed.emit(
				_initialization_error
			)
			return result

	_initialized = true
	runtime_initialization_completed.emit()

	return Result.success()


## Returns whether runtime composition completed successfully.
func is_initialized() -> bool:
	return _initialized


## Returns the most recent initialization error.
func get_initialization_error() -> DomainError:
	return _initialization_error

#endregion


#region Composition

func _configure_theme() -> Result:
	var theme_manager := get_node_or_null(
		"/root/ThemeManager"
	)

	if theme_manager == null:
		return _missing_service(&"ThemeManager")

	return Result.success()


func _configure_diagnostics() -> Result:
	var diagnostics := get_node_or_null(
		"/root/Diagnostics"
	) as DiagnosticsService

	if diagnostics == null:
		return _missing_service(&"Diagnostics")

	var configuration := DiagnosticsConfiguration.new()
	var configure_result := diagnostics.configure(
		configuration
	)

	if configure_result.is_failure():
		return configure_result

	var probe_result := diagnostics.register_probe(
		RuntimeDiagnosticProbe.new()
	)

	if (
		probe_result.is_failure()
		and probe_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return probe_result

	return diagnostics.start()


func _configure_notifications() -> Result:
	var notification_center := get_node_or_null(
		"/root/NotificationCenter"
	) as NotificationCenterService

	if notification_center == null:
		return _missing_service(&"NotificationCenter")

	var configuration := NotificationConfiguration.new()
	var repository := InMemoryNotificationRepository.new()

	return notification_center.configure(
		configuration,
		repository
	)


func _configure_device_hub() -> Result:
	var device_hub := get_node_or_null(
		"/root/DeviceHub"
	) as DeviceHubService

	if device_hub == null:
		return _missing_service(&"DeviceHub")

	var configuration := DeviceHubConfiguration.new()
	var configure_result := device_hub.configure(
		configuration
	)

	if configure_result.is_failure():
		return configure_result

	var provider_result := device_hub.register_provider(
		DemoDeviceProvider.new()
	)

	if (
		provider_result.is_failure()
		and provider_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return provider_result

	return device_hub.start()


func _configure_ai_system() -> Result:
	var ai_system := get_node_or_null(
		"/root/AiSystem"
	) as AiSystemService

	if ai_system == null:
		return _missing_service(&"AiSystem")

	var configuration := AiSystemConfiguration.new()
	var configure_result := ai_system.configure(
		configuration
	)

	if configure_result.is_failure():
		return configure_result

	var provider_result := ai_system.register_provider(
		LocalDemoAiProvider.new()
	)

	if (
		provider_result.is_failure()
		and provider_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return provider_result

	if ai_system.get_active_conversation() == null:
		return ai_system.create_conversation(
			"HYDRA PRIMARY SESSION"
		)

	return Result.success()


func _configure_automation() -> Result:
	var automation := get_node_or_null(
		"/root/Automation"
	) as AutomationService

	if automation == null:
		return _missing_service(&"Automation")

	var configuration := AutomationConfiguration.new()
	var repository := InMemoryAutomationRuleRepository.new()

	var configure_result := automation.configure(
		configuration,
		repository
	)

	if configure_result.is_failure():
		return configure_result

	var executor_result := automation.register_executor(
		DemoAutomationActionExecutor.new()
	)

	if (
		executor_result.is_failure()
		and executor_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return executor_result

	return automation.start()


func _configure_debug_tools() -> Result:
	var debug_tools := get_node_or_null(
		"/root/DebugTools"
	) as DebugToolsService

	if debug_tools == null:
		return _missing_service(&"DebugTools")

	var configuration := DebugToolsConfiguration.new()
	var registry := DebugCommandRegistry.new()

	registry.register_command(
		HelpDebugCommand.new(registry)
	)
	registry.register_command(
		RuntimeDebugCommand.new()
	)
	registry.register_command(
		ClearDebugCommand.new()
	)

	var configure_result := debug_tools.configure(
		configuration,
		registry
	)

	if configure_result.is_failure():
		return configure_result

	if configuration.enabled:
		return debug_tools.start()

	return Result.success()


func _configure_android_platform() -> Result:
	var android_platform := get_node_or_null(
		"/root/AndroidPlatform"
	) as AndroidPlatformService

	if android_platform == null:
		return _missing_service(&"AndroidPlatform")

	var configuration := AndroidConfiguration.new()
	var adapter: AndroidPlatformPort

	if OS.get_name() == "Android":
		adapter = AndroidRuntimeAdapter.new()
	else:
		adapter = NullAndroidPlatformAdapter.new()

	var configure_result := android_platform.configure(
		configuration,
		adapter
	)

	if configure_result.is_failure():
		return configure_result

	return android_platform.initialize_platform()

#endregion


#region Private methods

func _missing_service(
	service_id: StringName
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.SERVICE_NOT_FOUND,
			"Required runtime service is unavailable.",
			{
				&"service_id": service_id,
			}
		)
	)

#endregion