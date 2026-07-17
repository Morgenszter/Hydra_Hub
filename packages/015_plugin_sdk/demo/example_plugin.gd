class_name ExampleHydraPlugin
extends HydraPlugin
## Demonstrates a safe SDK plugin lifecycle.


#region State

var _started: bool = false

#endregion


#region HydraPlugin

func _on_validate() -> Result:
	return Result.success()


func _on_initialize(
	context: PluginContext
) -> Result:
	var extension := PluginExtensionDescriptor.new(
		&"example_diagnostic_probe",
		PluginCapability.DIAGNOSTIC_PROBE,
		self,
		{
			&"display_name": "EXAMPLE PLUGIN PROBE",
		}
	)

	return context.register_extension(extension)


func _on_start() -> Result:
	_started = true
	print("Example HYDRA plugin started.")

	return Result.success()


func _on_stop() -> Result:
	_started = false
	print("Example HYDRA plugin stopped.")

	return Result.success()


func _on_dispose() -> void:
	_started = false

#endregion


#region Public API

func is_started() -> bool:
	return _started

#endregion