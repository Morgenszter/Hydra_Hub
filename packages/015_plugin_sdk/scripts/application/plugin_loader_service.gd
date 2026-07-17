class_name PluginLoaderService
extends Node
## Validates, initializes and starts HYDRA plugins.


#region Signals

signal plugin_loaded(plugin: HydraPlugin)
signal plugin_started(plugin: HydraPlugin)
signal plugin_stopped(plugin: HydraPlugin)
signal plugin_failed(
	plugin_id: StringName,
	error: DomainError
)

#endregion


#region State

var _registry: PluginRegistry
var _granted_services: Dictionary[StringName, Variant] = {}

#endregion


#region Public API

## Configures the loader.
func configure(
	registry: PluginRegistry
) -> Result:
	if registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin registry cannot be null."
			)
		)

	_registry = registry

	return Result.success()


## Grants a service to future plugin contexts.
func grant_service(
	service_id: StringName,
	service: Variant
) -> Result:
	if service_id.is_empty() or service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin service grant is invalid."
			)
		)

	_granted_services[service_id] = service

	return Result.success()


## Loads and starts one plugin.
func load_plugin(
	plugin: HydraPlugin,
	manifest: PluginManifest
) -> Result:
	if _registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Plugin loader is not configured."
			)
		)

	if plugin == null or manifest == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin and manifest are required."
			)
		)

	plugin.set_manifest(manifest)

	var validation_result := plugin.validate_plugin()

	if validation_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			validation_result.get_error()
		)

	var context := PluginContext.new()

	for service_id in _granted_services:
		context.grant_service(
			service_id,
			_granted_services[service_id]
		)

	var initialization_result := plugin.initialize_plugin(
		context
	)

	if initialization_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			initialization_result.get_error()
		)

	var registration_result := _registry.register_plugin(
		plugin
	)

	if registration_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			registration_result.get_error()
		)

	var extension_result := _registry.register_extensions(
		context.get_extensions()
	)

	if extension_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			extension_result.get_error()
		)

	plugin_loaded.emit(plugin)

	var start_result := plugin.start_plugin()

	if start_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			start_result.get_error()
		)

	plugin_started.emit(plugin)

	return Result.success(plugin)


## Stops one plugin.
func stop_plugin(
	plugin_id: StringName
) -> Result:
	if _registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Plugin loader is not configured."
			)
		)

	var plugin := _registry.get_plugin(plugin_id)

	if plugin == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin was not found.",
				{&"plugin_id": plugin_id}
			)
		)

	var result := plugin.stop_plugin()

	if result.is_failure():
		return _report_failure(
			plugin_id,
			result.get_error()
		)

	plugin_stopped.emit(plugin)

	return Result.success(plugin)

#endregion


#region Private methods

func _report_failure(
	plugin_id: StringName,
	error: DomainError
) -> Result:
	plugin_failed.emit(plugin_id, error)

	return Result.failure(error)

#endregion