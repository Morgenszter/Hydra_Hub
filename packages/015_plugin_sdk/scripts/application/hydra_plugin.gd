@abstract
class_name HydraPlugin
extends RefCounted
## Base class for all HYDRA plugins.


#region State

var _manifest: PluginManifest
var _context: PluginContext
var _state: PluginLifecycleState.Value = \
	PluginLifecycleState.Value.DISCOVERED
var _last_error: DomainError

#endregion


#region Public API

## Assigns the validated plugin manifest.
func set_manifest(
	manifest: PluginManifest
) -> void:
	assert(manifest != null, "Plugin manifest cannot be null.")
	_manifest = manifest


## Returns the plugin manifest.
func get_manifest() -> PluginManifest:
	return _manifest


## Returns the current lifecycle state.
func get_state() -> PluginLifecycleState.Value:
	return _state


## Returns the most recent lifecycle error.
func get_last_error() -> DomainError:
	return _last_error


## Validates this plugin.
func validate_plugin() -> Result:
	_state = PluginLifecycleState.Value.VALIDATING

	if _manifest == null:
		return _fail(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin manifest is not assigned."
			)
		)

	var manifest_result := _manifest.validate()

	if manifest_result.is_failure():
		return _fail(manifest_result.get_error())

	for capability in _manifest.requested_capabilities:
		if not PluginCapability.is_supported(
			StringName(capability)
		):
			return _fail(
				DomainError.new(
					HydraErrors.INVALID_ARGUMENT,
					"Plugin requested an unsupported capability.",
					{
						&"plugin_id": _manifest.plugin_id,
						&"capability": capability,
					}
				)
			)

	var custom_result := _on_validate()

	if custom_result.is_failure():
		return _fail(custom_result.get_error())

	_state = PluginLifecycleState.Value.VALIDATED

	return Result.success()


## Initializes the plugin.
func initialize_plugin(
	context: PluginContext
) -> Result:
	if _state != PluginLifecycleState.Value.VALIDATED:
		return _invalid_state("initialize")

	if context == null:
		return _fail(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin context cannot be null."
			)
		)

	_state = PluginLifecycleState.Value.INITIALIZING
	_context = context

	var result := _on_initialize(context)

	if result.is_failure():
		return _fail(result.get_error())

	_state = PluginLifecycleState.Value.READY

	return Result.success()


## Starts the plugin.
func start_plugin() -> Result:
	if _state not in [
		PluginLifecycleState.Value.READY,
		PluginLifecycleState.Value.STOPPED,
	]:
		return _invalid_state("start")

	_state = PluginLifecycleState.Value.STARTING

	var result := _on_start()

	if result.is_failure():
		return _fail(result.get_error())

	_state = PluginLifecycleState.Value.RUNNING

	return Result.success()


## Stops the plugin.
func stop_plugin() -> Result:
	if _state != PluginLifecycleState.Value.RUNNING:
		return _invalid_state("stop")

	_state = PluginLifecycleState.Value.STOPPING

	var result := _on_stop()

	if result.is_failure():
		return _fail(result.get_error())

	_state = PluginLifecycleState.Value.STOPPED

	return Result.success()


## Disposes the plugin.
func dispose_plugin() -> void:
	if _state == PluginLifecycleState.Value.RUNNING:
		stop_plugin()

	_on_dispose()
	_context = null
	_state = PluginLifecycleState.Value.DISPOSED

#endregion


#region Extension points

func _on_validate() -> Result:
	return Result.success()


func _on_initialize(
	_context_value: PluginContext
) -> Result:
	return Result.success()


func _on_start() -> Result:
	return Result.success()


func _on_stop() -> Result:
	return Result.success()


func _on_dispose() -> void:
	pass

#endregion


#region Private methods

func _fail(error: DomainError) -> Result:
	_last_error = error
	_state = PluginLifecycleState.Value.FAILED

	return Result.failure(error)


func _invalid_state(operation: String) -> Result:
	return _fail(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Plugin lifecycle operation is invalid.",
			{
				&"operation": operation,
				&"state": PluginLifecycleState.to_string_name(_state),
			}
		)
	)

#endregion