@abstract
class_name DeviceProviderPort
extends RefCounted
## Defines a provider-independent device integration boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns whether the provider is currently available.
@abstract
func is_available() -> bool


## Returns a Result containing Array[DeviceDescriptor].
@abstract
func discover_devices() -> Result


## Returns a Result containing DeviceStateSnapshot.
@abstract
func fetch_device_state(
	device_id: StringName
) -> Result


## Executes a normalized command.
@abstract
func execute_command(
	command: DeviceCommand
) -> Result

#endregion